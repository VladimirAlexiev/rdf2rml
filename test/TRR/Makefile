IGNORE = prefixes.ttl
TTL    = $(filter-out $(IGNORE), $(wildcard *.ttl))
PNG    = $(patsubst %.ttl, %.png, $(TTL))

all : $(PNG)

%.puml : %.ttl
	rdfpuml.bat $<

%.png : %.puml
	puml.bat $<
