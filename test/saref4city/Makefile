all: example1-saref4city.png example1-saref4city-smetana.png

%.puml: %.ttl
	rdfpuml.bat $*.ttl

example1-saref4city.png: example1-saref4city.puml
	puml.bat $^

example1-saref4city-smetana.png: example1-saref4city.puml
	puml.bat -pipe -Playout=smetana < $^ > $@
