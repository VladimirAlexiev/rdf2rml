base <https://data.ontotext.com/crunchbase/>
prefix cb: <https://data.ontotext.com/crunchbase/ontology/>
prefix xsd: <http://www.w3.org/2001/XMLSchema#>

delete where {<cb> cb:updatedAt ?old};
insert {<cb> cb:updatedAt ?new}
where {select (max(?upd) as ?new) {[] cb:updatedAt ?upd}};
