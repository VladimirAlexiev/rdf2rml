base <https://graph.swissgrid.ch/>
prefix meta: <https://graph.swissgrid.ch/meta/>
prefix enum: <https://graph.swissgrid.ch/enum/>
prefix otl: <https://graph.swissgrid.ch/otl/>
prefix image: <https://aim.swissgrid.ch/images/>
prefix inventar: <https://graph.swissgrid.ch/profile/inventar/>
prefix cmdb: <https://graph.swissgrid.ch/profile/cmdb/>
prefix dms: <https://graph.swissgrid.ch/profile/dms/>
prefix eb: <https://graph.swissgrid.ch/profile/engineeringbase/>
prefix gis: <https://graph.swissgrid.ch/profile/gis/>
prefix plscadd: <https://graph.swissgrid.ch/profile/plscadd/>
prefix sales: <https://graph.swissgrid.ch/profile/salesforcegrid/>
prefix sappm: <https://graph.swissgrid.ch/profile/sappm/>
prefix bim: <https://graph.swissgrid.ch/profile/bim/>
prefix instandhaltung: <https://graph.swissgrid.ch/profile/instandhaltung/>
prefix apf: <http://jena.apache.org/ARQ/property#>
prefix cur: <https://qudt.org/vocab/currency/>
prefix dct: <http://purl.org/dc/terms/>
prefix fx: <http://sparql.xyz/facade-x/ns/>
prefix geo: <http://www.opengis.net/ont/geosparql#>
prefix owl: <http://www.w3.org/2002/07/owl#>
prefix pso: <http://purl.org/spar/pso#>
prefix puml: <http://plantuml.com/ontology#>
prefix qudt: <http://qudt.org/schema/qudt/>
prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
prefix rsx: <http://rdf4j.org/shacl-extensions#>
prefix schema: <http://schema.org/>
prefix sf: <http://www.opengis.net/ont/sf#>
prefix sh: <http://www.w3.org/ns/shacl#>
prefix skos: <http://www.w3.org/2004/02/skos/core#>
prefix sysont: <http://ns.ontowiki.net/SysOnt/>
prefix unit: <http://qudt.org/vocab/unit/>
prefix vs: <http://www.w3.org/2003/06/sw-vocab-status/ns#>
prefix xsd: <http://www.w3.org/2001/XMLSchema#>
prefix xyz: <http://sparql.xyz/facade-x/data/>
construct {
  ?profile_IRI_Mastersystem_SYS_PRIMARY_graph_URL {
    ?otl_Attribut_IRI_URL meta:systemPraeferenz <enum/systemPraeferenz/primaer>}
  ?profile_IRI_Mastersystem_SYS_SECONDARY_graph_URL {
    ?otl_Attribut_IRI_URL meta:systemPraeferenz <enum/systemPraeferenz/sekundaer>}
  ?profile_IRI_Zukuenftiges_Mastersystem_graph_URL {
    ?otl_Attribut_IRI_URL meta:systemPraeferenz <enum/systemPraeferenz/zukuenftigePrimaer>}
  ?profile_Attribut_System_Referenz_SPLIT_SEMI_SYSREFSYS_graph_URL {
    ?otl_Attribut_IRI_URL meta:systemReferenz ?Attribut_System_Referenz_SPLIT_SEMI_SYSREFID}
}
where {
  service <x-sparql-anything:> {
    fx:properties
      fx:location $_location ;
      fx:csv.headers "true" ;
      fx:csv.headers.sanitize "true" ;
      fx:csv.null-string "" ;
    .
    optional {?ROW xyz:IRI_Mastersystem ?IRI_Mastersystem}
    optional {?ROW xyz:Attribut_IRI ?Attribut_IRI}
    optional {?ROW xyz:IRI_Zukuenftiges_Mastersystem ?IRI_Zukuenftiges_Mastersystem}
    optional {?ROW xyz:Attribut_System_Referenz ?Attribut_System_Referenz}
    bind(if(?IRI_Mastersystem="engineeringbaseSap","engineeringbase",?IRI_Mastersystem) as ?IRI_Mastersystem_SYS_PRIMARY)
    bind(iri(concat("profile/",?IRI_Mastersystem_SYS_PRIMARY,"/graph")) as ?profile_IRI_Mastersystem_SYS_PRIMARY_graph_URL)
    bind(iri(concat("otl/",?Attribut_IRI)) as ?otl_Attribut_IRI_URL)
    bind(if(?IRI_Mastersystem="engineeringbaseSap","sappm",?UNDEF) as ?IRI_Mastersystem_SYS_SECONDARY)
    bind(iri(concat("profile/",?IRI_Mastersystem_SYS_SECONDARY,"/graph")) as ?profile_IRI_Mastersystem_SYS_SECONDARY_graph_URL)
    bind(iri(concat("profile/",?IRI_Zukuenftiges_Mastersystem,"/graph")) as ?profile_IRI_Zukuenftiges_Mastersystem_graph_URL)
    optional {?Attribut_System_Referenz_SPLIT_SEMI apf:strSplit (?Attribut_System_Referenz ";")}
    bind(replace(?Attribut_System_Referenz_SPLIT_SEMI,"(.+):.*","$1") as ?Attribut_System_Referenz_SPLIT_SEMI_SYSREFSYS)
    bind(iri(concat("profile/",?Attribut_System_Referenz_SPLIT_SEMI_SYSREFSYS,"/graph")) as ?profile_Attribut_System_Referenz_SPLIT_SEMI_SYSREFSYS_graph_URL)
    bind(if(regex(?Attribut_System_Referenz_SPLIT_SEMI,".+:(.+)"),replace(?Attribut_System_Referenz_SPLIT_SEMI,".+:(.+)","$1"),?UNDEF) as ?Attribut_System_Referenz_SPLIT_SEMI_SYSREFID)
  }
}
