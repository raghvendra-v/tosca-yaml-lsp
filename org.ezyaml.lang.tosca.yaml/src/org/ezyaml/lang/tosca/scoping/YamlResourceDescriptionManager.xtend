package org.ezyaml.lang.tosca.scoping;

import java.util.Collection
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.IDefaultResourceDescriptionStrategy
import org.eclipse.xtext.resource.IResourceDescription
import org.eclipse.xtext.resource.IResourceDescription.Delta
import org.eclipse.xtext.resource.IResourceDescriptions
import org.eclipse.xtext.resource.impl.DefaultResourceDescription
import org.eclipse.xtext.resource.impl.DefaultResourceDescriptionManager
import org.eclipse.xtext.util.IResourceScopeCache
import org.ezyaml.lang.tosca.yaml.ToscaSimpleImport

class YamlResourceDescriptionManager extends DefaultResourceDescriptionManager {

	override isAffected(Collection<Delta> deltas, IResourceDescription candidate, IResourceDescriptions context) {
		val names = candidate.importedNames.toSet
		for (d : deltas) {
			if (names.contains(QualifiedName.create(d.uri.trimFileExtension.lastSegment)))
				return true
		}
		return false
	}

	override protected internalGetResourceDescription(Resource resource, IDefaultResourceDescriptionStrategy strategy) {
		return new YamlResourceDescription(resource, strategy, this.cache)
	}

	static class YamlResourceDescription extends DefaultResourceDescription {

		Iterable<QualifiedName> importedModules

		new(Resource resource, IDefaultResourceDescriptionStrategy strategy, IResourceScopeCache cache) {
			super(resource, strategy, cache)
			importedModules = computeImportedModules(resource)
		}

		private def computeImportedModules(Resource resource) {
			resource.allContents.filter(ToscaSimpleImport).map[QualifiedName.create(importURI)].toList
		}

		override getImportedNames() {
			importedModules
		}
	}
}
