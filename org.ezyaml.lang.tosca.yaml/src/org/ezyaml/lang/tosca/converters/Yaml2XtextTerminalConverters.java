package org.ezyaml.lang.tosca.converters;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

import org.eclipse.xtext.common.services.DefaultTerminalConverters;
import org.eclipse.xtext.conversion.IValueConverter;
import org.eclipse.xtext.conversion.ValueConverter;
import org.eclipse.xtext.conversion.impl.AbstractNullSafeConverter;
import org.eclipse.xtext.impl.RuleCallImpl;
import org.eclipse.xtext.impl.TerminalRuleImpl;
import org.eclipse.xtext.nodemodel.ICompositeNode;
import org.eclipse.xtext.nodemodel.ILeafNode;
import org.eclipse.xtext.nodemodel.INode;
import org.eclipse.xtext.nodemodel.impl.LeafNode;

public class Yaml2XtextTerminalConverters extends DefaultTerminalConverters {
	private static final String DEFAULT_SEPERATOR = ":";
	private static final String FOLDING = "FOLDING";
	private static final String CHOMPING = "CHOMPING";
	private static final String EOL = "EOL";
	private static final String MARGIN = "MARGIN";

	private static final Pattern FOLDING_SEPARATOR = Pattern
			.compile(".*:\\s(?<" + FOLDING + ">[|>])(?<" + CHOMPING + ">[\\-+])?");

	@ValueConverter(rule = "MultiLineString")
	public IValueConverter<String> MultiLineString() {
		return new AbstractNullSafeConverter<String>() {
			@Override
			protected String internalToValue(String string, INode node) {
				ICompositeNode m = node.getParent().getParent().getParent();// Get the YamlMappingExpr
				String separator = DEFAULT_SEPERATOR;
				if (((org.eclipse.xtext.RuleCall) m.getGrammarElement()).getRule().getName()
						.matches("YamlMappingExpr|YamlMappingEntry")) {
					Optional<ILeafNode> d = StreamSupport.stream(m.getLeafNodes().spliterator(), false)
							.filter(l -> l.getGrammarElement() instanceof org.eclipse.xtext.Keyword
									&& ((org.eclipse.xtext.Keyword) l.getGrammarElement()).getValue().equals(":"))
							.findFirst();
					if (d.isPresent() && d.get() instanceof LeafNode) {
						separator = ((org.eclipse.xtext.nodemodel.impl.LeafNode) d.get()).getText();
					}
				}

				Matcher matcher = null;
				Folding folding = null;
				Chomping chomping = null;
				if (!separator.equals(DEFAULT_SEPERATOR)
						&& (matcher = FOLDING_SEPARATOR.matcher(separator)).matches()) {
					folding = Folding.get(matcher.group(FOLDING));
					chomping = Chomping.get(matcher.group(CHOMPING) == null ? "" : matcher.group(CHOMPING));
				}

				List<ILeafNode> leaves = StreamSupport.stream(node.getLeafNodes().spliterator(), false)
						.collect(Collectors.toList());
				List<String> text = new ArrayList<String>();

				/*
				 * insane documentation https://yaml.org/spec/1.2/spec.html 8.1.3. Folded Style
				 * and 6.5. Line Folding Folding allows long lines to be broken anywhere a
				 * single space character separates two non-space characters.
				 */
				for (int i = 0; i < leaves.size(); i++) {
					ILeafNode leaf = leaves.get(i);
					if (isMARGIN(leaf))
						continue;
					if (isEOL(leaf)) {
						if (folding == Folding.LITERAL) {
							text.add(leaf.getText());
						} else {
							text.add(" "); // EOL will capture any trailing new lines
						}
						break;
					} else if (folding == Folding.FOLDED && leaf.getText().matches("\\s+")) {
						if (!(i > 0 && isEOL(leaves.get(i - 1))
								|| (i < leaves.size() - 1 && isEOL(leaves.get(i + 1))))) {
							text.add(leaf.getText());
						}

					} else {
						text.add(leaf.getText());
					}
				}
				string = String.join("", text);
				if (folding == Folding.LITERAL) {
					switch (chomping) {
					case CLIP:
						string = string.replace("[\r\n]+$", "");
						break;
					case STRIP:
						string = string.replace("[\r\n]+$", "\n");
						break;
					default:
						break;
					}
				}

				if ((string.startsWith("'") && string.endsWith("'"))
						|| (string.startsWith("\"") && string.endsWith("\""))) {
					return STRING().toValue(string, node);
				}

				return ID().toValue(string, node);
			}

			@Override
			protected String internalToString(String value) {
				return STRING().toString(value);
			}
		};

	}

	private boolean isEOL(ILeafNode leaf) {
		return leaf.isHidden() && leaf instanceof TerminalRuleImpl
				&& ((TerminalRuleImpl) leaf.getGrammarElement()).getName().equals(EOL);
	}

	private boolean isMARGIN(ILeafNode leaf) {
		return !leaf.isHidden() && leaf instanceof RuleCallImpl
				&& ((RuleCallImpl) leaf.getGrammarElement()).getRule().getName().matches(MARGIN);
	}

	@ValueConverter(rule = "STR")
	public IValueConverter<String> STR() {
		return new AbstractNullSafeConverter<String>() {
			@Override
			protected String internalToValue(String string, INode node) {
				if ((string.startsWith("'") && string.endsWith("'"))
						|| (string.startsWith("\"") && string.endsWith("\""))) {
					return STRING().toValue(string, node);
				}
				return ID().toValue(string, node);
			}

			@Override
			protected String internalToString(String value) {
				return STRING().toString(value);
			}
		};
	}

	@ValueConverter(rule = "KEY_STR")
	public IValueConverter<String> KEY_STR() {
		return new AbstractNullSafeConverter<String>() {
			@Override
			protected String internalToValue(String string, INode node) {
				if ((string.startsWith("'") && string.endsWith("'"))
						|| (string.startsWith("\"") && string.endsWith("\""))) {
					return STRING().toValue(string, node);
				}
				return ID().toValue(string, node).trim();
			}

			@Override
			protected String internalToString(String value) {
				return STRING().toString(value);
			}
		};
	}
}

enum Folding {
	FOLDED(">"), LITERAL("|");
	private String indicator;

	Folding(String indicator) {
		this.indicator = indicator;
	}

	public String getIndicator() {
		return indicator;
	}

	private static final Map<String, Folding> lookup = new HashMap<>();
	static {
		for (Folding env : Folding.values()) {
			lookup.put(env.getIndicator(), env);
		}
	}

	public static Folding get(String indicator) {
		return lookup.get(indicator);
	}
}

enum Chomping {
	STRIP("-"), CLIP(""), KEEP("+");
	private String indicator;

	Chomping(String indicator) {
		this.indicator = indicator;
	}

	public String getIndicator() {
		return indicator;
	}

	private static final Map<String, Chomping> lookup = new HashMap<>();
	static {
		for (Chomping env : Chomping.values()) {
			lookup.put(env.getIndicator(), env);
		}
	}

	public static Chomping get(String indicator) {
		return lookup.get(indicator);
	}
}