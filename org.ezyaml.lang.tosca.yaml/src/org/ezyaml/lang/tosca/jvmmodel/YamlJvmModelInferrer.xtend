/*
 * generated by Xtext 2.18.0
 */
package org.ezyaml.lang.tosca.jvmmodel

import com.google.inject.Inject
import io.swagger.annotations.ApiModel
import io.swagger.annotations.ApiModelProperty
import org.eclipse.xtext.common.types.JvmDeclaredType
import org.eclipse.xtext.common.types.JvmTypeReference
import org.eclipse.xtext.xbase.jvmmodel.AbstractModelInferrer
import org.eclipse.xtext.xbase.jvmmodel.IJvmDeclaredTypeAcceptor
import org.eclipse.xtext.xbase.jvmmodel.JvmTypesBuilder
import org.ezyaml.lang.tosca.yaml.Scalar
import org.ezyaml.lang.tosca.yaml.ToscaSuperTypeDeclaration
import org.ezyaml.lang.tosca.yaml.ToscaType
import org.ezyaml.lang.tosca.yaml.ToscaTypeMembers
import org.ezyaml.lang.tosca.yaml.YamlMappingEntry
import org.ezyaml.lang.tosca.yaml.YamlRHS
import com.google.common.base.Function
import java.util.List

/**
 * <p>Infers a JVM model from the source model.</p> 
 * 
 * <p>The JVM model should contain all elements that would appear in the Java code 
 * which is generated from the source model. Other models link against the JVM model rather than the source model.</p>     
 */
class YamlJvmModelInferrer extends AbstractModelInferrer {

