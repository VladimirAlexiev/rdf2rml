#!/bin/bash

# Clean out all the .puml and .png
rm -rf /puml-doc/out/*

# Transform all the .ttl into .puml, ignore prefixes.ttl
for f in /puml-doc/ttl/*.ttl
do
    turtle_file=`basename $f`
    if [ "$turtle_file" != "prefixes.ttl" ]; then
       base=`basename $f .ttl`
       puml_file="/puml-doc/out/${base}.puml"
       echo "Transforming turtle [$f] to puml [${puml_file}]"
       /puml-doc/rdfpuml $f -outfile  ${puml_file} -plantumlcfgfile /puml-doc/plantuml-cfg/plantuml.cfg -prefixfile /puml-doc/ttl/prefixes.ttl
    fi
done

# Transform all the .puml to .png using plantuml
for f in /puml-doc/out/*.puml
do
    echo "Transforming puml [$f] to PNG"
    /puml-doc/plantuml.sh $f
done