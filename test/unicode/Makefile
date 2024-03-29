.DELETE_ON_ERROR:

all: unicode.png

%.png : %.ttl prefixes.ttl
	rdfpuml.bat $*.ttl
	puml.bat $*.puml
	rm $*.puml
