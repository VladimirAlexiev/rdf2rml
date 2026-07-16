# Using rdf2sparql with SparqlAnything

Documented at [rdf2sparql#sparql-anything](../../doc/rdf2sparql.md#sparql-anything).
Files:
- `Makefile`: run `make`
- `common.h`: some macros
- `enum.csv`: input file. Some cells are empty and should not appear as triples
- `model-enum.ttl, model-enum.fx`: model, and generated SparqlAnything transform.
- `enum.ttl`: output as Turtle.
- `model-enum-with-graph.ttl, model-enum-with-graph.fx`: model with graph, and generated SparqlAnything transform.
- `enum-with-graph.nq`: output as NQuads.
  Note that because of [sparql.anything#642](https://github.com/SPARQL-Anything/sparql.anything/issues/642) you can't use Trig right now.
- `prefixes.rq, prefixes.ttl`: common prefixes.
