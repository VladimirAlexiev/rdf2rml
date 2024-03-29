.DELETE_ON_ERROR:

all: persoon.png persoon-contributors.png

%.png : %.ttl prefixes.ttl
	rdfpuml.bat $*.ttl
	puml.bat $*.puml
	rm $*.puml
