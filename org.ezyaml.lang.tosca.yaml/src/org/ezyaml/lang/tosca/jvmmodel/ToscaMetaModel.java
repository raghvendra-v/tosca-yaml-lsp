package org.ezyaml.lang.tosca.jvmmodel;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

public class ToscaMetaModel {
	public static final int START_UTF8_CHAR_INDEX = 192;
	private static ToscaMetaModel INSTANCE;
	private Document model = null;
	private HashMap<Character, Element> nodesMapIndex = new HashMap<Character, Element>();
	private HashMap<Element, Character> nodesMarkerIndex = new HashMap<Element, Character>();
	private HashMap<String, List<Character>> tagIndex = new HashMap<String, List<Character>>();
	private String rootTag = "";
	private int index = 0;

	private ToscaMetaModel() throws SAXException, IOException, ParserConfigurationException {
		InputStream in = ToscaMetaModel.class.getResourceAsStream("/org/ezyaml/lang/tosca/tosca-metamodel.xml");
		DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
		DocumentBuilder builder = factory.newDocumentBuilder();
		model = builder.parse(in);
		rootTag = model.getDocumentElement().getTagName();
	}

	public static ToscaMetaModel getInstance() {
		synchronized (ToscaMetaModel.class) {
			if (INSTANCE == null) {
				try {
					INSTANCE = new ToscaMetaModel();
					INSTANCE.loadDictionaries(INSTANCE.model.getDocumentElement());
				} catch (SAXException | IOException | ParserConfigurationException e) {
					e.printStackTrace();
				}
			}
		}
		return INSTANCE;
	}

	private void loadDictionaries(final Element e) {
		NodeList all = e.getChildNodes();
		for (int i = 0; i < all.getLength(); i++) {
			if (all.item(i).getNodeType() == Node.ELEMENT_NODE) {
				char markerChar = (char) (START_UTF8_CHAR_INDEX + index++);
				Element elem = (Element) all.item(i);
				if (elem.getAttribute("ignore").equalsIgnoreCase("true")) {
					continue;
				}
				nodesMapIndex.put(markerChar, (Element) all.item(i));
				nodesMarkerIndex.put((Element) all.item(i), markerChar);
				if (!tagIndex.containsKey(elem.getTagName())) {
					List<Character> markers = new ArrayList<Character>();
					markers.add(markerChar);
					tagIndex.put(elem.getTagName(), markers);
				} else {
					tagIndex.get(elem.getTagName()).add(markerChar);
				}
				loadDictionaries((Element) all.item(i));
			}
		}
	}

	private List<Character> populateAncestors(final Element node) {
		List<Character> ancestors = new ArrayList<Character>();
		Element parent = node.getParentNode().getNodeType() == Node.ELEMENT_NODE
				&& !((Element) node).getAttribute("ignore").equalsIgnoreCase("true")
				&& !((Element) node.getParentNode()).getTagName().equals(rootTag) ? (Element) node.getParentNode()
						: null;
		while (parent != null) {
			ancestors.add(nodesMarkerIndex.get(parent));
			parent = parent.getParentNode().getNodeType() == Node.ELEMENT_NODE
					&& !((Element) parent).getAttribute("ignore").equalsIgnoreCase("true")
					&& !((Element) parent.getParentNode()).getTagName().equals(rootTag)
							? (Element) parent.getParentNode()
							: null;
		}
		// Collections.reverse(ancestors);
		return ancestors;
	}

	private Map<Character, List<Character>> getPossibleParents(String tagName) {
		Map<Character, List<Character>> map = new HashMap<Character, List<Character>>();
		NodeList elements = model.getDocumentElement().getElementsByTagName(tagName);
		for (int i = 0; i < elements.getLength(); i++) {
			List<Character> ancestors = null;
			if (elements.item(i).getNodeType() == Node.ELEMENT_NODE)
				ancestors = populateAncestors((Element) elements.item(i));
			if (ancestors.size() > 0 || elements.getLength() == 1) {
				map.put(nodesMarkerIndex.get(elements.item(i)), ancestors);
			}
		}
		return map;
	}

	public char getMarkerCharacter(String keyword, List<Character> currentLineage) {
		char marker = 0;
		Map<Character, List<Character>> parents = getPossibleParents(keyword);
		for (Character possibleMarker : parents.keySet()) {
			if (parents.keySet().size() == 1) {
				if (parents.get(possibleMarker).size() == 0) // top level element
				{
					marker = possibleMarker;
					break;
				}

			}
			if (doesLineageMatch(parents.get(possibleMarker), currentLineage)) {
				marker = possibleMarker;
				break;
			}
		}
		return marker;
	}

	private boolean doesLineageMatch(List<Character> possibleLineage, List<Character> lineage) {
		boolean matches = true;
		if (possibleLineage.size() == lineage.size()) {
			for (int i = 0; i < lineage.size(); i++) {
				if ((int) possibleLineage.get(i) != (int) lineage.get(i)) {
					matches = false;
					break;
				}

			}
		} else {
			matches = false;
		}
		return matches;
	}
}
