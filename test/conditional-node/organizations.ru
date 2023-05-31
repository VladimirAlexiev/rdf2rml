base <https://example.org/>
prefix adms: <http://www.w3.org/ns/adms#>
prefix dct: <http://purl.org/dc/terms/>
prefix ebg: <http://data.businessgraph.io/ontology#>
prefix locn: <http://www.w3.org/ns/locn#>
prefix org: <http://www.w3.org/ns/org#>
prefix schema: <http://schema.org/>
prefix skos: <http://www.w3.org/2004/02/skos/core#>
delete {graph ?graph_cb_organizations_uuid_URL {?_s_ ?_p_ ?_o_}}
where {
  service <rdf-mapper:ontorefine:PROJECT_ID> {
    bind(?c_uuid as ?uuid)
    bind(?c_street as ?street)
    bind(?c_postal_code as ?postal_code)
    bind(?c_region as ?region)
    bind(?c_country_code as ?country_code)
    bind(?c_facebookUrl as ?facebookUrl)
    bind(?c_linkedinUrl as ?linkedinUrl)
    bind(iri(concat("graph/cb/organizations/",?uuid)) as ?graph_cb_organizations_uuid_URL)
    bind(iri(concat("cb/agent/",?uuid)) as ?cb_agent_uuid_URL)
    bind(if(bound(?country_code)||bound(?region)||bound(?postal_code)||bound(?street),"address",?UNDEF) as ?address_IF_BOUND)
    bind(iri(concat("cb/agent/",?uuid,"/",?address_IF_BOUND)) as ?cb_agent_uuid_address_IF_BOUND_URL)
    bind(if(bound(?facebookUrl),"facebook",?UNDEF) as ?facebook_IF_BOUND)
    bind(iri(concat("cb/agent/",?uuid,"/id/",?facebook_IF_BOUND)) as ?cb_agent_uuid_id_facebook_IF_BOUND_URL)
    bind(if(bound(?linkedinUrl),"linkedin",?UNDEF) as ?linkedin_IF_BOUND)
    bind(iri(concat("cb/agent/",?uuid,"/id/",?linkedin_IF_BOUND)) as ?cb_agent_uuid_id_linkedin_IF_BOUND_URL)
  }
  ?graph_cb_organizations_uuid_URL {?_s_ ?_p_ ?_o_}};
insert {graph ?graph_cb_organizations_uuid_URL {
  ?cb_agent_uuid_URL a org:Organization;
    org:hasSite ?cb_agent_uuid_address_IF_BOUND_URL;
    adms:identifier
      ?cb_agent_uuid_id_facebook_IF_BOUND_URL,
      ?cb_agent_uuid_id_linkedin_IF_BOUND_URL .
  ?cb_agent_uuid_address_IF_BOUND_URL a locn:Address;
    locn:fullAddress ?street;
    locn:postCode ?postal_code;
    locn:adminUnitL2 ?region;
    locn:adminUnitL1 ?country_code.
  ?cb_agent_uuid_id_facebook_IF_BOUND_URL a adms:Identifier;
    dct:isPartOf <identifier/Facebook>;
    skos:notation ?facebookUrl.
  ?cb_agent_uuid_id_linkedin_IF_BOUND_URL a adms:Identifier;
    dct:isPartOf <identifier/Linkedin>;
    skos:notation ?linkedinUrl.
  <identifier/Facebook> a ebg:IdentifierSystem;
    skos:notation "Facebook";
    schema:name "Facebook";
    schema:url <https://facebook.com>;
    ebg:urlTemplate "https://facebook.com/{}".
  <identifier/Linkedin> a ebg:IdentifierSystem;
    skos:notation "Linkedin";
    schema:name "Linkedin";
    schema:url <https://linkedin.com>;
    ebg:urlTemplate "https://linkedin.com/company/{}".
}}
where {
  service <rdf-mapper:ontorefine:PROJECT_ID> {
    bind(?c_uuid as ?uuid)
    bind(?c_street as ?street)
    bind(?c_postal_code as ?postal_code)
    bind(?c_region as ?region)
    bind(?c_country_code as ?country_code)
    bind(?c_facebookUrl as ?facebookUrl)
    bind(?c_linkedinUrl as ?linkedinUrl)
    bind(iri(concat("graph/cb/organizations/",?uuid)) as ?graph_cb_organizations_uuid_URL)
    bind(iri(concat("cb/agent/",?uuid)) as ?cb_agent_uuid_URL)
    bind(if(bound(?country_code)||bound(?region)||bound(?postal_code)||bound(?street),"address",?UNDEF) as ?address_IF_BOUND)
    bind(iri(concat("cb/agent/",?uuid,"/",?address_IF_BOUND)) as ?cb_agent_uuid_address_IF_BOUND_URL)
    bind(if(bound(?facebookUrl),"facebook",?UNDEF) as ?facebook_IF_BOUND)
    bind(iri(concat("cb/agent/",?uuid,"/id/",?facebook_IF_BOUND)) as ?cb_agent_uuid_id_facebook_IF_BOUND_URL)
    bind(if(bound(?linkedinUrl),"linkedin",?UNDEF) as ?linkedin_IF_BOUND)
    bind(iri(concat("cb/agent/",?uuid,"/id/",?linkedin_IF_BOUND)) as ?cb_agent_uuid_id_linkedin_IF_BOUND_URL)
  }
};
