use RDF::Trine;
my $store = RDF::Trine::Store::Memory->new();
our $model = RDF::Trine::Model->new($store) or die "can't create model: $!\n";
my $parser = RDF::Trine::Parser->new('trig') or die "can't create trig parser: $!\n";
#$parser->parse_into_model (undef, "graph <urn:g> {<urn:s> <urn:p> <urn:o>}", $model);
$parser->parse_into_model (undef, "GRAPH <urn:g> {<urn:s> <urn:p> <urn:o>}", $model);
#$parser->parse_into_model (undef, "<urn:s> <urn:p> <urn:o>", $model);
