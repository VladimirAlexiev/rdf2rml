all: enum.ttl enum-with-graph.nq

prefixes.rq: prefixes.ttl
	perl -pe 'm{###} and last; s{^@}{}; s{ *\.( *#.*)?$$}{}' $^ > $@

%.fx: common.h prefixes.rq %.ttl
	perl -S rdf2sparql.pl -fx $*.ttl | cat common.h prefixes.rq - | cpp -P -C -nostdinc - > $@
	qparse --query $@ > /dev/null

enum.ttl: model-enum.fx enum.csv
	sparql-anything -q model-enum.fx -v location=enum.csv > $@
	rmdir tmp

enum-with-graph.nq: model-enum-with-graph.fx enum.csv
	sparql-anything -q model-enum-with-graph.fx -f nq -v location=enum.csv > $@
	rmdir tmp

