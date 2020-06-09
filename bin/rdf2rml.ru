prefix rr: <http://www.w3.org/ns/r2rml#>

# SPARQL UPDATE script to convert RDF with embedded SQL & source fields to R2RML

### If a node ?y has no SQL, is not Inlined, has some props, and a single incoming edge, then add its parent's SQL as default
insert {
  ?y puml:label ?sql
}
where {
  ?x ?p ?y; puml:label ?sql
  filter not exists {?p a puml:InlineProperty}
  filter not exists {?y a puml:Inline}
  filter not exists {?y puml:label ?sql2}
  filter exists {?y ?p1 ?z}
  filter not exists {?x1 ?p1 ?y filter(?x1!=?x)}
};

### REPEAT two more times in case there are longer chains
insert {
  ?y puml:label ?sql
}
where {
  ?x ?p ?y; puml:label ?sql
  filter not exists {?p a puml:InlineProperty}
  filter not exists {?y a puml:Inline}
  filter not exists {?y puml:label ?sql2}
  filter exists {?y ?p1 ?z}
  filter not exists {?x1 ?p1 ?y filter(?x1!=?x)}
};
insert {
  ?y puml:label ?sql
}
where {
  ?x ?p ?y; puml:label ?sql
  filter not exists {?p a puml:InlineProperty}
  filter not exists {?y a puml:Inline}
  filter not exists {?y puml:label ?sql2}
  filter exists {?y ?p1 ?z}
  filter not exists {?x1 ?p1 ?y filter(?x1!=?x)}
};

### If a node ?y has no SQL, is not Inlined, has a single outgoing edge, then add its parent'counterparty's SQL as default
insert {
  ?y puml:label ?sql
}
where {
  ?y ?p ?x. ?x puml:label ?sql
  filter not exists {?p a puml:InlineProperty}
  filter not exists {?y a puml:Inline}
  filter not exists {?y puml:label ?sql2}
  filter not exists {?y ?p1 ?x1 filter(?x1!=?x)}
};

### create rr:logicalTable
insert { graph rr:graph {
  ?map a rr:TriplesMap;
    rr:logicalTable [
      rr:tableName ?table; # either
      rr:sqlQuery ?sql1    # or
    ]
}}
where {
  ?s puml:label ?sql
  bind(uri(concat(str(?s),"!map")) as ?map)
  values ?undef {undef}
  # assign ?sql to ?table only if "[[catalog.]schema.]table"
  bind(if(regex(?sql,'^"?[\\w.]+"?$') && ?sql!="ONCE",?sql,?undef) as ?table)
  # prepend "select * from" to ?sql1 if missing in ?sql
  bind(if(?sql="ONCE","select 1 from dual",
       if(regex(?sql,'^"?[\\w.]+"?$'),?undef,
       if(regex(?sql,"select ","i"),?sql,
       concat("select * from ",?sql)))) as ?sql1)
};

### create constant subject
insert { graph rr:graph {
  ?map rr:subjectMap ?subj.
  ?subj a rr:SubjectMap; rr:constant ?s
}}
where {
  ?s puml:label ?sql
  filter(!regex(str(?s),"\\("))
  bind(uri(concat(str(?s),"!map")) as ?map)
  bind(uri(concat(str(?s),"!subj")) as ?subj)
};

### create variable subject
insert { graph rr:graph {
  ?map rr:subjectMap ?subj.
  ?subj a rr:SubjectMap; rr:template ?s1
}}
where {
  ?s puml:label ?sql
  filter(regex(str(?s),"\\("))
  bind(uri(concat(str(?s),"!map")) as ?map)
  bind(uri(concat(str(?s),"!subj")) as ?subj)
  bind(replace(replace(str(?s),"\\(","{"),"\\)","}") as ?s1)
};

### create rr:class
insert { graph rr:graph {
  ?subj rr:class ?class.
}}
where {
  ?s puml:label ?sql; a ?class
  bind(uri(concat(str(?s),"!subj")) as ?subj)
};

### create rr:predicateObjectMap
insert { graph rr:graph {
  ?map rr:predicateObjectMap ?pmap.
  ?pmap a rr:PredicateObjectMap;
    rr:predicate ?p.
}}
where {
  ?s ?p ?o
  filter exists {?s puml:label ?sql}
  filter(?p != rdf:type)
  filter(!strstarts(str(?p),str(puml:)))
  bind(uri(concat(str(?s),"!map")) as ?map)
  bind(replace(str(?p),".*[#/]","") as ?p1) # cut out namespace
  bind(replace(str(?o),".*[#/]","") as ?o1) # cut out namespace
  bind(replace(?o1,"[^a-zA-Z0-9()!.]+","_") as ?o2) # replace non-URL symbols in literal
  bind(uri(concat(str(?s),"!",?p1,"!",?o2)) as ?pmap)
};

### create constant rr:object
insert { graph rr:graph {
  ?pmap rr:object ?o
}}
where {
  ?s ?p ?o
  filter exists {?s puml:label ?sql}
  filter(?p != rdf:type)
  filter(!strstarts(str(?p),str(puml:)))
  filter(!regex(str(?o),"\\("))
  bind(replace(str(?p),".*[#/]","") as ?p1) # cut out namespace
  bind(replace(str(?o),".*[#/]","") as ?o1) # cut out namespace
  bind(replace(?o1,"[^a-zA-Z0-9()!.]+","_") as ?o2) # replace non-URL symbols in literal
  bind(uri(concat(str(?s),"!",?p1,"!",?o2)) as ?pmap)
};

### create rr:objectMap for variable objects
insert { graph rr:graph {
  ?pmap rr:objectMap [
    a rr:ObjectMap;
    rr:template ?o3;
    rr:termType ?type;
    rr:datatype ?dt1;
    rr:language ?lang1
  ]
}}
where {
  ?s ?p ?o
  filter exists {?s puml:label ?sql}
  filter(?p != rdf:type)
  filter(!strstarts(str(?p),str(puml:)))
  filter(regex(str(?o),"\\("))
  bind(replace(str(?p),".*[#/]","") as ?p1) # cut out namespace
  bind(replace(str(?o),".*[#/]","") as ?o1) # cut out namespace
  bind(replace(?o1,"[^a-zA-Z0-9()!.]+","_") as ?o2) # replace non-URL symbols in literal
  bind(uri(concat(str(?s),"!",?p1,"!",?o2)) as ?pmap)
  bind(replace(replace(str(?o),"\\(","{"),"\\)","}") as ?o3)
  bind(if(isIRI(?o),rr:IRI,
       if(isBlank(?o),rr:BlankNode,
       rr:Literal)) as ?type)
  bind(datatype(?o) as ?dt)
  bind(lang(?o) as ?lang)
  values ?undef {undef}
  bind(if(?dt=xsd:string,?undef,?dt) as ?dt1)
  bind(if(?lang="",?undef,?lang) as ?lang1)
};

### remove source data, which is in the default graph
clear default;

# output the result graph
# construct {?s ?p ?o} where {graph rr:graph {?s ?p ?o}}
