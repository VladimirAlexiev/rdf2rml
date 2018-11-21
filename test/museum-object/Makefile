IGNORE = prefixes.ttl
TTL    = $(filter-out $(IGNORE), $(wildcard *.ttl))
PUML   = $(patsubst %.ttl, %.puml, $(TTL))
PNG    = $(patsubst %.ttl, %.png, $(TTL))
R2RML  = objects.r2rml.ttl

all : $(PUML) $(PNG) $(R2RML)

%.puml : %.ttl
	rdfpuml.bat $<

%.png : %.puml
	puml.bat $<

%.r2rml.ttl : %.ttl
	rdf2rml.sh $< >$@

