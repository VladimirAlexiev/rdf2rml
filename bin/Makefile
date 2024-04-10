.PHONY: clean

# TODO: Simplify command
# "In your case pp -c -o rdfpuml.exe -I lib rdfpuml.pl does the trick"
# https://github.com/rschupp/PAR-Packer/issues/88#issuecomment-2027435765
rdfpuml.exe: rdfpuml.pl
	pp -o $@ -M RDF::Trine:: -M RDF::Query:: -M Data::Perl::Collection::Hash::MooseLike -M FindBin -a ../lib/RDF/Prefixes $^

clean:
	rm rdfpuml.exe
