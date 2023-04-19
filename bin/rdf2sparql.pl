#!perl -w

our $tool = "ontorefine";
our $form = "update";
use Getopt::Long qw(:config no_ignore_case auto_abbrev);
# https://perldoc.perl.org/Getopt::Long#bundling-(default:-disabled)
GetOptions ('construct' => sub {$form = "construct"},
            'tarql'     => sub {$form = "construct"; $tool = "tarql"});

our $GRAPH;
our $output = "";
our %bound;

our @where  = ('','',''); # Array of WHERE strings, since order of binds matters:
  # [0] OntoRefine prebinds
  # [1] Normal binds inside OntoRefine service
  # [2] Binds after (outside) OntoRefine service

sub addWhere($$) {
  # Append $clause to $where[$index]
  my $index = shift;
  my $clause = shift;
  my $spaces = ' ' x ($index >= 2 ? 2 : 4);
  $clause = "\n$spaces$clause";
  $where[$index] .= $clause;
}

sub ontorefine($) {
  # OntoRefine prefixes input cols with `c_`, and we must mention each col in WHERE
  # https://ontotext.atlassian.net/browse/GDB-6600
  my $var = $1;
  if ($tool eq "ontorefine") {
    $bound{$var} && $bound{$var} ne "ontorefine" and die "$var is used for both ontorefine and $bound{$var}\n";
    $bound{$var} and return "($var)";
    $bound{$var} = "ontorefine";
    addWhere(0,"bind(?c_$var as ?$var)");
  };
  "($var)"
}

sub function($$$) {
  # Replace `fun(var)` with `var_FUN` and add such call in WHERE
  my $fun = shift;
  my $var = shift;
  my $rest = shift;
  my $FUN = uc $fun;
  my $var1 = "${var}_${FUN}";
  $bound{$var1} && $bound{$var1} ne "function" and die "$var is used for both function and $bound{$var}\n";
  $bound{$var1} and return "($var1)";
  $bound{$var1} = "function";
  my $where = 1;
  $fun =~ m{[^a-z]url$}i and do {
    $tool eq "ontorefine" or die "Macro $fun ends in 'url' and can only be used with OntoRefine\n";
    $where = 2
  };
  addWhere ($where, "$fun(?$var$rest)");
  "($var1)"
}

sub typecast($$) {
  # convert 'var'^^xsd:datatype to strdt(var,xsd:datatype) as var_xsd_datatype
  my $var = shift;
  my $dt = shift;
  my $VAR = "${var}_$dt";
  $VAR =~ s{([^\w])}{_}g; # replace punctuation with underscore
  $var = "?$var";
  $VAR = "?$VAR";
  $bound{$VAR} && $bound{$VAR} ne "typecast" and die "$VAR is used for both typecast and $bound{$VAR}\n";
  $bound{$VAR} and return $VAR;
  $bound{$VAR} = "typecast";
  # Jena has xsd:date("2020-05-22") but rdf4j has only strdt("2020-05-22",xsd:date) so we use that:
  addWhere(1,"bind(strdt($var,$dt) as $VAR)");
  $VAR
}

sub templated_url {
  my $url = shift;
  # simple case: URL consists of a single var that's already a URL
  return "?$1" if $url =~ m{^\((\w+url)\)$}i;
  # complex case: URL consists of several parts, and/or needs to be converted to iri()
  $var = $url . "_URL";
  $var =~ s{\W}{_}g;
  $var =~ s{__+}{_}g;
  $var =~ s{^_}{};
  $var =~ s{_$}{};
  $var = "?" . $var;
  $bound{$var} && $bound{$var} ne "templated_URL" and die "$var is used for both templated_URL and $bound{$var}\n";
  $bound{$var} and return $var;
  $bound{$var} = "templated_URL";
  $url =~ s{\(([\w.]+)\)}{",?$1,"}g;
  $url = qq{"$url"};
  $url =~ s{,""}{}g;
  $url =~ s{^"",}{};
  addWhere(1,"bind(iri(concat($url)) as $var)");
  $var
}

## main

if ($form eq "update") {
  $_ = <>;
  m{#+ GRAPH <(.*)>} or die "Expected # GRAPH <...> got $_";
  $GRAPH = templated_url($1);
};
while ($_ = <>) {
  m{puml:label *['"]+(.*?)['"]+ *[;.]( *#.*)$} and do {addWhere(1,$1); next};
  m{puml:|plantuml} and next; # skip any other puml statements
  s{\((\w+)\)}{ontorefine($1)}ge;
  while (s{(\w+)\((\w+)([,?\w]*)\)}{function($1,$2,$3)}ge)
    # recursively replace function calls.
    # <industry/urlify(foo)> -> <industry/(foo_URLIFY)>: single parentheses needed to enact templated_url
    # <industry/urlify(split(foo))> -> <industry/urlify((foo_SPLIT))> -> <industry/urlify((foo_SPLIT))>: double parens, reduce them -> <industry/urlify(foo_SPLIT)> -> <industry/(foo_SPLIT_URLIFY)>
    {s{\(\((\w+)\)}{($1}g}; # reduce double parens
  s{['"]\((\w+)\)['"]\^\^([\w:]+)}{typecast($1,$2)}ge;
  s{['"]\((\w+)\)['"]}{?$1}g; # simple var
  s{<([^\s>]*\([^\s>]*)>}{templated_url($1)}ge;
  $_ = "  $_" if $_;
  $output = "$output$_";
};

my $WHERE_POST = pop @where;
my $WHERE_PRE  = join'',@where;

print

  $form eq "update" ? << "EOF"
delete {graph $GRAPH {?s ?p ?o}}
where {
  service <rdf-mapper:ontorefine:PROJECT_ID> {
$WHERE_PRE
  }
$WHERE_POST
  $GRAPH {?s ?p ?o}};

insert {graph $GRAPH {
$output}}
where {
  service <rdf-mapper:ontorefine:PROJECT_ID> {
$WHERE_PRE
  }
$WHERE_POST};
EOF

  : $tool eq "ontorefine" ? << "EOF"
construct {
$output}
where {
  service <rdf-mapper:ontorefine:PROJECT_ID> {
$WHERE_PRE
  }
$WHERE_POST}
EOF

  # tarql construct
  : << "EOF";
construct {
$output}
where {
$WHERE_PRE
}
EOF
