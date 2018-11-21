#!perl -w

use lib "../lib";
use RDF::Prefixes::Curie;

my $prefixes = RDF::Prefixes::Curie->new(\*DATA);
# my $prefixes = RDF::Prefixes::Curie->new("prefixes.ttl");

use feature 'say';
say $prefixes->turtle;
say $prefixes->get_qname('http://museum1.org/object/BCR187052');    # <object/BCR187052> # uses base
say $prefixes->get_qname('http://museum2.org/object/BCR187052');    # :object/BCR187052  # uses empty prefix. Slash in CURIE
say $prefixes->get_qname('http://museum3.org/object/BCR187052');    # <http://museum3.org/object/BCR187052> # neither base nor prefix
say $prefixes->get_qname('http://vocab.getty.edu/aat/1234');        # aat:1234          # starting digit in CURIE
say $prefixes->get_qname('http://vocab.getty.edu/aat/contrib/456'); # aat_contrib:456   # longest prefix match

__DATA__
@base     <http://will-be-ignored.com>.
@base     <http://museum1.org/>.
@prefix : <http://museum2.org/>.                    # Another Museum
@prefix aat:         <http://vocab.getty.edu/aat/>. # Getty AAT
@prefix aat_contrib: <http://vocab.getty.edu/aat/contrib/>.

