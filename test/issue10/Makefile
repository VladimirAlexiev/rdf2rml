all: example.png example2.png

%.png : %.ttl prefixes.ttl
	rdfpuml $*.ttl
	puml $*.puml
	rm $*.puml
