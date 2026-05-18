.DELETE_ON_ERROR:

all: reification-owl_Axiom.png

%.png : %.ttl prefixes.ttl
	rdfpuml.bat $*.ttl
	puml $*.puml
	rm $*.puml
