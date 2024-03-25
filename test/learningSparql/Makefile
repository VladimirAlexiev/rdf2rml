all: ex012.png ex012.svg

%.png: %.ttl
	rdfpuml.bat $*.ttl
	puml.bat $*.puml
	rm $*.puml

%.svg: %.ttl
	rdfpuml.bat $*.ttl
	puml.bat -Tsvg $*.puml
	rm $*.puml

