base <https://data.ontotext.com/crunchbase/>
prefix cb: <https://data.ontotext.com/crunchbase/ontology/>
prefix xsd: <http://www.w3.org/2001/XMLSchema#>

delete where {
    <cb> cb:updatedAt ?old
};
insert data {
    <cb> cb:updatedAt '0001-01-01T00:00:00'^^xsd:dateTime
};