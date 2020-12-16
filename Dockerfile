FROM ubuntu:20.10

LABEL MAINTANER Jem Rayfield "jem.rayfield@ontotext.com"

RUN apt-get update -y
RUN apt-get install -y software-properties-common
RUN apt-get install -y perl
RUN apt-get install -y automake
RUN apt-get install -y graphviz
RUN apt-get install -y curl
RUN apt-get install -y git
RUN apt-get install -y wget 

ENV DST_DIR=/puml-doc
ENV DST_DIR_OUT=/puml-doc/out

WORKDIR ${DST_DIR}

# CPAN
RUN apt-get install -y build-essential && \
    curl -L https://cpanmin.us | perl - App::cpanminus
COPY rdfpuml-docker/MyConfig.pm /root/.cpan/CPAN/MyConfig.pm 

# RDFPUML
RUN cd ${DST_DIR} && \
    cpanm RDF::Trine && \
    cpanm RDF::Query && \
    cpanm RDF::Prefixes && \
    cpanm Encode && \
    cpanm FindBin && \
    cpanm Carp::Always && \
    cpanm Slurp && \
    cpanm Getopt::Long && \
    cpanm Pod::Usage && \
    cpanm Path::Tiny    

COPY rdfpuml-docker/rdfpuml ${DST_DIR}/    
COPY bin/ ${DST_DIR}/rdf2rml/bin
COPY lib/ ${DST_DIR}/rdf2rml/lib
# JAVA
RUN apt-get install -y openjdk-8-jdk 

# MAVEN
RUN cd ${DST_DIR} && \
    wget https://www.mirrorservice.org/sites/ftp.apache.org/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz && \
    tar xvfz apache-maven-3.6.3-bin.tar.gz 

ENV M2_HOME="${DST_DIR}/apache-maven-3.6.3"
ENV PATH=$PATH:$M2_HOME/bin

# Plant UML
RUN cd ${DST_DIR} && \ 
    git clone https://github.com/plantuml/plantuml.git && \
    cd plantuml && \
    mvn -Djar.finalName=plantuml package 
   
COPY plantuml/plantuml.sh ${DST_DIR}/
ENV PATH=$PATH:${DST_DIR}/plantuml

COPY rdfpuml-docker/gen_puml.sh ${DST_DIR}/

COPY plantuml/plantuml.cfg ${DST_DIR}

ENTRYPOINT [ "/puml-doc/gen_puml.sh" ]
