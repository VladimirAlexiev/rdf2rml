IGNORE = prefixes.ttl
TTL    = $(filter-out $(IGNORE), $(wildcard *.ttl))
PUML   = $(patsubst %.ttl, %.puml, $(TTL))
PNG    = $(patsubst %.ttl, %.png, $(TTL))
R2RML  = exhibitions.r2rml.ttl
SQLITE = exhibitions.sqlite

all : $(PUML) $(PNG) $(R2RML) # $(SQLITE)

%.puml : %.ttl
	rdfpuml.bat $<

%.png : %.puml
	puml.bat $<

%.r2rml.ttl : %.ttl
	rdf2rml.sh $< >$@

%.sqlite : %.sql
	rm -f $@
	sqlite3 -init $< -cmd quit $@
