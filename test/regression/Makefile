IGNORE = prefixes.ttl
TTL    = $(filter-out $(IGNORE), $(wildcard *.ttl))
PUML   = $(patsubst %.ttl, %.puml, $(TTL))
PNG    = $(patsubst %.ttl, %.png, $(TTL))

all : $(PUML) $(PNG)

%.puml : %.ttl
	rdfpuml.bat $<

%.png : %.puml
	puml.bat $<

