#!perl -w

# Author: vladimir.alexiev@ontotext.com
# 20160210 1.0
# - support blank nodes
# - support new puml "hidden" links that can sometimes help the layout: http://plantuml.com/class-diagram#layout
# 20170825 1.1
# - fix unicode of "decorative arrows"
# 20180225
# - support arrow color (named or hex)

# #!/bin/sh
# #! -*-perl-*-
# eval 'exec perl -x -wS "$( cygpath -w "$0" )" ${1+"$@"}'
#     if 0;

use strict;
use Encode;
use Carp::Always; # http://search.cpan.org/~ferreira/Carp-Always-0.13/lib/Carp/Always.pm
  # stronger than $Carp::Verbose = 1;
use RDF::Trine;
use RDF::Query;
use Slurp;
use FindBin;
use lib "$FindBin::Bin/../lib"; # Curie is my own module, not yet on CPAN
use RDF::Prefixes::Curie;
#use Smart::Comments;
use File::Basename;

my %PREFIXES =
  (
   crm    => 'http://www.cidoc-crm.org/cidoc-crm/',
   crmx   => 'http://purl.org/NET/cidoc-crm/ext#',
   frbroo => 'http://example.com/frbroo/',
   crmdig => 'http://www.ics.forth.gr/isl/CRMdig/',
   crmsci => 'http://www.ics.forth.gr/isl/crmsci/',
   puml   => 'http://plantuml.com/ontology#',
   rdf    => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
   rdfs   => 'http://www.w3.org/2000/01/rdf-schema#',
   skos   => 'http://www.w3.org/2004/02/skos/core#',
   leak   => 'http://data.ontotext.com/resource/leak/',
  );
my $PREFIXES_TURTLE = join "\n", map "\@prefix $_: <$PREFIXES{$_}>.", sort keys(%PREFIXES);
my $PREFIXES_SPARQL = join "\n", map   "prefix $_: <$PREFIXES{$_}>",  sort keys(%PREFIXES);
my %HEAD = (none => "", tri => "|>", star => "*", o => "o");
my $HEAD_RE = join '|', keys %HEAD;
my $LINE_RE = "dotted|dashed|bold|hidden"; # http://plantuml.com/activity-diagram-beta#arrow

use utf8; # Unicode chars below
my %ARROW = (left => "←", right => "→", up => "↑", down => "↓");
my %OPPOSITE = (left => "right", right => "left", up => "down", down => "up");

my %dir; # $dir{$s}{$о} = left|right|up|down: direction of the relation between $s and $o
my %sanitized; # cona:700000166-thing -> cona_700000166_thing
my %predicate_arrow;

use constant {RE_CLASS=>0, RE_SUBJ_PROP=>1, RE_SHORTCUT_PROP=>2, RE_OBJ_PROP=>3};
my @RE =
  (
   [qw(rdf:Statement                 rdf:subject                    rdf:predicate                    rdf:object                )],
   [qw(crm:E13_Attribute_Assignment  crm:P140_assigned_attribute_to crmx:property                    crm:P141_assigned         )],
   [qw(crm:E14_Condition_Assessment  crm:P34_concerned              crmx:property                    crm:P35_has_identified    )],
   [qw(crm:E15_Identifier_Assignment crm:P140_assigned_attribute_to crmx:property                    crm:P37_assigned          )],
   [qw(crm:E15_Identifier_Assignment crm:P140_assigned_attribute_to crmx:property                    crm:P38_deassigned        )],
   [qw(crm:E16_Measurement           crm:P39_measured               crmx:property                    crm:P40_observed_dimension)],
   [qw(crm:E17_Type_Assignment       crm:P41_classified             crmx:property                    crm:P42_assigned          )],
   [qw(frbroo:F52_Name_Use_Activity  frbroo:R63_named               crmx:property                    frbroo:R64_used_name      )],
   [qw(crmsci:S4_Observation         crmsci:O8_observed             crmsci:O9_observed_property_type crmsci:O16_observed_value )],
   [qw(leak:Edge                     leak:hasSource                 rdf:nil                          leak:hasTarget            )],
  );

