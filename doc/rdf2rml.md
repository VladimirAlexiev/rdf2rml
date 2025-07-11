---
title: rdf2rml - Convert RDF examples to R2RML scripts
author: Vladimir Alexiev, Ontotext Corp
date: 2023-06-02
---

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [SYNOPSIS](#synopsis)
- [DESCRIPTION](#description)
    - [RDF Model](#rdf-model)
    - [Example](#example)
        - [Generated R2RML](#generated-r2rml)
        - [Relational Data](#relational-data)
        - [Output RDF](#output-rdf)
    - [Prerequisites](#prerequisites)
    - [Internal Workings](#internal-workings)
        - [rdf2rml.ru](#rdf2rmlru)
        - [rdf2rml.sh](#rdf2rmlsh)
    - [Limitations](#limitations)
- [SEE ALSO](#see-also)

<!-- markdown-toc end -->

# SYNOPSIS

    rdf2rml.sh model.ttl > model.r2rml.ttl

# DESCRIPTION

**rdf2rml** converts an RDF example with embedded tables (or SQL queries) column names
into an R2RML script.
[R2RML](https://www.w3.org/TR/r2rml/) is the W3C standard for RDBMS->RDF conversion.
It is quite verbose and requires semantic experience to write.

**rdf2rml** generates R2RML transformations from examples,
which saves about 15x in complexity and
ensures compliance of the actual conversion to the model.

Typically the example is an **rdfpuml** model
that uses embedded column names rather than actual attribute values.

## RDF Model

The RDF model is a normal Turtle file with two additions.

1. `puml:label` is used to provide the SQL source for each node
   It can be one of the following:
   - A table name:
     Emitted as `rr:tableName`
   - A SQL query:
     `select * from` is optional and is prepended if missing.
     Emitted as `rr:sqlQuery`.
   - `ONCE`: replaced with `select 1 from dual`,
     which causes a single copy of the node to be generated
     (no iteration from its "parent" node).
     Use this for fixed data like `skos:ConceptScheme` info
   - Omitted:
     If `puml:label` is omitted, the node "inherits" the same query as its "parent" node.
     This works only if the node has a single incoming or outgoing relation.
     Inlined nodes and nodes with no properties don't use this inheritance mechanism.
2. Parenthesized **column names** are used in literals and URLs
   to indicate where to substitute SQL data.
   Parentheses are converted to curly brackets in the R2RML putput
   to conform with the requirements of `rr:template`.

That's all we need to be able to generate R2RML!

## Example

Consider the following example:

    <exhibition/(exhibitionid)>
      puml:label """
        exhibitions left join conxrefs 
         on id=exhibitionid
         where tableid=47
          and roleid=286  
          and exhdepartment in (53,54)
        """;
      a crm:E7_Activity;
      crm:P2_has_type aat:300054766; # exhibition
      crm:P14_carried_out_by <agent/(constituentid)>;
      crm:P1_is_identified_by <exhibition/(exhibitionid)/title>;
      crm:P4_has_time-span <exhibition/(exhibitionid)/date>.

    <exhibition/(exhibitionid)/title> a crm:E41_Appellation;
      crm:P3_has_note "(exhtitle)".

    <exhibition/(exhibitionid)/date> a crm:E52_Time-Span;
      crm:P3_has_note "(displaydate)";
      crm:P82a_begin_of_the_begin "(beginisodate)"^^xsd:date;
      crm:P82b_end_of_the_end "(endisodate)"^^xsd:date.

This creates 3 connected nodes.
All of them use the same query, inherited from the top node.
The column `(exhibitionid)` is used in the URLs of all these nodes,
to ensure that correlated (linked) nodes are created for each row in the resultset.

Constant values like `a crm:E7_Activity` and `crm:P2_has_type aat:300054766` are emitted as is.
Variables like `(displaydate)` are substituted.
As a hybrid example, `(endisodate)` uses a variable value but constant datatype `xsd:date`.

Now let's see the full example `test/exhibitions/exhibitions.ttl`:

![](../test/exhibitions/exhibitions-colored.png)

### Generated R2RML

The generated R2RML script is `test/exhibitions/exhibitions.r2rml.ttl`.
The single node circled in red on the diagram above (and its 3 outgoing connections)
generates the following R2RML nodes: a saving of about 15x complexity!

![](../test/exhibitions/exhibitions.r2rml-colored.png)

### Relational Data

Now let's assume that we have the following relational data about Exhibitions (`test/exhibitions/exhibitions.sql`):

- `conaddress` (constitutent addresses)

| conaddressid | constituentid | address        |
|--------------|---------------|----------------|
|          101 |             1 | 'Getty Drive'  |
|          102 |             2 | 'MoMA Street'  |
|          103 |             3 | 'LACMA County' |

- `conxrefs` (constitutent cross-references)

| tableid | roleid |  id | constituentid |
|---------|--------|-----|---------------|
|      47 |    286 | 123 |             1 |

- `constituents` (constituents, in this case museums)

| constituentid | constituent    |
|---------------|----------------|
|             1 | 'Getty Museum' |
|             2 | 'MoMA'         |
|             3 | 'LACMA'        |

- `exhibitions` (exhibitions)

| exhibitionid | exhdepartment | exhtitle                 | displaydate    | beginisodate | endisodate   |
|--------------|---------------|--------------------------|----------------|--------------|--------------|
|          123 |            53 | 'Getty through the ages' | 'October 2016' | '2016-10-01' | '2016-10-30' |

- `exhvenuesxrefs` (exhibitions at venues)

| exhvenxref | exhid | conid | conaddrid | approved | dispord | displaydate      | beginisodate | endisodate   |
|------------|-------|-------|-----------|----------|---------|------------------|--------------|--------------|
|        202 |   123 |     2 |       102 |        1 |       1 | 'Early Oct 2016' | '2016-10-01' | '2016-10-15' |
|        203 |   123 |     3 |       103 |        1 |       2 | 'Late Oct 2016'  | '2016-10-16' | '2016-10-30' |

- `exhvenobjxrefs` (objects exibited at particular venue as part of an exhibition)

| exhvenuexrefid | objectid | catalognumber | begindispldateiso | enddispldateiso | displayed |
|----------------|----------|---------------|-------------------|-----------------|-----------|
|            202 |     1001 | 'cat 1001'    | '2016-10-01'      | '2016-10-15'    |         1 |
|            203 |     1001 | 'cat 1001'    | '2016-10-16'      | '2016-10-30'    |         1 |
|            202 |     1002 | 'cat 1002'    | '2016-10-01'      | '2016-10-15'    |         1 |

### Output RDF

If we apply the generated R2RML script on the relational data, we get this output: `test/exhibitions/exhibitions-out.ttl`.

As you can see, it has the same structure as the example `test/exhibitions/exhibitions.ttl` but more nodes:

![](../test/exhibitions/exhibitions-out-colored.png)

## Prerequisites

- [Apache Jena](https://jena.apache.org/download/): `riot, update`. Tested with version 3.1.0 of 2016-05-10.
- Perl. Tested with version 5.22
- `cat, grep, rm`

## Internal Workings

This tool consists of two scripts.

### rdf2rml.ru

`rdf2rml.ru` is a SPARQL UPDATE script that transforms the model to R2RML.

It uses `rr:graph` for all output, so it can be separated from the input.

It makes deterministic R2RML URLs by taking the source URLs and using this convention:

    <{s}!map>     for rr:TriplesMap
    <{s}!subj>    for rr:SubjectMap
    <{s}!{p}!{o}> for rr:PredicateObjectMap

Here `{s}` is the full subject URL, but `{p} {o}` are stripped to their local names.

The SPARQL UPDATE has the following steps:

1. Propagates inherited queries from parent to child nodes (repeated several times to ensure propagation from child to grandchild).
2. Emits `rr:logicalTable` for each subject node, using `rr:tableName` or `rr:sqlQuery`.
3. Emits constant subjects (those that have no parentheses in the URL) using `rr:constant`
4. Creates variable subjects (those that have a parenthesis in the URL) replacing parentheses with curly brackets, and using `rr:template`.
5. Creates constant `rr:class` for each subject that has one.
6. Creates `rr:predicateObjectMap` for each pair subject-object
7. Emits constant objects (those that have no parentheses in URL or literal) using `rr:object`
8. Creates variable objects (those that have a parenthesis in the URL or literal) replacing parentheses with curly brackets, and using `rr:objectMap` and `rr:template`.
9. Ensures that appropriate `rr:termType, rr:datatype, rr:language` are emitted for each object.
10. Removes source data by using `clear default`, to preserve only the output graph `rr:graph`

### rdf2rml.sh

`rdf2rml.sh` is a simple shell script that
takes file `prefixes.ttl` in the current folder,
prepends it to the model file,
converts it to SPARQL form, and prepends it to the SPARQL script.
Then it runs the SPARQL script,
converts the output to turtle,
removes prefixes,
and sorts the output by subject.

See `test/*/Makefile` for examples how to set up make.

## Limitations

`rdf2rml.sh` hard-codes the TMP directory and the location of Apache Jena

It also unconditionally looks for a file `prefixes.ttl` in the current folder
that it prepends to the model file and the SPARQL script.

Use parentheses to designate column names in literals and URLs, instead of curly brackets as the R2RML standard (`rr:template`) uses.
This makes the URLs valid, so the RDF can be validated and diagrammed.

Parentheses in literals are shown as brackets on generated diagrams, due to a limitation of rdfpuml.

Resource classes, literal datatypes and languages are limited to constant values:
you cannot specify they should come from a SQL column.

You may get a Jena RIOT warning for literals with numeric or date/time datatype,
because a parenthesized string is not a valid lexical form for such literals.
But the conversion will work fine despite of the warning.

# SEE ALSO

- The [Stardog Mapping Syntax](https://www.stardog.com/docs/#_stardog_mapping_syntax)
  uses a similar idea, but doesn't use valid RDF to represent the model.
  The benefit of using actual RDF is that it can be validated and diagrammed with **rdfpuml**.
- **rdf2rml** and **rdf2sparql**: a tool to generate R2RML and SPARQL transformations from RDF examples.
- If you use these tools, please cite them as follows. See these presentations for numerous examples.
  - RDF by Example: rdfpuml for True RDF Diagrams, rdf2rml for R2RML Generation
    Alexiev, V. In Semantic Web in Libraries 2016 (SWIB 16), Bonn, Germany, November 2016.
    [Presentation](https://github.io/VladimirAlexiev/my/pres/20161128-rdfpuml-rdf2rml/index.html), [HTML](https://github.io/VladimirAlexiev/my/pres/20161128-rdfpuml-rdf2rml/index-full.html), [PDF](https://github.io/VladimirAlexiev/my/pres/20161128-rdfpuml-rdf2rml/RDF_by_Example.pdf), [Video](https://youtu.be/4WoYlaGF6DE)
  - Generation of Declarative Transformations from Semantic Models. 
    Alexiev, V. In European Data Conference on Reference Data and Semantics (ENDORSE 2023), pages 33, 42-59, March 2023. 
    European Commission: Directorate-General for Informatics, Publications Office of the European Union.
    [Paper](https://drive.google.com/open?id=1Cq5o9th_P812paqGkDsaEomJyAmnypkD), [ppt](https://docs.google.com/presentation/d/1JCMQEH8Tw_F-ta6haIToXMLYJxQ9LRv6/edit), [video](https://youtu.be/yL5nI_3ccxs), [proceedings](https://op.europa.eu/en/publication-detail/-/publication/4db67b35-34df-11ee-bdc3-01aa75ed71a1), [doi](http://doi.org/10.2830/343811)
