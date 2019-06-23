package org.ezyaml.lang.tosca.common;

import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;

@Retention(RetentionPolicy.RUNTIME)
public @interface CatalogueResourceURI {
	String value();

}