my $NOREL = # predicates that are not emitted as relations
  '^('.
  (join '|',
   map @$_[RE_SUBJ_PROP,RE_SHORTCUT_PROP,RE_OBJ_PROP], @RE # reification -> puml Assoc Class
  ).')$';

# E14,15,16,17 imply the shortuct prop, so RE_SHORTCUT_PROP is optional
my $RE = join " union\n", map <<SPARQL, @RE;
  {bind($_->[RE_SUBJ_PROP] as ?sp)
   bind($_->[RE_SHORTCUT_PROP] as ?pp)
   bind($_->[RE_OBJ_PROP] as ?op)
   ?re a $_->[RE_CLASS]; ?sp ?s; ?op ?o.
   optional {?re ?pp ?p}}
SPARQL

my $RE_SPARQL = <<"SPARQL";
$PREFIXES_SPARQL

select ?re ?sp ?pp ?op ?s ?p ?o {
$RE
filter not exists {?re a puml:NoReify}}
SPARQL
## $RE_SPARQL;

my $fname = shift or die "perl rdfpuml <file>: read <file>.ttl, write <file>.puml\n";
$fname =~ s{\.ttl$}{};

my $prefixes = -e "prefixes.ttl" ? slurp("prefixes.ttl") : "";
my $file = slurp("$fname.ttl");
my $turtle = decode_utf8 "$PREFIXES_TURTLE\n$prefixes\n$file";
my $prefixes_all = decode_utf8 "$PREFIXES_TURTLE\n$prefixes";
open (STDOUT, ">:encoding(UTF-8)", "$fname.puml") or die "can't create $fname.puml: $!\n";
binmode STDERR, ":encoding(UTF-8)";
#print STDERR $turtle; die;

my $store = RDF::Trine::Store::Memory->new();
my $model = RDF::Trine::Model->new($store) or die "can't create model: $!\n";
my $parser = RDF::Trine::Parser->new('turtle');
$parser->parse_into_model (undef, $turtle, $model);
my $map = RDF::Prefixes::Curie->new ($prefixes_all);

my $dirname = dirname(__FILE__);
my $plantuml_cfg_fn = "plantuml.cfg";
my $sep = File::Spec->catfile('', '');
my $plantuml_cfg_path = $dirname . $sep  . $plantuml_cfg_fn;

open my $plantuml_cfg_fh, '<', $plantuml_cfg_path or die "Can't open $plantuml_cfg_path $!";
my $plantuml_cfg  = do { local $/; <$plantuml_cfg_fh> };

myprint (<<'EOF');
@startuml
EOF

myprint ("$plantuml_cfg\n");

stereotypes();
replace_inlines();
collect_predicate_arrows();

for my $s ($model->subjects(undef,undef)) {
  my $s1 = puml_node($s);
  my $noReify = print_types ($s, $s1); # types come first
  print_relations ($s, $s1, $noReify);
  print_attributes ($s, $s1); # literals and inline objects
}
reification();

myprint ("\@enduml\n");

sub print_types {
  my ($s, $s1) = @_;
  my @types = map puml_node2($_), $model->objects ($s, U("rdf:type"));
  my $noReify = grep m{puml:NoReify}, @types;
  my $types = join ", ", grep !m{puml:NoReify}, @types;
  myprint (qq{$s1 : a $types\n}) if $types;
  return $noReify
}

