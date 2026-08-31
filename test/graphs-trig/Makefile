all: prefixes.rq attr-sysRefPref.png attr-sysRefPref.fx

prefixes.rq: prefixes.ttl
	perl -pe 'm{###} and last; s{^@}{}; s{ *\.$$}{}' $^ > $@

%.png: %.trig
	perl -S rdfpuml.pl $*.trig
	puml $*.puml
	rm $*.puml

%.fx: common.h prefixes.rq %.trig
	perl -S rdf2sparql.pl -fx $*.trig | cat common.h prefixes.rq - | cpp -E -P -C -nostdinc - > $*.fx

