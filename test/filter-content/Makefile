all: prefixes.rq content.png content.tarql content-result.ttl

prefixes.rq: prefixes.ttl
	perl -pe 'm{###} and last; s{^@}{}; s{ *\.$$}{}' $^ > $@

%.png: %.ttl
	perl -S rdfpuml.pl $*.ttl
	puml $*.puml
	rm $*.puml

%.tarql: prefixes.rq %.ttl
	perl -S rdf2sparql.pl -tarql $*.ttl | cat prefixes.rq - > $*.tarql

%-result.ttl: %.tarql %.csv
	tarql $^ > $@
