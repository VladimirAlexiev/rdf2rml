all: prefixes.rq attr-sysRefPref.fx attr-sysRefPref.png attr-sysRefPref-with-graph-colors.png attr-sysRefPref-with-graph-labels.png

prefixes.rq: prefixes.ttl
	perl -pe 'm{###} and last; s{^@}{}; s{ *\.$$}{}' $^ > $@

%.puml: %.trig
	perl -S rdfpuml.pl $*.trig

%.png: %.puml
	puml $*.puml

%.fx: common.h prefixes.rq %.trig
	perl -S rdf2sparql.pl -fx $*.trig | cat common.h prefixes.rq - | cpp -E -P -C -nostdinc - > $*.fx

