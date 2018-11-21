package RDF::Prefixes::Curie;

# TODO: Trine preserves namespaces, see https://github.com/kasei/perlrdf/issues/130 but:
# - abbreviate instead of qname
# - @base is still not supported: https://github.com/kasei/perlrdf/issues/131
# - abbreviate would pick any of applicable prefixes because # reverse lookup is many-to-one
# Empty prefixes work fine:
# $ perl -w -MData::Dumper -MRDF::Trine::NamespaceMap -MRDF::Trine::Namespace \
#  -e '$x=RDF::Trine::NamespaceMap->new({""=>"http://vocab.getty.edu/aat/"}); print $x->abbreviate("http://vocab.getty.edu/aat/123")'
#  :123

use warnings;
use strict;
use utf8;

BEGIN {
  $RDF::Prefixes::Curie::AUTHORITY = 'cpan:VALEXIEV';
  $RDF::Prefixes::Curie::VERSION   = '0.001';
}

sub new {
  my ($class, $turtle) = @_;
  my $prefixes =
    ref($turtle) && ref($turtle) eq 'HASH' ? $turtle :
    $turtle !~ /\n/ # prevent Unsuccessful stat on filename containing newline
    && -e $turtle ? do {
      local $/ = undef;
      ref($turtle) ? <$turtle> :
        do {
          open(TURTLE,$turtle) or die "can't open $turtle: $!\n";
          $turtle = <TURTLE>;
          close(TURTLE);
          $turtle
        }
      } :
    $turtle;

  my %prefixes;
  while ($prefixes =~ m{^\s*\@prefix\s+(.*?): *<(.*?)>}gm) {$prefixes{$1} = $2};
  while ($prefixes =~ m{^\s*\@base\s*<(.*?)>}gm) {$prefixes{'@base'} = $1};
  my $self = bless {prefixes => \%prefixes}, $class;
  $self->_reset_prefixes();
  #use Data::Dumper; print Dumper($self);
  $self;
}

sub _reset_prefixes {
  my $self = shift;
  my %reverse = reverse %{$self->{prefixes}};
  my $prefix_re =
    join "|", map quotemeta,
    # want longer prefixes to take precedence
    sort { length($b) <=> length($a) } keys %reverse;
  $prefix_re = qr{^($prefix_re)(.*)$};
  #print STDERR $prefix_re;
  $self->{reverse} = \%reverse;
  $self->{prefix_re} = $prefix_re
}

# sub add_prefixes {
#   my $self = shift;
#   my $prefixes = shift;
#   $self->{prefixes} = {%{$self->{prefixes}}, %{$prefixes}};
#   $self->_reset_prefixes();
# }

sub prefixes {
  my ($self) = shift;
  $self->{prefixes}
}

sub turtle {
  my $self = shift;
  my %p = %{$self->{prefixes}};
  my $base = $p{'@base'};
  ($base ? "\@base  <$base> .\n" : "") .
    (join "",
     map "\@prefix $_: <$p{$_}> .\n",
     grep $_ ne '@base',
     sort keys %p
    )
}

sub get_qname {
  my ($self,$uri) = @_;
  $uri !~ m{$self->{prefix_re}} ? "<$uri>" :
    do {
      # $1=prefix, $2=rest
      my $p = $self->{reverse}{$1};
      $p eq '@base' ? "<$2>" :
        "$p:$2"
      }
}

sub uri {
  my ($self,$qname) = @_;
  $qname =~ m{^(\w*):(.*)$} or die "expected qname, got $qname\n";
  my $p = $self->{prefixes}{$1} or die "$1 not found in prefixes\n";
  "$p$2"
}

1

__END__

=head1 NAME

RDF::Prefixes::Curie - turn URIs into QNames aggressively

=head1 SYNOPSIS

 use RDF::Prefixes::Curie;
 my $prefixes = RDF::Prefixes::Curie->new(\*DATA);
 # my $prefixes = RDF::Prefixes::Curie->new("prefixes.ttl");

 use feature 'say';
 say $prefixes->get_qname('http://museum1.org/object/BCR187052');    # <object/BCR187052> # uses base
 say $prefixes->get_qname('http://museum2.org/object/BCR187052');    # :object/BCR187052  # uses empty prefix. Slash in CURIE
 say $prefixes->get_qname('http://museum3.org/object/BCR187052');    # <http://museum3.org/object/BCR187052> # neither base nor prefix
 say $prefixes->get_qname('http://vocab.getty.edu/aat/1234');        # aat:1234          # starting digit in CURIE
 say $prefixes->get_qname('http://vocab.getty.edu/aat/contrib/456'); # aat_contrib:456   # longest prefix match

 __DATA__
 @base     <http://museum1.org/>.
 @prefix : <http://museum2.org/>.                    # Another Museum
 @prefix aat:         <http://vocab.getty.edu/aat/>. # Getty AAT
 @prefix aat_contrib: <http://vocab.getty.edu/aat/contrib/>.

=head1 DESCRIPTION

This module loads prefixes from a Turtle file and then shortens URLs using the longest matching prefix.
It allows an empty prefix ":" and handles @base.
It is also very lax about what chars go into the qname, eg starting digit (allowed in Turtle 1.1) and slash (not allowed in Turtle).
It is mostly useful for generating diagrams, where shortness is critically important.

=head2 Constructor

=over 4

=item C<< new($filename|$filehandle|\%prefixes) >>

Reads prefixes and base from a Turtle file (name or handle).
You can also pass a hash: use '@base' as the key for the base entry.
Using an empty prefix is allowed.

=back

=head2 Methods

=over 4

=item C<< get_qname($uri) >>

Gets the qname CURIE associated with a URI.
If there is no prefix matching the URI, returns it surrounded with brackets: <URL>.
See examples above.

=item C<< prefixes >>

Returns a hashref of prefix mappings.

=item C<< turtle >>

Returns the Turtle representation of the prefixes and base (if any)

=back

=head2 Internationalisation

Strings passed to and from this module are expected to be utf8 character
strings, not byte strings. URIs containing non-Latin characters should "just work".

=head1 BUGS

Limitations:
- Prefixes may include key "@base", and other modules may hickup on it
- The prefixes are put in a regexp in the constructor new(), so you can't add additional prefixes later
- If the Turtle file defines base or a prefix several times, the last occurrence wins.
- If base and a prefix use the same URL, the last occurrence wins.

Please report any bugs to TODO.

=head1 AUTHOR

Vladimir Alexiev (valexiev) E<lt>vladimir.alexiev@ontotext.comE<gt>.

=head1 COPYRIGHT

Copyright 2015 Vladimir Alexiev

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
