all: prefixes.rq organizations.png organizations.ru

prefixes.rq: prefixes.ttl
	perl -pe 'm{###} and last; s{^@}{}; s{ *\.$$}{}' $^ > $@

%.png: %.ttl
	perl -S rdfpuml.pl $*.ttl
	puml $*.puml
	rm $*.puml

%.ru: prefixes.rq %.ttl
	perl -S rdf2sparql.pl \
	  --filterColumn updated_at \
	  --filter "<cb> cb:updatedAt ?UPDATED_AT_DT bind(replace(str(?UPDATED_AT_DT),'T',' ') as ?UPDATED_AT) filter(?updated_at > ?UPDATED_AT)" \
	  $*.ttl | cat common.h prefixes.rq - | cpp -P -C -nostdinc - > $*.ru
