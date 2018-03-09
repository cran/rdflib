## ----include = FALSE-----------------------------------------------------
knitr::opts_chunk$set(message=FALSE, warning = FALSE)

## ----libraries-----------------------------------------------------------
## Data 
library(nycflights13)
library(repurrrsive)

## for comparison approaches
library(tidyverse)
library(jsonlite)

## Our focal package:
library(rdflib)
## experimental functions for rdflib package
source(system.file("examples/as_rdf.R", package="rdflib"))
source(system.file("examples/tidy_schema.R", package="rdflib"))


## ----options, include = TRUE---------------------------------------------
#options(rdflib_storage = "BDB") 
options(rdflib_storage = "memory") 

# Use a smaller dataset if we do not have a BDB backend: 
if(getOption("rdflib_storage") != "BDB"){
  flights <- flights[1:1e3,]
}

## ----tidyverse-----------------------------------------------------------
df <- flights %>% 
  left_join(airlines) %>%
  left_join(planes, by="tailnum") %>% 
  select(carrier, name, manufacturer, model) %>% 
  distinct()
head(df)

## ----as_uri--------------------------------------------------------------
as_uri <- function(x, base_uri = "x:") paste0(base_uri, x)
uri_flights <- flights %>% 
  mutate(tailnum = as_uri(tailnum),
         carrier = as_uri(carrier))

## ----write_rdf-----------------------------------------------------------
system.time({
  
rdf <- rdf()

as_rdf(airlines, rdf = rdf, key = "carrier", vocab = "x:")
as_rdf(planes,  rdf = rdf, key = "tailnum", vocab = "x:")
as_rdf(uri_flights, rdf = rdf, key = NULL, vocab = "x:")

})

## ----query---------------------------------------------------------------
s <- 
  'SELECT  ?carrier ?name ?manufacturer ?model ?dep_delay
WHERE {
?flight <x:tailnum>  ?tailnum .
?flight <x:carrier>  ?carrier .
?flight <x:dep_delay>  ?dep_delay .
?tailnum <x:manufacturer> ?manufacturer .
?tailnum <x:model> ?model .
?carrier <x:name> ?name
}'

system.time(
df <- rdf_query(rdf, s)
)

head(df)

## ------------------------------------------------------------------------
f <- system.file("extdata/gh_repos.json", package="repurrrsive")
gh_data <- jsonlite::read_json(f)

## ------------------------------------------------------------------------
gh_flat <- gh_data %>% purrr::flatten()  # abandon nested structure and hope we didn't need it

gh_tibble <- tibble(
  name =     gh_flat %>% map_chr("name"),
  issues =   gh_flat %>% map_int("open_issues_count"),
  wiki =     gh_flat %>% map_lgl("has_wiki"),
  homepage = gh_flat %>% map_chr("homepage", .default = ""),
  owner =    gh_flat %>% map_chr(c("owner", "login"))
)

gh_tibble %>% arrange(name) %>% head()

## ----gh_add--------------------------------------------------------------
gh_rdf <- as_rdf.list(gh_data, rdf = rdf, vocab = "gh:")

## ----gh_query------------------------------------------------------------
s <- 
  'SELECT ?name ?issues ?wiki ?homepage ?owner
WHERE {
?repo <gh:homepage>  ?homepage .
?repo <gh:has_wiki> ?wiki .
?repo <gh:open_issues_count> ?issues .
?repo <gh:name> ?name .
?repo <gh:owner> ?owner_id .
?owner_id <gh:login>  ?owner 
}'

system.time(
rdf_tibble <- rdf_query(rdf, s)
)

head(rdf_tibble)

