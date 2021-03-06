/*
 * generated by Xtext 2.16.0
 */
package org.ezyaml.lang.tosca.ui

import com.google.inject.Binder
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.ezyaml.lang.tosca.ide.contentassist.antlr.lexer.InternalYamlLexer
import org.ezyaml.lang.tosca.ide.contentassist.antlr.lexer.jflex.JFlexBasedEOFAwareYamlLexer

/**
 * Use this class to register components to be used within the Eclipse IDE.
 */
@FinalFieldsConstructor
class YamlUiModule extends AbstractYamlUiModule {
	
	override configureideLexer(Binder binder) {
		binder.bind(InternalYamlLexer).to(JFlexBasedEOFAwareYamlLexer)
	}
	
}
