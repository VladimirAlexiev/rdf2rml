#!perl -w

our @where; # Array of WHERE strings, since order of binds matters:
  # [0] OntoRefine prebinds
  # [1] Normal binds inside OntoRefine service
  # [2] Binds after (outside) OntoRefine service

sub addWhere($$) {
  # Append $clause to $where[$index]
  my $index = shift;
  my $clause = shift;
  my $spaces = ' ' x ($index >= 2 ? 2 : 4);
  $clause = "\n$spaces$clause";
  $where[$index] //= '';
  $where[$index] .= $clause;
}

sub ontorefine($) {
  # OntoRefine prefixes input cols with `c_`, and we must mention each col in WHERE
  # https://ontotext.atlassian.net/browse/GDB-6600
  my $var = $1;
  $bound{$var} && $bound{$var} ne "ontorefine" and die "$var is used for both ontorefine and $bound{$var}\n";
  $bound{$var} and return "($var)";
  $bound{$var} = "ontorefine";
  addWhere(0,"bind(?c_$var as ?$var)");
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
  addWhere ($fun =~ m{[^a-z]url$}i ? 2 : 1, "$fun(?$var$rest)");
  "($var1)"
}

sub typecast($$) {
  # convert 'var'^^xsd:datatype to strdt(var,xsd:datatype) as VAR
  my $var = "?" . shift;
  my $dt = shift;
  my $VAR = uc $var; # upcase var name to show it's been changed
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
  $bound{$var} && $bound{$var} ne "templated_url" and die "$var is used for both templated_url and $bound{$var}\n";
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

$_ = <>;
our ($GRAPH) = m{# (GRAPH <.*>)} or die "Expected GRAPH got $_";
our $output = ""; 
our %bound;

while ($_ = <>) {
  m{puml:|plantuml} and next; # skip any puml statements
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

my $WHERE_POST = scalar @where > 2 ? pop @where : '';
my $WHERE_PRE  = join'',@where;

print << "EOF";
delete where {$GRAPH {?s ?p ?o}};

insert {$GRAPH {
$output}}
where {
  service <rdf-mapper:ontorefine:PROJECT_ID> {
$WHERE_PRE
  }
$WHERE_POST};
EOF
