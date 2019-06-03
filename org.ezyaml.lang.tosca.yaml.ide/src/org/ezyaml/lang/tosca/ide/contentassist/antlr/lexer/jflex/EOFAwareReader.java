package org.ezyaml.lang.tosca.ide.contentassist.antlr.lexer.jflex;

import java.io.CharArrayReader;
import java.io.IOException;

/* Appends a newline char in the end of stream if not found already*/
public class EOFAwareReader extends CharArrayReader {

	private boolean isEOFReached = false;
	private char lastCharRead;

	public EOFAwareReader(char[] buf) {
		super(buf);
	}

	public EOFAwareReader(char[] data, int i, int data_length) {
		super(data, i, data_length);
	}

	@Override
	public int read() throws IOException {
		int c = super.read();
		if (c == -1) {
			if (!isEOFReached && lastCharRead != '\r' && lastCharRead != '\n') {
				c = (int) '\r';
				isEOFReached = true;
			}
		} else {
			lastCharRead = (char) c;
		}
		return c;
	}

	@Override
	public int read(char[] b, int off, int len) throws IOException {
		int numRead = 0;
		if (len > 1)
			numRead = super.read(b, off, len - 1);
		else 
			return super.read(b, off, len);
		int c = read();
		if ( c != -1 ) {
			if ( numRead==-1) { numRead=1; b[off]=(char)c; return numRead;}
			b[off+numRead++]=(char)c;
		}
		return numRead;
	}

}
