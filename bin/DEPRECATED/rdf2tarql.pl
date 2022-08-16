#!perl -w

our $construct = "";
our $where     = "";
our %bound;

while ($_ = <>) {
 m{puml:|plantuml} and next;
 s{"\(([\w.]+)\)"\^\^([\w:]+)}{typecast($1,$2)}ge;
 s{"\(([\w.]+)\)"}{?$1}g; # simple var
 s{<([^\s>]*\([^\s>]*)>}{templated_url($1)}ge;
 $_ = "  $_" if $_;
 $construct = "$construct$_";
};

open PREFIXES, "prefixes.rq" or die "can't open prefixes.rq: $!\n";
$/ = undef;
my $prefixes = <PREFIXES>;
print << "EOF";
$prefixes
construct {
$construct
} where {$where
}
EOF

sub typecast {
  my $var = "?" . shift;
  my $dt = shift;
  my $VAR = uc $var; # upcase var name to show it's been changed
  $bound{$VAR} && $bound{$VAR} ne "typecast" and die "$VAR is used for both typecast and urlify\n";
  $bound{$VAR} and return $VAR;
  $bound{$VAR} = "typecast";
  # Jena has xsd:date("2020-05-22") but rdf4j has only strdt("2020-05-22",xsd:date) so we use that:
  $where = "$where\n  bind(strdt($var,$dt) as $VAR)";
  $VAR
}

sub templated_url {
  my $url = shift;
  my $var = $url . "_URL";
  $var =~ s{(urlify)?\([\w.]+\)}{_}g;
  $var =~ s{\W}{_}g;
  $var =~ s{__+}{_}g;
  $var =~ s{^_}{};
  $var =~ s{_$}{};
  $var = "?" . $var;
  $bound{$var} and return $var;
  $bound{$var} = "templated_URL";
  $url =~ s{urlify\(([\w.]+)\)}{urlify($1)}ge;
  $url =~ s{\(([\w.]+)\)}{",?$1,"}g;
  $url = qq{"$url"};
  $url =~ s{,""}{}g;
  $url =~ s{^"",}{};
  $where = "$where\n  bind(iri(concat($url)) as $var)";
  $var
}

# Replace sequences of non-alphanumeric chars with '_', and leading/trailing with nothing.
# We use the Unicode categories \p{L} (letter) and \p{N} (number),
# see http://www.unicode.org/reports/tr18/#General_Category_Property.
# This handles accented chars, eg <university/Universität_Heidelberg> (IRIs allow such).

sub urlify {
  my $var = "?". shift;
  my $VAR = uc $var;
  $bound{$VAR} && $bound{$VAR} ne "urlify" and die "$VAR is used for both typecast and urlify\n";
  $bound{$VAR} and return qq{",$VAR,"};
  $bound{$VAR} = "urlify";
  $where = "$where\n  bind(replace(replace(replace($var,'[^\\\\p{L}\\\\p{N}]+','_'),'^_',''),'_\$','') as $VAR)";
  qq{",$VAR,"}
}
