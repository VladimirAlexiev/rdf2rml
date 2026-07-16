base <https://example.org/>
prefix fx: <http://sparql.xyz/facade-x/ns/>
prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
prefix skos: <http://www.w3.org/2004/02/skos/core#>
prefix xyz: <http://sparql.xyz/facade-x/data/>
construct {
graph ?enum_Attribut_IRI_graph_URL {
  ?enum_Attribut_IRI_URL a skos:ConceptScheme;
    skos:prefLabel ?Attribut_IRI_enum_lang_de;
    rdfs:label ?Attribut_IRI_enum_lang_de.
  ?enum_Attribut_IRI_Enumeration_DE_URLIFY_URL a skos:Concept;
    skos:inScheme ?enum_Attribut_IRI_URL; skos:topConceptOf ?enum_Attribut_IRI_URL;
    skos:prefLabel ?Enumeration_DE_lang_de, ?Enumeration_FR_lang_fr, ?Enumeration_IT_lang_it.
}}
where {
  service <x-sparql-anything:> {
    fx:properties
      fx:location $_location ;
      fx:csv.headers "true" ;
      fx:csv.headers.sanitize "true" ;
      fx:csv.null-string "" ;
    .
    optional {?ROW xyz:Attribut_IRI ?Attribut_IRI}
    optional {?ROW xyz:Enumeration_DE ?Enumeration_DE}
    optional {?ROW xyz:Enumeration_FR ?Enumeration_FR}
    optional {?ROW xyz:Enumeration_IT ?Enumeration_IT}
    bind(iri(concat("enum/",?Attribut_IRI,"/graph")) as ?enum_Attribut_IRI_graph_URL)
    bind(iri(concat("enum/",?Attribut_IRI)) as ?enum_Attribut_IRI_URL)
    bind(concat(?Attribut_IRI," enum") as ?Attribut_IRI_enum)
    bind(strlang(?Attribut_IRI_enum,"de") as ?Attribut_IRI_enum_lang_de)
    bind(replace(replace(replace(replace(?Enumeration_DE,"[^\\p{L}0-9]+",""),"ä","ae"),"ü","ue"),"ö","oe") as ?Enumeration_DE_URLIFY)
    bind(iri(concat("enum/",?Attribut_IRI,"/",?Enumeration_DE_URLIFY)) as ?enum_Attribut_IRI_Enumeration_DE_URLIFY_URL)
    bind(strlang(?Enumeration_DE,"de") as ?Enumeration_DE_lang_de)
    bind(strlang(?Enumeration_FR,"fr") as ?Enumeration_FR_lang_fr)
    bind(strlang(?Enumeration_IT,"it") as ?Enumeration_IT_lang_it)
  }
}
