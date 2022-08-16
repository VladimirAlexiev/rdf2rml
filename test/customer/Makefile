all: clean customer.tarql customer-result.ttl

.DELETE_ON_ERROR:

clean : 
	find . -type f -size 0 -delete

customer.tarql: ../../bin/rdf2sparql.pl customer.ttl
	perl ../../bin/rdf2sparql.pl --tarql customer.ttl | cat common.h prefixes.rq - | cpp -P -C -nostdinc - > $@

customer-result.ttl: customer.tarql customer.csv
	tarql --base http://example.org/resource/ --write-base $^ > $@
