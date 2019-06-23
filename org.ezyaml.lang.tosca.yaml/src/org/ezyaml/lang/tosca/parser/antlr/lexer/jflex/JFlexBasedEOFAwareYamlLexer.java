/*
 * generated by Xtext 2.18.0
 */
package org.ezyaml.lang.tosca.parser.antlr.lexer.jflex;

import java.io.Reader;
import java.lang.reflect.Field;

import org.antlr.runtime.ANTLRStringStream;
import org.antlr.runtime.CharStream;
import org.antlr.runtime.RecognitionException;
import org.antlr.runtime.Token;
import org.ezyaml.lang.tosca.parser.antlr.lexer.InternalYamlLexer;
import org.ezyaml.lang.tosca.parser.antlr.lexer.jflex.EOFEmitterReader;

public class JFlexBasedEOFAwareYamlLexer extends InternalYamlLexer {
	YamlFlexer delegate = new YamlFlexer((Reader)null);

	@Override
	public void mTokens() throws RecognitionException {
		throw new UnsupportedOperationException();
	}

	@Override
	public CharStream getCharStream() {
		return new ANTLRStringStream(data, data.length);
	}

	@Override
	public Token nextToken() {
		return delegate.nextToken();
	}

	char[] data = null;
	int data_length = -1;

	@Override
	public void setCharStream(CharStream input) {
		try {
			Field field = ANTLRStringStream.class.getDeclaredField("data");
			Field field_n = ANTLRStringStream.class.getDeclaredField("n");
			field.setAccessible(true);
			field_n.setAccessible(true);
			data = (char[]) field.get(input);
			data_length = (Integer) field_n.get(input);
			reset();
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
	}

	@Override
	public void reset() {
		delegate.reset(new EOFEmitterReader(data, 0, data_length));
	}
}