sub print_relations {
  my ($s, $s1, $noReify) = @_;
  for my $o ($model->objects ($s, undef, undef, type=>'resource'),
             $model->objects ($s, undef, undef, type=>'blank')) {
    # collect all relations between the two nodes.
    # TODO: also collect inverse relations? Then be careful for reifications!
    my @predicates = grep !m{rdf:type}, map puml_predicate($_), $model->predicates ($s, $o);
    # TODO: remove actually reified predicates (see reification()), not potentially reifiable ($NOREL)
    @predicates = grep !m{$NOREL}o, @predicates if !$noReify;
    next unless @predicates;
    my $arrow = find_predicate_arrow(@predicates);
    my @pred1 = grep !m{puml:}, @predicates;
    @pred1 = ("") if !@pred1; # allow a decorative arrow alone
    my $o1 = puml_node($o);
    $arrow = puml_arrow ($arrow, $s1, $o1);
    my $predicates = join '\n', @pred1; # each predicate label on new line, centered
    $predicates = " : $predicates" if $predicates;
    myprint (qq{$s1 $arrow $o1$predicates\n})
  }
}

sub print_attributes {
  my ($s, $s1) = @_;
  my $it = $model->get_statements ($s, undef, undef);
  my %st;
  while (my $st = $it->next) {
    my $o = $st->object;
    next unless $o->is_literal;
    my $o1 = puml_literal($o);
    my $p = $st->predicate;
    my $p1 = puml_predicate($p);
    push @{$st{$p1}}, $o1
  }
  for my $p1 (sort keys %st) {
    my $os = scalar @{$st{$p1}} > 1 ?
      "\\n  ".(join ",\\n  ", sort @{$st{$p1}}) :
      " ".$st{$p1}->[0];
    myprint ("$s1 : $p1$os\n")
  }
}

sub myprint {
  print shift # encode_utf8(shift)
}

sub U {
  my $uri = $map->uri(shift);
  # print STDERR "$uri\n";
  RDF::Trine::Node::Resource->new ($uri)
}

sub replace_inlines {
  # ?inline a puml:Inline
  map replace_inline($_), $model->subjects (U("rdf:type"), U("puml:Inline"));
  # ?prop a puml:InlineProperty: inline all Objects of ?prop
  map {map replace_inline($_), grep $_->is_resource(), $model->objects (undef, $_, undef)}
    $model->subjects (U("rdf:type"), U("puml:InlineProperty"));
  $model->remove_statements (undef, U("rdf:type"), U("puml:InlineProperty"));
  # For puml:NoReify nodes, inline the property pointed by SHORTCUT_PROP
  for my $sp (map U(@$_[RE_SHORTCUT_PROP]), @RE) {
    for my $noReify ($model->subjects (U("rdf:type"), U("puml:NoReify"))) {
      my $it = $model->get_statements ($noReify, $sp);
      while (my $st = $it->next) {
        next unless $st->object->is_resource; # $repl_st is returned by the iterator :-(
        # print STDERR $st->as_string;
        my $repl = $map->get_qname($st->object->uri_value);
        $repl = RDF::Trine::Node::Literal->new ($repl, undef, U("puml:noquote"));
        my $repl_st = RDF::Trine::Statement->new ($st->subject, $st->predicate, $repl);
        $model->remove_statement ($st);
        $model->add_statement ($repl_st);
      }
    }
  }
}

sub replace_inline {
  # replace given node with a literal having the url, and optionally its label
  my $inline = shift;
  my $repl = puml_qname($inline);
  my ($label) = $model->objects ($inline, U("rdfs:label"));
  $label or ($label) = $model->objects ($inline, U("skos:prefLabel"));
  $repl .= " # " . $label->value if $label;
  $repl = RDF::Trine::Node::Literal->new ($repl, undef, U("puml:noquote")); # use as datatype
  my $it = $model->get_statements (undef, undef, $inline);
  while (my $st = $it->next) {
    next if $st->predicate->uri_value eq U("rdf:type")->uri_value; # avoid nasty BUG1, see at bottom
    my $repl_st = RDF::Trine::Statement->new ($st->subject, $st->predicate, $repl);
    $model->remove_statement ($st);
    $model->add_statement ($repl_st);
  }
  $model->remove_statements ($inline, undef, undef);
}

