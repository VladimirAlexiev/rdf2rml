#!perl -w

our $tool = "ontorefine";
our $form = "update";
our ($filter, $filterColumn);
our $endpoint = "rdf-mapper:ontorefine:PROJECT_ID";
use Getopt::Long qw(:config no_ignore_case auto_abbrev);
# https://perldoc.perl.org/Getopt::Long#bundling-(default:-disabled)
GetOptions
  ('construct'      => sub {$form = "construct"},
   'tarql'          => sub {$form = "construct"; $tool = "tarql"},
   'sparql-anything'=> sub {$form = "construct"; $tool = "fx"},
   'sa'             => sub {$form = "construct"; $tool = "fx"},
   'fx'             => sub {$form = "construct"; $tool = "fx"},
   'endpoint=s'     => \$endpoint,
   'filter=s'       => \$filter,
   'filterColumn=s' => \$filterColumn
   );

our $GRAPH;       # named graph: per-table (if constant) or per-row (if templated, i.e. uses a row field)
our $output = ""; # model body, all field embeds converted to SPARQL vars, to be used in INSERT or CONSTRUCT
our %bound;       # memoized variables, with "reason" for var existence

our @where  = ('','','','',''); # Array of WHERE binds and filters, since order of binds matters:
  # [0] OntoRefine --filterColumn prebind and GRAPH variable: used for both DELETE and INSERT
  # [1] Prebinds: OntoRefine (used for INSERT only) or FX "[] xyz:col ?col" 
  # [2] Normal binds inside OntoRefine service: used for INSERT only; FX GRAPH variable
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

sub prebind($) {
  # ontorefine and fx require some prebinds in Where
  my $var = shift;
  my $index = 1; # prebinds always go in a fixed addWhere slot
  $tool eq "ontorefine" and ontorefine($index,$var);
  $tool eq "fx" and fx($index,$var);
  undef
}

sub prebind_all($$) {
  # prebind all arguments of n-ary macro
  my $fun = shift;
  my @args = split(/,/,shift);
  shift @args if $fun =~ m{^_}; # macros starting with "_" leave their first arg alone
  map {prebind($_)} @args
}

sub ontorefine($$) {
  # OntoRefine prefixes input cols with `c_`, and we must mention each col in WHERE
  # https://ontotext.atlassian.net/browse/GDB-6600
  my $index = shift;
  my $var = shift;
  $bound{$var} && $bound{$var} ne "ontorefine" && $bound{$var} ne "function" and die "$var is used for both ontorefine and $bound{$var}\n";
  $bound{$var} and return "($var)";
  $bound{$var} = "ontorefine";
  addWhere($index,"bind(?c_$var as ?$var)");
  undef
}

