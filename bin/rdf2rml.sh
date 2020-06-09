#!bash
# usage: rdf2rml.sh model.ttl > model.r2rml.ttl

TMP=c:/tmp
DIR=`dirname $0`
[[ `uname` = CYGWIN* ]] && EXT=".bat"

# convert prefixes to SPARQL form (strip leading @), skip any other lines. Add to SPARQL UPDATE script
perl -ne 'print if s{\@(.*)\.(.*)}{$1$2}' prefixes.ttl | \
  cat - $DIR/rdf2rml.ru > $TMP/rdf2rml.ru

# add prefixes to turtle
cat prefixes.ttl $1 > $TMP/rdf2rml-$$.ttl

# abort if the first pipeline step ("update") fails
# TODO: for some reason the pipeline after "update" hangs if there's an error
set -o pipefail

# Run jena SPARQL "update", dump as nquads, strip rr:graph name, prepend prefixes, convert to turtle, sort by "paragraph" (turtle subject block) keeping prefixes first
update$EXT --data=$TMP/rdf2rml-$$.ttl --update=$TMP/rdf2rml.ru --dump 2>$TMP/rdf2rml-$$.err | \
  perl -pe 'BEGIN {print qq{\@prefix rr: <http://www.w3.org/ns/r2rml#>.\n\n}}; s{ <http://www.w3.org/ns/r2rml#graph>}{}' | \
  cat prefixes.ttl - | \
  riot$EXT --syntax=turtle --formatted=turtle - | \
  perl -e 'print while ($_=<>) =~ m{^\s*(\@|$)}; $/=undef; $_ = $_.<>; print join "\n\n", sort split /\n\n/, $_'

# filter out harmless warnings from update's error log, eg "(some_date)"^^xsd:date
grep -vE 'Datatype format exception|Lexical form .* not valid for datatype' $TMP/rdf2rml-$$.err 1>&2

rm $TMP/rdf2rml-$$.ttl $TMP/rdf2rml-$$.err 
