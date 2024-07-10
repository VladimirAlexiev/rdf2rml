all: example.png example2.png example-iof.puml example-iof.png example-iof-puml.png

%.puml: %.ttl | prefixes.ttl
	rdfpuml.bat $^

%.png: %.puml
	plantuml $^

