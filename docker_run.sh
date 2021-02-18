#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker run \
           -it \
           -v ${DIR}/ttl:/puml-doc/ttl/ \
           -v ${DIR}/out:/puml-doc/out/ \
           -v ${DIR}/plantuml/plantuml.cfg:/puml-doc/plantuml-cfg/plantuml.cfg  \
           rdf-puml-gen:latest \
           /bin/bash