sub reification {
  # print STDERR $RE_SPARQL; die;
  my $query = RDF::Query->new($RE_SPARQL);
  # print STDERR $query; die;
  # print STDERR $model->as_string; die;
  my $it = $query->execute($model);
  while (my $row = $it->next) {
    $row->{o}->is_resource or die "can't reify literal: $row->{s} $row->{p} $row->{o}\n";
    # parallel relations are collected into one, so $p is ignored
    my $re = puml_node     ($row->{re}); # no blank node reifications, sorry
    my $sp = puml_predicate($row->{sp});
    my $pp = puml_predicate($row->{pp}); $pp = undef if $pp eq 'rdf:nil';
    my $op = puml_predicate($row->{op});
    my $s  = puml_node2    ($row->{s}); # semi-sanitized
    my $p  = puml_predicate($row->{p});
    my $o  = puml_node2    ($row->{o}); # semi-sanitized
    my $s1 = puml_node     ($row->{s}); # sanitized
    my $o1 = puml_node     ($row->{o}); # sanitized
    my $dir2 = $dir{$s1}{$o1} or die "$s->$o is in reification $re but not as direct relation\n";
    my $dir1 = $OPPOSITE{$dir2};
    my $arr1 = $ARROW{$dir1};
    my $arr2 = $ARROW{$dir2};
    # http://plantuml.com/classes.html#Association_classes
    # http://plantuml.sourceforge.net/qa/?qa=3788/set-direction-of-association-class
    my $orient = $dir1 =~ m(left|right) ? '..' : '.';
    my $dash   = $dir1 =~ m(left|right) ? ':' : '..';
    # http://plantuml.sourceforge.net/qa/?qa=4037/association-node-breaks-link-direction
    my $pair   = $dir2 =~ m{down|right} ? "$s1, $o1" : "$o1, $s1";
    myprint qq{($pair) $orient $re\n};
    # print prop names with decorative Unicode arrows. Do not use myprint() below, as the arrows are already Unicode chars
    print qq{$re : $arr1 $sp $s\n};
    print qq{$re : $dash $pp $p\n} if $pp && $p;
    print qq{$re : $arr2 $op $o\n};
  }
}

sub puml_qname {
  my $node = shift;
  return "" unless $node;
  $map->get_qname($node->uri_value);
}

sub puml_predicate {
  my $pred = puml_qname(shift);
  $pred eq "puml:label" ? "" : $pred
}

sub puml_node1 {
  # if blank node, return unchanged. Else qname (prefixed form)
  my $node = shift;
  my $isBlank = $node->is_blank;
  $node = $isBlank ? $node->as_string : puml_qname($node);
  ($node,$isBlank)
}

sub puml_node2 {
  # semi-sanitize: round parens to square parens else PUML makes a method
  my $node = puml_qname(shift);
  $node =~ tr{()}{[]};
  $node
}

sub puml_node {
  my ($node,$isBlank) = puml_node1(shift);
  my $sanitized = $sanitized{$node};
  return $sanitized if $sanitized;
  $sanitized = $node;
  $sanitized =~ s{\W+}{_}g;
  $node =~ s{_+}{_}g; # else platts___gasoil___asia___03 causes underlining
  $sanitized{$node} = $sanitized;
  $node = " " if $isBlank; # puml doesn't allow "" here
  myprint qq{class $sanitized as "$node"\n};
  $sanitized
}

sub puml_literal {
  my $node = shift;
  my $val = $node->literal_value;
  my $dt = $node->literal_datatype;
  my $lang = $node->literal_value_language;
  $dt = $dt ? $map->get_qname($dt) : '';
  $dt = "puml:noquote" if
    $dt eq 'xsd:integer' && $val =~ /^[+-]?[0-9]+$/
    || $dt eq 'xsd:decimal' && $val =~ /^[+-]?[0-9]*\.[0-9]+$/
    || $dt eq 'xsd:double'  && $val =~ /^(?:(?:[+-]?[0-9]+\.[0-9]+)|(?:[+-]?\.[0-9]+)|(?:[+-]?[0-9]))[Ee][+-]?[0-9]+$/
    || $dt eq 'xsd:boolean' && $val =~ /^(true|false|0|1)/;
  $val =~ s{\n}{\\n}g; # newline to PUML newline
  $val =~ tr{()}{[]}; # round parens to square parens else PUML makes a method
  $val = qq{"$val"} unless $dt eq "puml:noquote";
  $val .= '@' . $lang if $lang;
  $val .= '^^' . $dt if $dt && $dt ne "puml:noquote";
  $val
}

