.DELETE_ON_ERROR:

all: reification-owl_Axiom.png reification-owl_Axiom-left-to-right.png reification-owl_Axiom-domain-up.png

%.png : %.ttl prefixes.ttl
	rdfpuml.bat $*.ttl
	puml $*.puml
	# rm $*.puml