sub fx($$) {
  my $index = shift;
  my $var = shift;
  $bound{$var} && $bound{$var} ne "fx" && $bound{$var} ne "function" and die "$var is used for both fx and $bound{$var}\n";
  $bound{$var} and return "($var)";
  $bound{$var} = "fx";
  addWhere($index,"optional {?ROW xyz:$var ?$var}");
  undef
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
  addWhere($index,"$fun($questionMark$var$rest)");
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

sub strlang($$) {
  # convert 'var'@xx to strlang(var,"xx") as var_lang_xx. xx is a constant
  my $var = shift;
  my $lang = shift;
  my $var_lang = "${var}_lang_$lang";
  my $lang_str = qq{"$lang"};
  $var_lang =~ s{([^\w])}{_}g; # replace punctuation with underscore
  $var = "?$var";
  $var_lang = "?$var_lang";
  $bound{$var_lang} && $bound{$var_lang} ne "strlang" and die "$var_lang is used for both strlang and $bound{$var_lang}\n";
  $bound{$var_lang} and return $var_lang;
  $bound{$var_lang} = "strlang";
  addWhere(2,"bind(strlang($var,$lang_str) as $var_lang)");
  $var_lang
}

sub templated_string($$) {
  my $index = shift;
  my $string = shift;
  my $var = $string;
  $var =~ s{\W}{_}g;
  $var =~ s{__+}{_}g;
  $var =~ s{^_}{};
  $var =~ s{_$}{};
  my $var1 = "?" . $var;
  $bound{$var1} && $bound{$var1} ne "templated_string" and die "$var1 is used for both templated_string and $bound{$var1}\n";
  $bound{$var1} and return qq{"($var)"};
  $bound{$var1} = "templated_string";
  $string =~ s{\(([\w.]+)\)}{prebind($1); qq{",?$1,"}}ge;
  $string = qq{"$string"};
  $string =~ s{,""}{}g;
  $string =~ s{^"",}{};
  addWhere($index,"bind(concat($string) as $var1)");
  qq{"($var)"} # so that typecast() or strlang() can still work on it
}

sub templated_url($$) {
  my $index = shift;
  my $url = shift;
  # simple case: URL consists of a single var that's already a URL
  return "?$1" if $url =~ m{^\((\w+url)\)$}i;
  # complex case: URL consists of several parts, and/or needs to be converted to iri()
  my $var = $url . "_URL";
  $var =~ s{\W}{_}g;
  $var =~ s{__+}{_}g;
  $var =~ s{^_}{};
  $var =~ s{_$}{};
  $var = "?" . $var;
  $bound{$var} && $bound{$var} ne "templated_URL" and die "$var is used for both templated_URL and $bound{$var}\n";
  $bound{$var} and return $var;
  $bound{$var} = "templated_URL";
  $url =~ s{\(([\w.]+)\)}{prebind($1); qq{",?$1,"}}ge;
  $url = qq{"$url"};
  $url =~ s{,""}{}g;
  $url =~ s{^"",}{};
  addWhere($index, "bind(iri(concat($url)) as $var)");
  $var
}

sub prefixed_url($$$) {
  my $index = shift;
  my $prefix = shift;
  my $localname = shift;
  prebind($localname);
  my $var = $prefix."_".$localname;
  $var =~ s{-}{_};
  $var = "?".$var."_URL";
  $localname = "?".$localname;
  $bound{$var} && $bound{$var} ne "prefixed_URL" and die "$var is used for both prefixed_URL and $bound{$var}\n";
  $bound{$var} and return $var;
  $bound{$var} = "prefixed_URL";
  addWhere($index,"bind(iri(concat(str($prefix:),$localname)) as $var)");
  $var
}

## main

$_ = <>;
my ($graph) = m{#+ GRAPH <(.*)>};
$form eq "update" && !$graph and die "Update requires # GRAPH <...>, got $_";
$form eq "construct" && $tool ne "fx" && $graph and die "$tool $form does not support GRAPH\n";
my $first_line = $graph ? undef : $_;
$GRAPH = templated_url ($tool eq "fx" ? 2 : 0, $graph) if $graph;

die "--filterColumn and --filter must be used together\n" if $filter xor $filterColumn;
if ($filterColumn) {
  die "--filterColumn and --filter can be used only with ontorefine update, but you've selected $tool $form\n"
    unless $form eq "update" && $tool eq "ontorefine";
  ontorefine(0,$filterColumn);
  addWhere(4,$filter)
};

while ($first_line or $_ = <>) {
  $first_line = undef;
  m{puml:label *['"]+(.*?)['"]+ *[;.] *( *#.*)?$} and do {addWhere(1,$1); next};
  m{puml:|plantuml} and next; # skip any other puml statements
  while (m{\((\w+)\)}gc) {prebind($1)};
  m{(\w+)\(([\w,]+)\)} and prebind_all($1,$2);
  while (s{(\w+)\((\w+)([,?\w]*)\)}{function(2,$1,$2,$3)}ge)
    # recursively replace function calls.
    # <industry/URLIFY(foo)> -> <industry/(foo_URLIFY)>: single parentheses needed to enact templated_url
    # <industry/URLIFY(SPLIT(foo))> -> <industry/URLIFY((foo_SPLIT))> : double parens, reduce them -> <industry/URLIFY(foo_SPLIT)> -> <industry/(foo_SPLIT_URLIFY)>
    {s{\(\((\w+)\)}{($1}g}; # reduce double parens
  s{['"]([^'"]+\([^'"]*)['"]}{templated_string(2,$1)}ge; # starts with some constant chars
  s{['"](\(\w+\)[^'"]+)['"]}{templated_string(2,$1)}ge; # starts with a variable
  s{['"]\((\w+)\)['"]\^\^([\w:]+)}{typecast($1,$2)}ge;
  s{['"]\((\w+)\)['"]\@([\w-]+)}{strlang($1,$2)}ge;
  s{['"]\((\w+)\)['"]}{?$1}g; # simple var
  s{<([^\s>]*\([^\s>]*)>}{templated_url(2,$1)}ge;
  s{([\w-]+):\\\((\w+)\\\)}{prefixed_url(2,$1,$2)}ge; # localname must escape parens, eg: qk:\(quantityKind\)
  $_ = "  $_" if $_;
  $output = "$output$_";
};
$output = "graph $GRAPH {\n$output\n}" if $GRAPH && $form eq "construct";

# If "update" accesses patterns outside "service", wrap in a subquery to enforce execution there
# https://github.com/VladimirAlexiev/rdf2rml/issues/46
# https://ontotext.atlassian.net/issues/GDB-8365
my $delete_subquery_open  = " {select * {";
my $delete_subquery_close = "}}";
my $insert_subquery_open  = $where[3] || $where[4] ? $delete_subquery_open  : "";
my $insert_subquery_close = $where[3] || $where[4] ? $delete_subquery_close : "";

print

  $form eq "update" ? << "EOF"
delete {graph $GRAPH {?_s_ ?_p_ ?_o_}}
where {
 $delete_subquery_open service <$endpoint> {
$where[0]
  }$delete_subquery_close
$where[4]
  graph $GRAPH {?_s_ ?_p_ ?_o_}};

insert {graph $GRAPH {
$output}}
where {
 $insert_subquery_open service <$endpoint> {
$where[0]$where[1]$where[2]
  }$insert_subquery_close
$where[3]$where[4]};
EOF

  : $tool eq "ontorefine" ? << "EOF"
construct {
$output}
where {
 $insert_subquery_open service <$endpoint> {
$where[0]$where[1]$where[2]
  }$insert_subquery_close
$where[3]$where[4]}
EOF

  : $tool eq "fx" ? << "EOF"
construct {
$output}
where {
  service <x-sparql-anything:> {
    fx:properties
      fx:location \$_location ;
      fx:csv.headers "true" ;
      fx:csv.headers.sanitize "true" ;
      fx:csv.null-string "" ;
    .
    $where[0]$where[1]$where[2]
  }
}
EOF

  # tarql construct
  : << "EOF";
construct {
$output}
where {
$where[0]$where[1]$where[2]
}
EOF

# TODO use fx:read-from-std-in "true" instead of fx:location

