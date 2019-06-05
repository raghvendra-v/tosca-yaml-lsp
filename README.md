![Travis CI ](https://travis-ci.com/raghvendra-v/tosca-yaml-lsp.svg?branch=master)  
    
 
      
# TOSCA YAML LSP
TOSCA DSL grammer using the xtext framework

This project bridges the gap between meta-model derived from TOSCA catalogue and 
Java Object-Graph model.
It features 
 + [Xtext](https://github.com/eclipse/xtext "Eclipse Xtext™") based grammer to parse generic YAML
 + Xtext's native JvmModel translator to generate Java POJOs corresponding to the type definitions in the catalogue
 + [theia](https://github.com/theia-ide "theia-ide")  based cloud editor for tosca catalogue
 + Eclipse plugin to edit YAMLs

Further improvements in pipeline
 + OpenAPI decorators in the generated POJO's to help exposure using spring-boot APIs
 + OGM annotations in the generated POJO's for mapping to a graph DB ( neo4j ) , support for spring-boot REST repository
 
Issues in yaml parsing
 + Best to have a blank newline at the end of file, although it should work most of the time
 + Multi-documents (--- and ... markers);
 + Complex mapping keys and complex values starting with ?;
 + Tagged values as keys;
 + The following tags and types: !!set, !!omap, !!pairs, !!set, !!seq, !!bool, !!int, !!merge, !!null, !!timestamp, !!value, !!yaml;
 + TAG directives

## build process ## 
`maven clean install`  
[Bulk parsing Test](org.ezyaml.lang.tosca.yaml.tests/src/org/ezyaml/lang/tosca/tests/BulkYamlParserTest.xtend) runs regression against all the yaml descriptors available in [Open Source MANO GIT](https://osm.etsi.org/gitweb/?p=osm/devops.git;a=summary "OSM MANO") 