	static val baseClassMap = (#["Integer", "String", "Boolean", "Long", "Float"].map["java.lang.".concat(it)] +
		#["Map", "List"].map["java.util.".concat(it)]).toMap([it], [
		Class.forName(it)
	])
	static val preIndexingFeatureMapForType = #[
		'description' -> new Function<ToscaType, String>() {
			override String apply(ToscaType element) {
				(element.entries.filter(YamlMappingEntry).findFirst[key === "description"]?.value as Scalar)?.
					stringValue
			}
		}
	]

	static val featureMapForType = #[
		'description' -> new Function<ToscaType, String>() {
			override String apply(ToscaType element) {
				(element.entries.filter(YamlMappingEntry).findFirst[key === "description"]?.value as Scalar)?.
					stringValue
			}
		}
	]
	static val featureMapForTypeMembers = #[
		'type' -> new Function<Iterable<YamlMappingEntry>, String>() {
			override String apply(Iterable<YamlMappingEntry> propValues) {
				propValues?.filter[key == "type"]?.map[value]?.flatten.filter(Scalar)?.findFirst [
					true
				]?.stringValue?.trim()
			}
		},
		'required' -> new Function<Iterable<YamlMappingEntry>, String>() {
			override String apply(Iterable<YamlMappingEntry> propValues) {
				propValues?.filter[key == "required"]?.map[value]?.flatten.filter(Scalar)?.findFirst [
					true
				]?.boolValue?.trim()
			}
		},
		'status' -> new Function<Iterable<YamlMappingEntry>, String>() {
			override String apply(Iterable<YamlMappingEntry> propValues) {
				propValues?.filter[key == "status"]?.map[value]?.flatten.filter(Scalar)?.findFirst [
					true
				]?.stringValue?.trim()
			}
		},
		'entry_schema' -> new Function<Iterable<YamlMappingEntry>, List<String>>() {
			override List<String> apply(Iterable<YamlMappingEntry> propValues) {
				propValues?.filter[key == "entry_schema"]?.map[value].flatten.filter(YamlRHS).map [
					entries
				].flatten.filter(YamlMappingEntry).filter[key == "type"].map[value].flatten.filter(Scalar).map [
					stringValue?.trim()
				].toList
			}
		}
	]

	/**
	 * convenience API to build and initialize JVM types and their members.
	 */
	@Inject extension JvmTypesBuilder
	@Inject extension JvmModelHelper

	/**
	 * The dispatch method {@code infer} is called for each instance of the
	 * given element's type that is contained in a resource.
	 * 
	 * @param element
	 *            the model to create one or more
	 *            {@link JvmDeclaredType declared
	 *            types} from.
	 * @param acceptor
	 *            each created
	 *            {@link JvmDeclaredType type}
	 *            without a container should be passed to the acceptor in order
	 *            get attached to the current resource. The acceptor's
	 *            {@link IJvmDeclaredTypeAcceptor#accept(org.eclipse.xtext.common.types.JvmDeclaredType)
	 *            accept(..)} method takes the constructed empty type for the
	 *            pre-indexing phase. This one is further initialized in the
	 *            indexing phase using the lambda you pass as the last argument.
	 * @param isPreIndexingPhase
	 *            whether the method is called in a pre-indexing phase, i.e.
	 *            when the global index is not yet fully updated. You must not
	 *            rely on linking using the index if isPreIndexingPhase is
	 *            <code>true</code>.
	 */
	def dispatch void infer(ToscaType element, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {
		if (!baseClassMap.keySet.filter[it.matches("(?i:.*\\." + element.name + ")")].empty) {
			acceptor.accept(
				element.toClass(baseClassMap.keySet.findFirst[it.matches("(?i:.*\\." + element.name + ")")])
			)
		} else {
			acceptor.accept(element.toClass(element.name) [
				var description = (element.entries.filter(YamlMappingEntry).findFirst[key === "description"]?.
					value as Scalar)?.stringValue
				description = if (description !== null)
					description + ".\nSpecified in :" + element.eResource.URI + "."
				else
					description = "Specified in :" + element.eResource.URI + ""
				documentation = description
				interface = false
				var annoParam = newParamList.addStringParam("value", element.name)
				if (description !== null) {
					annoParam.addStringParam("description", description)
				}
				annotations += element.toAnno(
					typeof(ApiModel),
					annoParam
				)
			], [
				if (!isPreIndexingPhase) {
					superTypes += element.entries.filter(ToscaSuperTypeDeclaration)?.map[superType.name]?.map [
						typeRef(getNormalizedType(it))
					].findFirst[true].cloneWithProxies
					for (m : element.entries.filter(ToscaTypeMembers).map[entries].flatten) {
						var JvmTypeReference ref = null
						val propValues = m.value.filter(YamlRHS)?.map[entries].flatten.filter(YamlMappingEntry)
						var type = propValues?.filter[key == "type"]?.map[value]?.flatten.filter(Scalar)?.findFirst [
							true
						]?.stringValue?.trim()
						var required = propValues?.filter[key == "required"]?.map[value]?.flatten.filter(Scalar)?.
							findFirst [
								true
							]?.boolValue?.trim()
						var status = propValues?.filter[key == "status"]?.map[value]?.flatten.filter(Scalar)?.findFirst [
							true
						]?.stringValue?.trim()
						var entry_schema = propValues?.filter[key == "entry_schema"]?.map[value].flatten.filter(
							YamlRHS).map [
							entries
						].flatten.filter(YamlMappingEntry).filter[key == "type"].map[value].flatten.filter(Scalar)?.map [
							typeRef(getNormalizedType(stringValue?.trim())).cloneWithProxies
						].toList
						var _default = propValues?.filter[key == "default"]?.map[value]?.flatten.filter(Scalar)?.
							findFirst [
								true
							]?.stringValue?.trim()
						var constraints = propValues?.filter[key == "constraints"]?.map[value]?.flatten.filter(Scalar)?.
							findFirst[true]?.stringValue?.trim()

						ref = typeRef(getNormalizedType(type))
						if (entry_schema !== null && entry_schema.size > 0) {
							if (ref.qualifiedName == "java.util.Map" && entry_schema.size == 1) {
								entry_schema.add(0, typeRef(getNormalizedType('java.lang.String')).cloneWithProxies)
							}
							ref = typeRef(ref.qualifiedName, entry_schema)
						}
						members += m.toField(m.key, ref) [
							documentation = propValues?.filter[key == "description"]?.map[value]?.flatten.filter(
								Scalar)?.findFirst[true]?.stringValue?.trim()
							var annoParam = newParamList.addStringParam("name", m.key)
							if(documentation !== null) annoParam.addStringParam("value", documentation)
							annotations += element.toAnno(typeof(ApiModelProperty), annoParam)
						]
					}
				}
			])
		}
	}

	def static private String getNormalizedType(String typeString) {
		var type = 'java.lang.Object'
		if (typeString !== null) {
			if (!baseClassMap.keySet.filter[it.matches("(?i:.*\\." + typeString + ")")].empty) {
				type = baseClassMap.keySet.findFirst[it.matches("(?i:.*\\." + typeString + ")")]
				return type
			}
		}
		return type
	}

}
