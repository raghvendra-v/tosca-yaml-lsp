package org.ezyaml.lang.tosca.tests

import com.google.inject.Inject
import com.google.inject.Provider
import java.io.File
import java.io.IOException
import java.io.OutputStream
import java.io.PrintStream
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.util.List
import java.util.stream.Collectors
import org.eclipse.emf.common.util.URI
import org.eclipse.xtext.generator.GeneratorDelegate
import org.eclipse.xtext.generator.InMemoryFileSystemAccess
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.ezyaml.lang.tosca.yaml.YamlDocument
import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.MethodOrderer.OrderAnnotation
import org.junit.jupiter.api.Order
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.TestMethodOrder
import org.junit.jupiter.api.^extension.ExtendWith
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.Arguments
import org.junit.jupiter.params.provider.MethodSource

import static org.junit.jupiter.api.Assertions.*

@ExtendWith(InjectionExtension)
@InjectWith(YamlInjectorProvider)
@DisplayName("OSM YAML Parse Test")
@TestInstance(PER_CLASS)
@TestMethodOrder(OrderAnnotation)
class OSM_BulkParserTest {
	val static configFilePaths = #["test-resources/devops/descriptor-packages"];

	@Inject
	ParseHelper<YamlDocument> parseHelper
	@Inject GeneratorDelegate underTest
	@Inject
	var Provider<XtextResourceSet> resourceSetProvider

	val dummy = new PrintStream(new OutputStream() {
		override write(int b) throws IOException {
			// DO NOTHING
		}
	})
	val original = System.out
	var static XtextResourceSet resourceSet
	var static InMemoryFileSystemAccess fsa

	@BeforeAll
	def void initialize() {
		fsa = new InMemoryFileSystemAccess()
	}

	def static List<Arguments> getFiles() {
		configFilePaths.map([new File(it)]).forEach[println("Loading: "+it.absolutePath)]
		val List<Path> paths = newArrayList()
		configFilePaths.forEach [ configFilePath |
			paths.addAll((Files.walk(Paths.get(configFilePath)).collect(Collectors.toList())))
		]
		paths.filter[p|Files.isRegularFile(p) && ( p.toString.endsWith(".yaml") || p.toString.endsWith(".yml"))].map [ p |
			Arguments.of(p.fileName.toString, p)
		].toList
	}

	@ParameterizedTest(name="{0}")
	@MethodSource("getFiles")
	@Order(1)
	def void parseYaml(String fileName, Path p) {
		if(resourceSet === null) resourceSet = resourceSetProvider.get
		try {
			System.setOut(dummy)
			var r = parseHelper.parse(new String(Files.readAllBytes(p)), URI.createURI(fileName), resourceSet)
			System.setOut(original)
			Assertions.assertNotNull(r)
			var errors = r.eResource.errors
			Assertions.assertTrue(errors.isEmpty, '''Errors while parsing «p.toString»: «errors.join("\n\t")»''')
		} catch (Throwable t) {
			System.setOut(original)
			fail('''Error while parsing «p.toString»: «t.message»''', t)

		}

	}

	@Test
	@DisplayName("Generate Resources")
	@Order(2)
	def void generateResources() {
		var resourceList = resourceSet.resources.filter([it.URI.fileExtension.matches("ya*ml")]).toList
		for (r : resourceList) {
			try {
				println(r.URI)
				underTest.doGenerate(r, fsa)
			} catch (Throwable t) {
				println('''Error while parsing «r.URI»''')
			}
		}

	}

	@AfterAll
	def void printGenrated() {
		println("Listing files:\n"+fsa.allFiles)
	}
}
