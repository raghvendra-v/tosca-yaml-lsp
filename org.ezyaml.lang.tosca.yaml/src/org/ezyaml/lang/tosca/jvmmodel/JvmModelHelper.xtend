package org.ezyaml.lang.tosca.jvmmodel

import com.google.common.base.Function
import com.google.inject.Inject
import java.util.ArrayList
import java.util.List
import java.util.Map
import java.util.TreeMap
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.common.types.JvmAnnotationReference
import org.eclipse.xtext.common.types.JvmAnnotationType
import org.eclipse.xtext.common.types.JvmAnnotationValue
import org.eclipse.xtext.common.types.JvmOperation
import org.eclipse.xtext.common.types.JvmStringAnnotationValue
import org.eclipse.xtext.common.types.TypesFactory
import org.eclipse.xtext.util.internal.Nullable
import org.eclipse.xtext.xbase.jvmmodel.JvmTypesBuilder

class JvmModelHelper {
		/**
	 * convenience API to build and initialize JVM types and their members.
	 */
	@Inject extension JvmTypesBuilder
	
		def JvmAnnotationReference toAnno(@Nullable EObject sourceElement, Class<?> annotationType,
		Map<String, List<Function<JvmAnnotationType, JvmAnnotationValue>>> namedParams) {

		val a = sourceElement.toAnnotation(annotationType) => [

			for (namedValue : namedParams.entrySet) {

				val annotationValueFactories = namedValue.value;

				explicitValues.addAll(annotationValueFactories.map([f|f.apply(annotation)]))
			} // for named param
		];

		return a;
	}

	def Map<String, List<Function<JvmAnnotationType, JvmAnnotationValue>>> newParamList() {

		return new TreeMap<String, List<Function<JvmAnnotationType, JvmAnnotationValue>>>();
	}

	def Map<String, List<Function<JvmAnnotationType, JvmAnnotationValue>>> addStringParam(
		Map<String, List<Function<JvmAnnotationType, JvmAnnotationValue>>> map, String paramName,
		String... stringValues) {

		return addValuesG(
			map,
			TypesFactory::eINSTANCE.createJvmStringAnnotationValue,
			paramName,
			stringValues,
			[p|return (p as JvmStringAnnotationValue).values;]
		);
	}

	def <ValueType, AnotationValueType extends JvmAnnotationValue> Map<String, List<Function<JvmAnnotationType, JvmAnnotationValue>>> addValuesG(
		Map<String, List<Function<JvmAnnotationType, JvmAnnotationValue>>> map,
		JvmAnnotationValue newAnotationParameterAssignment,
		String paramName,
		ValueType[] valuesOfNamedAnnotationParameter,
		Function<JvmAnnotationValue, ? extends List<ValueType>> valuesExtr
	) {

		val effMap = if(map !== null) map else newParamList();

		if (valuesOfNamedAnnotationParameter.contains(null))
			throw new IllegalArgumentException("Value for Annotation-Param " + paramName + " must not be null.");

		effMap.addValue2AnnotationParamMap(paramName, [ aType |

			val op = aType.members.filter(typeof(JvmOperation)).filter(o|paramName.equals(o.simpleName)).head;
			newAnotationParameterAssignment.operation = op;

			valuesExtr.apply(newAnotationParameterAssignment) += valuesOfNamedAnnotationParameter;

			return newAnotationParameterAssignment;
		]);

		return effMap;
	}

	def Map<String, List<Function<JvmAnnotationType, JvmAnnotationValue>>> addValue2AnnotationParamMap(
		Map<String, List<Function<JvmAnnotationType, JvmAnnotationValue>>> map, String paramName,
		Function<JvmAnnotationType, JvmAnnotationValue> valueFactory) {

		val effParamName = if (paramName !== null) {
				if(!"".equals(paramName)) paramName else "value";
			} else
				"value";

		var List<Function<JvmAnnotationType, JvmAnnotationValue>> valueList = map.get(effParamName)
		if (valueList === null) {
			valueList = new ArrayList<Function<JvmAnnotationType, JvmAnnotationValue>>();
			map.put(effParamName, valueList);
		} else
			throw new IllegalArgumentException("Duplicate creation of the '" + effParamName + "' parameter.");

		valueList.add(valueFactory);

		return map;
	}
	
}