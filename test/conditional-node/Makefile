all: prefixes.rq organizations.png organizations.ru

prefixes.rq: prefixes.ttl
	perl -pe 'm{###} and last; s{^@}{}; s{ *\.$$}{}' $^ > $@

%.png: %.ttl
	perl -S rdfpuml.pl $*.ttl
	puml $*.puml
	rm $*.puml

%.ru: prefixes.rq %.ttl
	perl -S rdf2sparql.pl $*.ttl | cat common.h prefixes.rq - | cpp -P -C -nostdinc - > $*.ru
