library(redland)
library(rdflib)

doc <- system.file("extdata", "dc.rdf", package="redland")

query <-
 'PREFIX dc: <http://purl.org/dc/elements/1.1/>
  SELECT ?s ?p ?o
  WHERE { ?s ?p ?o . }'

rdf <- rdf_parse(doc)
#rdf_query(rdf, query)


queryObj <- new("Query", rdf$world, query)
queryResult <- redland::executeQuery(queryObj, rdf$model)

getResults <- function(queryResult, format = "csv", ...){
  mimetype <- switch(format,
                     "csv" = "text/csv; charset=utf-8",
                     NULL)
  readr::read_csv(redland:::librdf_query_results_to_string2(
    queryResult@librdf_query_results, 
    format, mimetype, NULL, NULL), 
    ...)
}

getResults(queryResult)



## YAY, x is XML


# redland:::librdf_query_results_get_bindings_count(.Object@librdf_query_results)

## Default method is XML-based, or requires we know the format URI
#x <- redland:::librdf_query_results_to_string(.Object@librdf_query_results, NULL, NULL)
#format_uri <- redland:::librdf_new_uri(rdf$world@librdf_world, "http://www.w3.org/2005/sparql-results#")
#x <- redland:::librdf_query_results_to_string(.Object@librdf_query_results, format_uri, NULL)

## redland *_string2 and *_file2 methods can use name and mime type in place of format uris