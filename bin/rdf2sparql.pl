#!perl -w

our $tool = "ontorefine";
our $form = "update";
our ($filter, $filterColumn);
use Getopt::Long qw(:config no_ignore_case auto_abbrev);
# https://perldoc.perl.org/Getopt::Long#bundling-(default:-disabled)
GetOptions
  ('construct'      => sub {$form = "construct"},
   'tarql'          => sub {$form = "construct"; $tool = "tarql"},
   'filter=s'       => \$filter,
   'filterColumn=s' => \$filterColumn
   );

our $GRAPH;       # named graph: per-table (if constant) or per-row (if templated, i.e. uses a row field)
our $output = ""; # model body, all field embeds converted to SPARQL vars, to be used in INSERT or CONSTRUCT
our %bound;       # memoized variables, with "reason" for var existence

our @where  = ('','','','',''); # Array of WHERE binds and filters, since order of binds matters:
  # [0] OntoRefine --filterColumn prebind and GRAPH variable: used for both DELETE and INSERT
  # [1] OntoRefine prebinds: used for INSERT only
  # [2] Normal binds inside OntoRefine service: used for INSERT only
  # [3] Binds after (outside) OntoRefine service: used for INSERT only
  # [4] Binds after (outside) OntoRefine service: used for both DELETE and INSERT

sub addWhere($$) {
  # Append $clause to $where[$index]
  my $index = shift;
  my $clause = shift;
  my $spaces = ' ' x ($index >= 3 ? 2 : 4);
  $clause = "\n$spaces$clause";
  $where[$index] .= $clause;
}

sub ontorefine($$) {
  # OntoRefine prefixes input cols with `c_`, and we must mention each col in WHERE
  # https://ontotext.atlassian.net/browse/GDB-6600
  my $index = shift;
  my $var = shift;
  if ($tool eq "ontorefine") {
    $bound{$var} && $bound{$var} ne "ontorefine" && $bound{$var} ne "function" and die "$var is used for both ontorefine and $bound{$var}\n";
    $bound{$var} and return "($var)";
    $bound{$var} = "ontorefine";
    addWhere($index,"bind(?c_$var as ?$var)");
  };
  "($var)"
}

sub function($$$$) {
  # Replace `fun(var)` with `var_FUN` and add such call in WHERE
  my $index = shift;
  my $fun = shift;
  my $var = shift;
  my $rest = shift;
  my $FUN = uc $fun;
  # eg _IF_BOUND(x,?y,?z): don't add extra underscore, nor question mark
  my $startsWithUnderscore = $fun =~ m{^_};
  my $questionMark = $startsWithUnderscore ? "" : "?";
  my $var1 = $var;
  $var1 .= "_" unless $startsWithUnderscore;
  $var1 .= $FUN;
  $bound{$var1} && $bound{$var1} ne "function" and die "$var is used for both function and $bound{$var}\n";
  $bound{$var1} and return "($var1)";
  $bound{$var1} = "function";
  $fun =~ m{[^a-z]url$}i and do {
    $tool eq "ontorefine" or die "Macro $fun ends in 'url' and can only be used with OntoRefine\n";
    $index > 0 or die "Macro $fun ends in 'url' and cannot be used in the GRAPH templated URL\n";
    $index = 3
  };
  addWhere ($index, "$fun($questionMark$var$rest)");
  "($var1)"
}

sub typecast($$) {
  # convert 'var'^^xsd:datatype to strdt(var,xsd:datatype) as var_xsd_datatype
  my $var = shift;
  my $dt = shift;
  my $var_dt = "${var}_$dt";
  $var_dt =~ s{([^\w])}{_}g; # replace punctuation with underscore
  $var = "?$var";
  $var_dt = "?$var_dt";
  $bound{$var_dt} && $bound{$var_dt} ne "typecast" and die "$var_dt is used for both typecast and $bound{$var_dt}\n";
  $bound{$var_dt} and return $var_dt;
  $bound{$var_dt} = "typecast";
  # Jena has xsd:date("2020-05-22") but rdf4j has only strdt("2020-05-22",xsd:date) so we use that:
  addWhere(2,"bind(strdt($var,$dt) as $var_dt)");
  $var_dt
}

sub templated_url($$) {
  my $index = shift;
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
  $url =~ s{\(([\w.]+)\)}{ontorefine($index,$1); qq{",?$1,"}}ge;
  $url = qq{"$url"};
  $url =~ s{,""}{}g;
  $url =~ s{^"",}{};
  addWhere($index,"bind(iri(concat($url)) as $var)");
  $var
}

## main

if ($form eq "update") {
  $_ = <>;
  m{#+ GRAPH <(.*)>} or die "Expected # GRAPH <...> got $_";
  $GRAPH = templated_url(0,$1);
};

die "--filterColumn and --filter must be used together\n" if $filter xor $filterColumn;
if ($filterColumn) {
  die "--filterColumn and --filter can be used only with ontorefine update, but you've selected $tool $form\n"
    unless $form eq "update" && $tool eq "ontorefine";
  ontorefine(0,$filterColumn);
  addWhere(4,$filter)
};

while ($_ = <>) {
  m{puml:label *['"]+(.*?)['"]+ *[;.]( *#.*)$} and do {addWhere(1,$1); next};
  m{puml:|plantuml} and next; # skip any other puml statements
  s{\((\w+)\)}{ontorefine(1,$1)}ge;
  while (s{(\w+)\((\w+)([,?\w]*)\)}{function(2,$1,$2,$3)}ge)
    # recursively replace function calls.
    # <industry/urlify(foo)> -> <industry/(foo_URLIFY)>: single parentheses needed to enact templated_url
    # <industry/urlify(split(foo))> -> <industry/urlify((foo_SPLIT))> -> <industry/urlify((foo_SPLIT))>: double parens, reduce them -> <industry/urlify(foo_SPLIT)> -> <industry/(foo_SPLIT_URLIFY)>
    {s{\(\((\w+)\)}{($1}g}; # reduce double parens
  s{['"]\((\w+)\)['"]\^\^([\w:]+)}{typecast($1,$2)}ge;
  s{['"]\((\w+)\)['"]}{?$1}g; # simple var
  s{<([^\s>]*\([^\s>]*)>}{templated_url(2,$1)}ge;
  $_ = "  $_" if $_;
  $output = "$output$_";
};

print

  $form eq "update" ? << "EOF"
delete {graph $GRAPH {?_s_ ?_p_ ?_o_}}
where {
  service <rdf-mapper:ontorefine:PROJECT_ID> {
$where[0]
  }
$where[4]
  graph $GRAPH {?_s_ ?_p_ ?_o_}};

insert {graph $GRAPH {
$output}}
where {
  service <rdf-mapper:ontorefine:PROJECT_ID> {
$where[0]$where[1]$where[2]
  }
$where[3]$where[4]};
EOF

  : $tool eq "ontorefine" ? << "EOF"
construct {
$output}
where {
  service <rdf-mapper:ontorefine:PROJECT_ID> {
$where[0]$where[1]$where[2]
  }
$where[3]$where[4]}
EOF

  # tarql construct
  : << "EOF";
construct {
$output}
where {
$where[0]$where[1]$where[2]
}
EOF
