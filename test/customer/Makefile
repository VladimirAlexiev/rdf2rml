all: clean customer.tarql customer-result.ttl

.DELETE_ON_ERROR:

clean : 
	find . -type f -size 0 -delete

customer.tarql: ../../bin/rdf2tarql.pl customer.ttl
	perl $^ > $@

customer-result.ttl: customer.tarql customer.csv
	tarql $^ > $@
