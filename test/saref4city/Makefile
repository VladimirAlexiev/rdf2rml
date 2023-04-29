all: example1-saref4city.png example1-saref4city-smetana.png example1-saref4city-vizjs.png example1-saref4city-elk.png

%.puml: %.ttl
	rdfpuml.bat $*.ttl

example1-saref4city.png: example1-saref4city.puml
	puml.bat $^

example1-saref4city-smetana.png: example1-saref4city.puml
	puml.bat -pipe -Playout=smetana < $^ > $@

example1-saref4city-vizjs.png: example1-saref4city.puml
	puml.bat -pipe -graphvizdot vizjs < $^ > $@

example1-saref4city-elk.png: example1-saref4city.puml
	puml.bat -pipe -Playout=elk < $^ > $@
