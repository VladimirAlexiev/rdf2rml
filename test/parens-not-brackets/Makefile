NONE: 

old: test-old.puml test-old.png
new: test-new.puml test-new.png

%.puml: test.ttl
	perl -S rdfpuml.pl test.ttl
	mv test.puml $*.puml

%.png: %.puml
	puml $*.puml
