all: permid-model-fin.png permid-model-org.png permid-model-pers.png sample-RobinSmith-positions.png sample-SirmaGroup-AtanasKiryakov.png

%.png : %.ttl
	rdfpuml.bat $*.ttl
	puml.bat $*.puml
	rm $*.puml
