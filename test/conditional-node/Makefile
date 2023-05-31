all: prefixes.rq organizations.png organizations.ru test-macro-out.txt

prefixes.rq: prefixes.ttl
	perl -pe 'm{###} and last; s{^@}{}; s{ *\.$$}{}' $^ > $@

%.png: %.ttl
	perl -S rdfpuml.pl $*.ttl
	puml $*.puml
	rm $*.puml

%.ru: prefixes.rq %.ttl
	perl -S rdf2sparql.pl $*.ttl | cat common.h prefixes.rq - | cpp -P -C -nostdinc - > $*.ru

test-macro-out.txt: test-macro-in.txt
	cpp -P -C -nostdinc $^ > $@
