package org.ezyaml.lang.tosca.converters;

import java.util.regex.Pattern;

import org.eclipse.xtext.common.services.DefaultTerminalConverters;
import org.eclipse.xtext.conversion.IValueConverter;
import org.eclipse.xtext.conversion.ValueConverter;
import org.eclipse.xtext.conversion.impl.AbstractNullSafeConverter;
import org.eclipse.xtext.nodemodel.INode;

public class Yaml2XtextTerminalConverters extends DefaultTerminalConverters {
	private static final Pattern ID_PATTERN = Pattern.compile("(\\p{Alpha}\\w*)*");

	@ValueConverter(rule = "MultiLineString")
	public IValueConverter<String> MultiLineString() {
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
				if (ID_PATTERN.matcher(value).matches()) {
					return ID().toString(value);
				} else {
					return STRING().toString(value);
				}
			}
		};
	}
}
