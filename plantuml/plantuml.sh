#! /bin/sh -e
GRAPHVIZ_DOT=`which dot`  
java -DPLANTUML_LIMIT_SIZE=8192 -jar /puml-doc/plantuml.jar "$@"