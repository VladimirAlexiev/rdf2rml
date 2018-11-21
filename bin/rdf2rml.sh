#!bash
# usage: rdf2rml.sh model.ttl > model.r2rml.ttl

declare TMP=c:/tmp
declare DIR=`dirname $0`

# convert prefixes to SPARQL form (strip leading @), skip any other lines. Add to SPARQL UPDATE script
perl -ne 'print if s{\@(.*)\.(.*)}{$1$2}' prefixes.ttl | \
  cat - $DIR/rdf2rml.ru > $TMP/rdf2rml.ru

# add prefixes to turtle
cat prefixes.ttl $1 > $TMP/rdf2rml-$$.ttl

PATH=$PATH:/cygdrive/c/prog/apache-jena/bin/

# Run jena SPARQL update, dump as NQuads, strip rr:graph name, prepend prefixes, convert to turtle, strip prefixes, sort by "paragraph" (turtle subject block)
update --data=$TMP/rdf2rml-$$.ttl --update=$TMP/rdf2rml.ru --dump 2>/dev/null | \
  perl -pe 's{ <http://www.w3.org/ns/r2rml#graph>}{}' | \
  cat prefixes.ttl - | \
  riot --syntax=turtle --formatted=turtle - | \
  grep -v '@prefix' | \
  perl -e '$/=""; print sort <>'

#  grep -v 'WARN  riot' | \
#  riot --syntax=nquads --out=turtle - #| \
#  sort | \

rm $TMP/rdf2rml-$$.ttl