sub puml_arrow {
  # puml:$dir-$head-$line-$COLOR
  # puml:(left|right|up|down)-(none|tri|star|o)-(dotted|dashed|hidden)-bold-COLOR
  # Where color is hex (eg 0000FF) or name (eg red, blue, green...)
  local $_ = shift || '';
  my ($s,$o) = @_;
  s{puml:}{};
  # we remove matched parts from the arrow name, so the remaining thing is the COLOR
  my $dir = 'down'; m{\b(left|right|up|down)\b} and ($dir=$1, s{}{});
  $dir{$s}{$o} = $dir;
  ##print STDERR "puml_arrow DIR: $_: $dir\n" if $_;
  my $head = '>'; m{\b($HEAD_RE)\b}o and ($head=$HEAD{$1}, s{}{});
  ##print STDERR "puml_arrow HEAD: $_: '$head'\n" if $_;
  my @line; while (m{\b($LINE_RE)\b}og) {push @line, $1; s{}{}};
  my $len = 1; m{\b(\d{1,2})\b} and ($len=$1, s{}{});
  my $arrow = '-' x $len;
  # color: https://stackoverflow.com/questions/38451956/how-do-i-color-a-single-arrow-in-a-plant-uml-component-diagram
  while (m{\b(\w+)\b}g) {push @line, "#".$1; s{}{}} ;
  my $line = @line ? "[".(join",",@line)."]" : '';
  ##print STDERR "puml_arrow LINE: $_: @line\n" if @line;
  "-$dir$line$arrow$head"
}

sub collect_predicate_arrows {
  # eg "nif:oliaLink puml:arrow puml:up" causes $predicate_arrow{"nif:oliaLink"} = "puml:up"
  my $it = $model->get_statements (undef, U("puml:arrow"), undef);
  while (my $st = $it->next) {
    $predicate_arrow{$map->get_qname($st->subject->uri_value)} = $map->get_qname($st->object->uri_value)
  };
  $model->remove_statements (undef, U("puml:arrow"), undef);
}

sub find_predicate_arrow {
  # for each predicate in the list: return its specified arrow; or return itself if it's an arrow
  for (@_) {
    return $predicate_arrow{$_} if exists $predicate_arrow{$_};
    return $_ if m{puml:}
  }
  return undef
}

sub stereotypes {
  my $it = $model->get_statements (undef, U("puml:stereotype"), undef);
  while (my $st = $it->next) {
    my $class = $st->subject;
    my $stereotype = $st->object->literal_value;
    my $circle = $stereotype =~ m{\(.*\)};
    my $it1 = $model->get_statements (undef, U("rdf:type"), $class);
    my @nodes;
    if (!$it1->finished) {
      # whole class with instances, eg fn:AnnotationSet puml:stereotype "(F)Frame"
      my $st1;
      push @nodes, $st1->subject while $st1 = $it1->next;
    } elsif (has_statements_different_from ($class,U("puml:stereotype"))) {
      # individual node, eg <#char=22,24_annoSet> puml:stereotype "(F)Frame"
      @nodes = ($class)
    }
    map {
      my $node = puml_node($_);
      myprint ("class $node <<$stereotype>>\n");
      myprint ("show $node circle\n") if $circle;
    } @nodes;
  };
  $model->remove_statements (undef, U("puml:stereotype"), undef);
}

sub has_statements_different_from {
  # check if $node has any outgoing or incoming statements, except a given property
  my $node = shift;
  my $except = shift;
  return
    $model->count_statements($node, undef, undef) - $model->count_statements($node, $except, undef) ||
    $model->count_statements(undef, undef, $node) - $model->count_statements(undef, $except, $node)
}
