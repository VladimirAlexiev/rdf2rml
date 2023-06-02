all: rdf2rml.html rdfpuml.html rdf2sparql.html

%.html : %.md
	pandoc --standalone --wrap=preserve $< -o $@
