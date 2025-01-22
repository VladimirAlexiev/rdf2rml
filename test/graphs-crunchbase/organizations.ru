base <https://data.ontotext.com/crunchbase/>
prefix cb: <https://data.ontotext.com/crunchbase/ontology/>
prefix puml: <http://plantuml.com/ontology#>
prefix spif: <http://spinrdf.org/spif#>
prefix skos: <http://www.w3.org/2004/02/skos/core#>
prefix xsd: <http://www.w3.org/2001/XMLSchema#>
delete {graph ?graph_organizations_uuid_URL {?_s_ ?_p_ ?_o_}}
where {
  {select * { service <rdf-mapper:ontorefine:PROJECT_ID> {
    bind(?c_uuid as ?uuid)
    bind(iri(concat("graph/organizations/",?uuid)) as ?graph_organizations_uuid_URL)
    bind(?c_updated_at as ?updated_at)
  }}}
  <cb> cb:updatedAt ?UPDATED_AT_DT bind(replace(str(?UPDATED_AT_DT),'T',' ') as ?UPDATED_AT) filter(?updated_at > ?UPDATED_AT)
  graph ?graph_organizations_uuid_URL {?_s_ ?_p_ ?_o_}};
insert {graph ?graph_organizations_uuid_URL {
  ?cb_agent_uuid_URL a cb:Organization;
    cb:cbId ?uuid;
    cb:name ?name;
    cb:cbPermalink ?permalink;
    cb:cbUrl ?cb_url_xsd_anyURI;
    cb:rank ?rank_xsd_integer;
    cb:createdAt ?created_at_FIXDATE_xsd_dateTime;
    cb:updatedAt ?updated_at_FIXDATE_xsd_dateTime;
    cb:legalName ?legal_name;
    cb:organizationRole ?cb_organizationRole_roles_SPLIT1_URLIFY_URL;
    cb:domain ?domain;
    cb:homepageUrl ?homepage_url_xsd_anyURI;
    cb:countryCode ?country_code;
    cb:stateCode ?state_code;
    cb:region ?region;
    cb:city ?city;
    cb:address ?address;
    cb:postalCode ?postal_code;
    cb:status ?cb_organizationStatus_status_URLIFY_URL;
    cb:shortDescription ?short_description;
    cb:industry ?cb_industry_category_list_SPLIT1_URLIFY_URL;
    cb:numFundingRounds ?num_funding_rounds_xsd_integer;
    cb:totalFundingUsd ?total_funding_usd_xsd_decimal;
    cb:totalFunding ?total_funding_xsd_decimal;
    cb:totalFundingCurrencyCode ?total_funding_currency_code;
    cb:foundedOn ?founded_on_xsd_date;
    cb:lastFundingOn ?last_funding_on_xsd_date;
    cb:closedOn ?closed_on_xsd_date;
    cb:employeeCount ?cb_employeeCount_employee_count_IFNOTNULL_URLIFY_URL;
    cb:email ?email;
    cb:phone ?phone;
    cb:facebookUrl ?facebook_url_xsd_anyURI;
    cb:linkedinUrl ?linkedin_url_xsd_anyURI;
    cb:twitterUrl ?twitter_url_xsd_anyURI;
    cb:logoUrl ?logo_url_xsd_anyURI;
    cb:alias ?alias1;
    cb:alias ?alias2;
    cb:alias ?alias3;
    cb:primaryRole ?cb_organizationRole_primary_role_URLIFY_URL;
    cb:numExits ?num_exits_xsd_integer.
}}
where {
  {select * { service <rdf-mapper:ontorefine:PROJECT_ID> {
    bind(?c_uuid as ?uuid)
    bind(iri(concat("graph/organizations/",?uuid)) as ?graph_organizations_uuid_URL)
    bind(?c_updated_at as ?updated_at)
    bind(?c_name as ?name)
    bind(?c_permalink as ?permalink)
    bind(?c_cb_url as ?cb_url)
    bind(?c_rank as ?rank)
    bind(?c_created_at as ?created_at)
    bind(?c_legal_name as ?legal_name)
    bind(?c_roles as ?roles)
    bind(?c_domain as ?domain)
    bind(?c_homepage_url as ?homepage_url)
    bind(?c_country_code as ?country_code)
    bind(?c_state_code as ?state_code)
    bind(?c_region as ?region)
    bind(?c_city as ?city)
    bind(?c_address as ?address)
    bind(?c_postal_code as ?postal_code)
    bind(?c_status as ?status)
    bind(?c_short_description as ?short_description)
    bind(?c_category_list as ?category_list)
    bind(?c_num_funding_rounds as ?num_funding_rounds)
    bind(?c_total_funding_usd as ?total_funding_usd)
    bind(?c_total_funding as ?total_funding)
    bind(?c_total_funding_currency_code as ?total_funding_currency_code)
    bind(?c_founded_on as ?founded_on)
    bind(?c_last_funding_on as ?last_funding_on)
    bind(?c_closed_on as ?closed_on)
    bind(?c_employee_count as ?employee_count)
    bind(?c_email as ?email)
    bind(?c_phone as ?phone)
    bind(?c_facebook_url as ?facebook_url)
    bind(?c_linkedin_url as ?linkedin_url)
    bind(?c_twitter_url as ?twitter_url)
    bind(?c_logo_url as ?logo_url)
    bind(?c_alias1 as ?alias1)
    bind(?c_alias2 as ?alias2)
    bind(?c_alias3 as ?alias3)
    bind(?c_primary_role as ?primary_role)
    bind(?c_num_exits as ?num_exits)
    bind(iri(concat("cb/agent/",?uuid)) as ?cb_agent_uuid_URL)
    bind(strdt(?cb_url,xsd:anyURI) as ?cb_url_xsd_anyURI)
    bind(strdt(?rank,xsd:integer) as ?rank_xsd_integer)
    bind(REPLACE(?created_at,' ','T') as ?created_at_FIXDATE)
    bind(strdt(?created_at_FIXDATE,xsd:dateTime) as ?created_at_FIXDATE_xsd_dateTime)
    bind(REPLACE(?updated_at,' ','T') as ?updated_at_FIXDATE)
    bind(strdt(?updated_at_FIXDATE,xsd:dateTime) as ?updated_at_FIXDATE_xsd_dateTime)
    ?roles_SPLIT1 spif:split (?roles ',').
    bind(LCASE(REPLACE(REPLACE(REPLACE(?roles_SPLIT1, "[^\\p{L}0-9]", "_"), "_+", "_"), "^_|_$", "")) as ?roles_SPLIT1_URLIFY)
    bind(iri(concat("cb/organizationRole/",?roles_SPLIT1_URLIFY)) as ?cb_organizationRole_roles_SPLIT1_URLIFY_URL)
    bind(strdt(?homepage_url,xsd:anyURI) as ?homepage_url_xsd_anyURI)
    bind(LCASE(REPLACE(REPLACE(REPLACE(?status, "[^\\p{L}0-9]", "_"), "_+", "_"), "^_|_$", "")) as ?status_URLIFY)
    bind(iri(concat("cb/organizationStatus/",?status_URLIFY)) as ?cb_organizationStatus_status_URLIFY_URL)
    ?category_list_SPLIT1 spif:split (?category_list ',').
    bind(LCASE(REPLACE(REPLACE(REPLACE(?category_list_SPLIT1, "[^\\p{L}0-9]", "_"), "_+", "_"), "^_|_$", "")) as ?category_list_SPLIT1_URLIFY)
    bind(iri(concat("cb/industry/",?category_list_SPLIT1_URLIFY)) as ?cb_industry_category_list_SPLIT1_URLIFY_URL)
    bind(strdt(?num_funding_rounds,xsd:integer) as ?num_funding_rounds_xsd_integer)
    bind(strdt(?total_funding_usd,xsd:decimal) as ?total_funding_usd_xsd_decimal)
    bind(strdt(?total_funding,xsd:decimal) as ?total_funding_xsd_decimal)
    bind(strdt(?founded_on,xsd:date) as ?founded_on_xsd_date)
    bind(strdt(?last_funding_on,xsd:date) as ?last_funding_on_xsd_date)
    bind(strdt(?closed_on,xsd:date) as ?closed_on_xsd_date)
    bind(if(?employee_count in ("other","not provided","unknown"),?UNDEF,?employee_count) as ?employee_count_IFNOTNULL)
    bind(LCASE(REPLACE(REPLACE(REPLACE(?employee_count_IFNOTNULL, "[^\\p{L}0-9]", "_"), "_+", "_"), "^_|_$", "")) as ?employee_count_IFNOTNULL_URLIFY)
    bind(iri(concat("cb/employeeCount/",?employee_count_IFNOTNULL_URLIFY)) as ?cb_employeeCount_employee_count_IFNOTNULL_URLIFY_URL)
    bind(strdt(?facebook_url,xsd:anyURI) as ?facebook_url_xsd_anyURI)
    bind(strdt(?linkedin_url,xsd:anyURI) as ?linkedin_url_xsd_anyURI)
    bind(strdt(?twitter_url,xsd:anyURI) as ?twitter_url_xsd_anyURI)
    bind(strdt(?logo_url,xsd:anyURI) as ?logo_url_xsd_anyURI)
    bind(LCASE(REPLACE(REPLACE(REPLACE(?primary_role, "[^\\p{L}0-9]", "_"), "_+", "_"), "^_|_$", "")) as ?primary_role_URLIFY)
    bind(iri(concat("cb/organizationRole/",?primary_role_URLIFY)) as ?cb_organizationRole_primary_role_URLIFY_URL)
    bind(strdt(?num_exits,xsd:integer) as ?num_exits_xsd_integer)
  }}}
  <cb> cb:updatedAt ?UPDATED_AT_DT bind(replace(str(?UPDATED_AT_DT),'T',' ') as ?UPDATED_AT) filter(?updated_at > ?UPDATED_AT)};
