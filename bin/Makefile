.PHONY: clean

rdfpuml.exe: rdfpuml.pl
	pp -o $@ -M RDF::Trine:: -M RDF::Query:: -M Data::Perl::Collection::Hash::MooseLike -M FindBin -a ../lib/RDF/Prefixes $^

clean:
	rm rdfpuml.exe
