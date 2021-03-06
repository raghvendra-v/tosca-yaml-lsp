package org.ezyaml.lang.tosca.parser.antlr.lexer.jflex;
import static org.ezyaml.lang.tosca.parser.antlr.internal.InternalYamlParser.*;

import java.io.IOException;
import java.io.Reader;
import java.lang.reflect.Field;
import java.util.HashMap;
import java.util.List;
import java.util.OptionalInt;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedList;
import java.util.Stack;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.antlr.runtime.CommonToken;
import org.antlr.runtime.Token;
import org.antlr.runtime.TokenSource;
import org.ezyaml.lang.tosca.parser.antlr.internal.InternalYamlParser;
import org.ezyaml.lang.tosca.jvmmodel.ToscaMetaModel;

@SuppressWarnings({"all"})
%%

%{
	private static final char START_OF_IN_SEQ = '[';
	private static final char START_OF_IN_MAP = '{';
	private static final char START_OF_RHS = ':';
	private static final char START_OF_SEQ = '-';
	private static final char START_OF_STR = '\"';
	private static final char START_OF_STR_INDENT = '\'';
	private static final Pattern INDENT = Pattern.compile("(\\s+)(.*)[\\r\\n]*");
	private static final Pattern MAP_SEPERATOR = Pattern.compile("(?<!:\\s)((:[\\ \\r\\n]+)|(:$)).*[\\r\\n]*");
	private static final Pattern SEQUENCE_START = Pattern.compile("(-\\s*).*[\\r\\n]*");


	public final static TokenSource createTokenSource(Reader reader) {
		ToscaMetaModel.getInstance();
		return new YamlFlexer(reader);
	}

	private int offset = 0;

	public void reset(Reader reader) {
		yyreset(reader);
		offset = 0;
	}

	private static final HashMap<Integer, String> DICTIONARY = new HashMap<Integer, String>();
	private static final HashMap<String, Integer> KEYWORDS = new HashMap<String, Integer>();
	private static final String PREFIX = "RULE_";
	static {
		/* all this pain to print the token names instead of numbers */
		Class<? extends Object> c = InternalYamlParser.class;
		Field[] fields = c.getDeclaredFields();
		List<String> keywords = Arrays.asList(InternalYamlParser.tokenNames);
		for (Field f : fields) {
			if (f.getType() == int.class && f.getModifiers() == 25) {
				try {
					int value = f.getInt(null);
					String name = f.getName();
					DICTIONARY.put(value, f.getName().replace(PREFIX, ""));
					if ( !name.startsWith(PREFIX) && keywords.contains(name)) {
						KEYWORDS.put(name.substring(0,1).toLowerCase().concat(name.substring(1)), value);
					}
				} catch (IllegalArgumentException | IllegalAccessException e) {
					e.printStackTrace();
				}
			}
		}
	}
	class MarkerStack {
		int indent;
		Stack<Character> stack;

		public MarkerStack(int indent, Character marker) {
			super();
			this.indent = indent;
			this.stack = new Stack<Character>();
			this.stack.push(marker);
		}

		public MarkerStack(int indent) {
			super();
			this.indent = indent;
			this.stack = new Stack<Character>();
		}

		@Override
		public String toString() {
			return "MarkerStack [" + indent + "=>" + stack + "]";
		}
	}

	class PendingTokenHelper {
		protected LinkedList<CommonTokenWithText> pendingTokens = new LinkedList<CommonTokenWithText>();

		public void push(int type, String text) {
			this.pendingTokens.add(new CommonTokenWithText(text, type, Token.DEFAULT_CHANNEL, offset));
			offset += text.length();
		}

		public void push(int type) {
			this.pendingTokens.add(new CommonTokenWithText("", type, Token.DEFAULT_CHANNEL, offset));
		}

		public int generatePendingTokens(int currentINDENT) {
			int markerTokenAt = markerStack.empty() ? Integer.MIN_VALUE : markerStack.peek().indent;
			int count = 0;
			while ((zzAtEOF && !markerStack.empty()) || currentIndent < markerTokenAt) {
				int type;
				char marker = markerStack.peek().stack.pop();
				switch (marker) {
				case START_OF_RHS:
					type = RULE_END_OF_RHS;
					break;
				case START_OF_STR:
					type = RULE_END_OF_STR;
					break;
				case START_OF_SEQ:
					type = RULE_END_OF_SEQ;
					break;
				default:
					type = RULE_HIDDEN;
				}
				if (markerStack.peek().stack.empty()) {
					markerStack.pop();
				}
				this.pendingTokens.add(new CommonTokenWithText("", type, Token.DEFAULT_CHANNEL, offset));
				count++;
			}
			return count;
		}

		public Token getPending() {
			if (markerStack.empty() && zzAtEOF && pendingTokens.isEmpty()) {
				return Token.EOF_TOKEN;
			} else {
				return pendingTokens.poll();
			}
		}

		public boolean isEmpty() {
			return this.pendingTokens.isEmpty();
		}
		
		public String toString() {
			return pendingTokens.toString();
		}
	}
	private List<Character> getKeywordHierarchy() {
		List<Character> hierarchy = new ArrayList<Character>();
		for (int i = markerStack.size() - 1; i >= 0; i--) {
			 OptionalInt x = markerStack.get(i).stack.stream().mapToInt(v->v).filter(c -> c >= ToscaMetaModel.START_UTF8_CHAR_INDEX).min();
			if ( x.isPresent()) 
				hierarchy.add((char)x.getAsInt());
			
		}
		return hierarchy;
	}
	protected Stack<Integer> indentationStack = new Stack<Integer>();
	protected PendingTokenHelper pendingTokens = new PendingTokenHelper();
	protected Stack<Character> inlineCollectionsStack = new Stack<Character>();
	protected Stack<MarkerStack> markerStack = new Stack<MarkerStack>();

	private int currentIndent = 0;

	public Token nextToken() {
	/*-
		System.out.print("markerStack=" + markerStack);
		System.out.print(" indentationStack=" + indentationStack);
		System.out.print(" pendingTokens=" + pendingTokens);
		System.out.print(" inlineCollectionsStack=" + inlineCollectionsStack);
		System.out.println(" yystate()=" + yystate());
	-*/

		try {
			Token result = pendingTokens.getPending();
			int type = -1;
			if (result == null) {
				type = advance();
				result = pendingTokens.getPending();
				if (result != null) {
					pendingTokens.push(type, yytext());
				} else {
					result = new CommonTokenWithText(yytext(), type, Token.DEFAULT_CHANNEL, offset);
					offset += yylength();
				}
			}
			if (result.getType() == RULE_KEY_STR && KEYWORDS.containsKey(result.getText())) {
				List<Character> hierarchy = getKeywordHierarchy();
				char marker = ToscaMetaModel.getInstance().getMarkerCharacter(result.getText(), hierarchy);
				if (marker != 0) {
					pushMarkerToken(currentIndent, marker);
					result.setType(KEYWORDS.get(result.getText()));
				}
			}
			/*-
			System.out.println("result=" + result);
			-*/
			return result;
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
	}

	@Override
	public String getSourceName() {
		return "FlexTokenSource";
	}

	public static class CommonTokenWithText extends CommonToken {
		private static final long serialVersionUID = 1L;

		public CommonTokenWithText(String tokenText, int type, int defaultChannel, int offset) {
			super(null, type, defaultChannel, offset, offset + tokenText.length() - 1);
			this.text = tokenText;
		}

		public String toString() {

			String channelStr = "";
			if (channel > 0) {
				channelStr = ",channel=" + channel;
			}
			String txt = getText();
			if (txt != null) {
				txt = txt.replace("\n", "\\n");
				txt = txt.replace("\r", "\\r");
				txt = txt.replace("\t", "\\t");
			} else {
				txt = "<no text>";
			}
			String typeString = DICTIONARY.containsKey(type) ? DICTIONARY.get(type) : String.valueOf(type);

			return "[@" + getTokenIndex() + "," + start + ":" + stop + "='" + txt + "',<" + typeString + ">"
					+ channelStr + "," + line + ":" + getCharPositionInLine() + "]";
		}
	}

	private int getIndentType() {
		int INDENT_TYPE;
		int prevIndent = indentationStack.empty() ? 0 : indentationStack.peek();
		if (prevIndent > currentIndent) {
			INDENT_TYPE = RULE_DEDENT;
		} else if (prevIndent < currentIndent) {
			INDENT_TYPE = RULE_INDENT;
		} else {
			INDENT_TYPE = RULE_MARGIN;
		}
		String indentTypeStr = DICTIONARY.containsKey(INDENT_TYPE) ? DICTIONARY.get(INDENT_TYPE)
				: String.valueOf(INDENT_TYPE);
		/*-
		System.out.println("YYINITIAL INDENT : [current=" + currentIndent + " ,previous=" + prevIndent
				+ " ] returning (" + indentTypeStr + " ) ");-*/
		return INDENT_TYPE;
	}

	private void pushMarkerToken(int indent, Character markerToken) {
		if (markerStack.empty() || markerStack.peek().indent != indent) {
			if (!markerStack.empty() && markerStack.peek().stack.empty()) {
				markerStack.pop();
			}
			markerStack.push(new MarkerStack(indent));
		}
		switch (markerToken) {
		case START_OF_RHS:
			markerStack.peek().stack.push(markerToken);
			pendingTokens.push(RULE_START_OF_RHS);
			break;
		case START_OF_STR:
			markerStack.peek().stack.push(markerToken);
			pendingTokens.push(RULE_START_OF_STR);
			break;
		case START_OF_STR_INDENT:
			boolean isIndentRecorded=false;
			for (int i=markerStack.size()-1;i>=0;i--) {
				if ( markerStack.get(i).stack.contains(START_OF_STR_INDENT)) {
					isIndentRecorded=true;
					break;
				}
			}
			if ( !isIndentRecorded ) { markerStack.peek().stack.push(markerToken); currentIndent=indent;handleINDENT();}
			break;
		case START_OF_SEQ:
			if (markerStack.peek().stack.contains(START_OF_SEQ)) {
				pendingTokens.push(RULE_START_OF_SEQ_ENTRY);
			} else {
				pendingTokens.push(RULE_START_OF_SEQ);
				markerStack.peek().stack.push(markerToken);
			}
			break;
		default: markerStack.peek().stack.push(markerToken);
		}
	}
	private int getMultilineStringIndent() {
		int indent=currentIndent;
		for (int i=markerStack.size()-1;i>=0;i--) {
			if ( markerStack.get(i).stack.contains(START_OF_STR_INDENT)) {
				indent=markerStack.get(i).indent;
				break;
			}
		}
		return indent;
	}
	private void handleINDENT() {
		handleINDENT(currentIndent); 
	}

	private void handleINDENT(int indentLen) {
		int prevIndent = indentationStack.empty() ? 0 : indentationStack.peek();
		int KIND_OF_INDENT = getIndentType();
		if (KIND_OF_INDENT == RULE_DEDENT) {
			fillClosingTokens(prevIndent, currentIndent);
			int prev = indentationStack.empty() ? 0 : indentationStack.peek();
			if (prev < currentIndent) {
				/*
				 * when the dedent closes the previous indent , but current expr is still a
				 * sibling of the closed one
				 */
				indentationStack.push(currentIndent);
				KIND_OF_INDENT = RULE_INDENT;
			} 	else if (prev == currentIndent) {
				/*
				 * when the dedent closes the previous indent , but current expr is still a
				 * sibling of the closed one
				 */
				KIND_OF_INDENT = RULE_MARGIN;
			}
		} else if (KIND_OF_INDENT == RULE_INDENT) {
			indentationStack.push(currentIndent);
		} else {
			fillClosingTokens(prevIndent, currentIndent);
		}
		StringBuilder indentText = new StringBuilder();
		for ( int i=0;i<indentLen;i++)indentText.append(' ');
		zzStartRead+=indentLen;yycolumn+=indentLen;
		pendingTokens.push(KIND_OF_INDENT,indentText.toString());
		/*-
		System.out.println("handleINDENT indentationStack=" + indentationStack);
		-*/
	}

	private void fillClosingTokens(int prevIndent, int currIndent) {
		boolean process = true;
		if (currIndent <= prevIndent) {
			while (!markerStack.empty() && process && markerStack.peek().indent >= currIndent) {
				if (markerStack.peek().stack.empty()) {
					markerStack.pop();
					if (!indentationStack.empty() && indentationStack.peek() > currentIndent) indentationStack.pop();
					continue;
				}
				char marker = markerStack.peek().stack.pop();
				int type = -10;
				switch (marker) {
				case START_OF_RHS:
					type = RULE_END_OF_RHS;
					break;
				case START_OF_STR:
					type = RULE_END_OF_STR;
					break;
				case START_OF_SEQ:
					if ( markerStack.peek().indent > currIndent )
						type = RULE_END_OF_SEQ;	
					else if (markerStack.peek().indent == currIndent) {
						markerStack.peek().stack.add(marker);//put it back, sequence is not ending : we popped it earlier
						if ( markerStack.peek().stack.size()==1) {
							process=false; // hyphen is the only character left stop processing this indent
						}
					}
					break;
				default:
					break;
				}
				if (type != -10) { pendingTokens.push(type); } /*else { if (process) { System.out.println("Error!");pendingTokens.push(type); }}*/
			}
		}
	}
	
	private int getNextState(char toRemove) {
		if (inlineCollectionsStack.empty() && inlineCollectionsStack.peek() != toRemove) {
			zzScanError(1);
		}
		inlineCollectionsStack.pop();
		int nextState = RHS_VAL;
		if (!inlineCollectionsStack.empty()) {
			switch (inlineCollectionsStack.peek()) {
			case START_OF_IN_SEQ:
				nextState = INLINE_SEQUENCE;
				break;
			case START_OF_IN_MAP:
				nextState = INLINE_MAPPING;
				break;
			default:
				nextState = -100;
			}
		}
		return nextState;
	}
	private void handleKeywordAsKey() {
		Matcher indent_matcher=INDENT.matcher(yytext());
		int firstIndent=( indent_matcher.matches()? indent_matcher.end(1):0);
		currentIndent=firstIndent+yycolumn;
		handleINDENT(firstIndent);//pushes a marker type INDENT, but with a lesser spread, same as first
		yybegin(SEPERATOR);
	}
%}
/*-
%debug 
-*/
%unicode
%column
%line
%implements org.antlr.runtime.TokenSource
%class YamlFlexer
%function advance
%public
%int
%eofval{
		pendingTokens.generatePendingTokens(0);
		/*-
		System.out.println("markerStack="+markerStack);
		-*/
		return Token.EOF;
%eofval}

U_NUMBER = [0-9]+ ("." [0-9]+)? | "." [0-9]+
NUMBER = ("+"|"-")? {U_NUMBER} ( "e" ("+"|"-")? [1-9] [0-9]* )?
NULL = "null" | "Null" | "NULL" | "~"
OCTAL = "0o" [0-7]+
HEX =  "0x" [0-9a-fA-F]+
BOOLEAN= y|Y|yes|Yes|YES|n|N|no|No|NO|true|True|TRUE|false|False|FALSE|on|On|ON|off|Off|OFF
STRING= ({ID})(([\ ]+{ID})|([\-\.]+{ID}))*
SINGLE_QUOTED_STRING= "'" [^']* "'"?
DOUBLE_QUOTED_STRING= \" ([^\\\"]|\\.)* \"?
ESCAPED_DQ_STRING= \\\" [^\\\"]* \\\"?
ESCAPED_SQ_STRING= "'" [^\\']* "'"? //is there a thing like ESCAPED_SQ_STRING. and this is not working
ANY_STRING= {ESCAPED_DQ_STRING} | {ESCAPED_SQ_STRING} | {SINGLE_QUOTED_STRING} | {DOUBLE_QUOTED_STRING}  | {STRING} 
SEPARATOR=":"
EOL=[\n\r]+
SL_COMMENT="#" [^\r\n]*

ID= [a-zA-Z_\^<$%@()/] [a-zA-Z0-9_!\^<>\?&$%@*()/]*
INDENT= [\ ]+



%s MAPPING_EXPR, SEQUENCE_EXPR, MIXED_STRING, RHS_VAL
%s SEPERATOR, INDENTATION
%s INLINE_SEQUENCE, INLINE_SEQUENCE_ENTRY, INLINE_MAPPING, INLINE_MAPPING_KEY, INLINE_MAPPING_SEPARATOR, INLINE_MAPPING_VALUE
%s FIRST_FOLDED_LINE, FIRST_FOLDED_LINE_OF_BLK, FOLDED_RHS_STRING, BLK_FOLDED_RHS_STRING
%s ANCHORED_NODE, ANCHORED_VALUE
%%

<RHS_VAL> {
	{INDENT}						{  if (yycolumn==0) {  currentIndent=yylength(); return getIndentType(); } else { return RULE_HIDDEN; }  }
	{NULL}							{  yybegin(YYINITIAL); return RULE_NULL;}
	{HEX}		|						
	{OCTAL}		|					
	{NUMBER}						{  yybegin(YYINITIAL); return RULE_DECIMAL;}
	{BOOLEAN}						{  yybegin(YYINITIAL); return RULE_BOOLEAN;}
	"&"								{  yybegin(ANCHORED_NODE); return Ampersand;}
	"*"								{  yybegin(ANCHORED_VALUE); return Asterisk;}
	[^\ \[{#\r\n&*] [^#\r\n]*		{  pushMarkerToken(currentIndent, START_OF_STR); yypushback(yylength()); yybegin(MIXED_STRING); }
}
<ANCHORED_NODE> {
	[^\ \[{#\r\n&*]+					{  yybegin(RHS_VAL);return RULE_STR;}
}
<ANCHORED_VALUE> {
	[^\ \[{#\r\n&*]+					{  yybegin(YYINITIAL);return RULE_STR;}
}
<FIRST_FOLDED_LINE> {
	{EOL}							{ return RULE_EOL; }
	{INDENT} 						{   if (yycolumn==0) { currentIndent=yylength(); indentationStack.push(currentIndent); pushMarkerToken(currentIndent, START_OF_STR);  indentationStack.pop(); yybegin(BLK_FOLDED_RHS_STRING); return RULE_MARGIN; }  }
}
<BLK_FOLDED_RHS_STRING> {
	{INDENT}						{   if (yycolumn==0) { if( yylength() < currentIndent ) { indentationStack.push(currentIndent); /* just to enable fillClosingTokens */ yypushback(yylength()); yybegin(YYINITIAL); } else if( yylength() > currentIndent ) { yypushback(yylength()-currentIndent); return RULE_MARGIN; } else { return RULE_HIDDEN; } } else { return RULE_STR; }  }
	{INDENT} / {EOL}				{   if (yycolumn==0) { return RULE_HIDDEN; } else { return RULE_STR; }  }
	[^\ \r\n] [^#\r\n]*	/ (({SL_COMMENT})? {EOL})
									{  if (yycolumn==0) {  currentIndent=0;indentationStack.push(currentIndent);yypushback(yylength()); yybegin(YYINITIAL); } else {  return RULE_STR; }   }
	{EOL} 							{  return RULE_EOL; }
}
<INLINE_SEQUENCE> {
	[^\ \],\r\n]+ 	{ yypushback(yylength()); yybegin(INLINE_SEQUENCE_ENTRY);}
	"," 			{ return Comma;}
}
<INLINE_SEQUENCE_ENTRY> {
	{NUMBER} / [\ ]*[,\]]						{  yybegin(INLINE_SEQUENCE); return RULE_DECIMAL;	}
	{BOOLEAN} / [\ ]*[,\]]						{  yybegin(INLINE_SEQUENCE); return RULE_BOOLEAN;	}
	{ANY_STRING} / [\ ]*[,\]]					{  yybegin(INLINE_SEQUENCE); return RULE_STR; 		}
	[^,\[\]{: ] [^,\[\]{:]+ / [\ ]*[,\]]		{  yybegin(INLINE_SEQUENCE); return RULE_STR; 		}
}

<INLINE_MAPPING_KEY> {
	{NUMBER}  / ": "						{ yybegin(INLINE_MAPPING_SEPARATOR); return RULE_DECIMAL; }
	{BOOLEAN} / ": "						{ yybegin(INLINE_MAPPING_SEPARATOR); return RULE_BOOLEAN; }
	{ANY_STRING} / ": "						{ yybegin(INLINE_MAPPING_SEPARATOR); return RULE_KEY_STR; }
}
<INLINE_MAPPING_SEPARATOR> {
		{SEPARATOR}  / [\ ]    				{   yybegin(INLINE_MAPPING_VALUE); return Colon;   }
}
<INLINE_MAPPING_VALUE> {
	{NUMBER}  / [\ ]*[,}]						{ yybegin(INLINE_MAPPING); return RULE_DECIMAL; }
	{BOOLEAN}  / [\ ]*[,}]						{ yybegin(INLINE_MAPPING); return RULE_BOOLEAN;	}
	{ANY_STRING}  / [\ ]*[,}]   				{ yybegin(INLINE_MAPPING); return RULE_STR; }
	[^,\[\{: ] [^,\[\{:]+ / [\ ]*[,}]    		{ yybegin(INLINE_MAPPING); return RULE_STR; }
}

<INLINE_MAPPING> {
	[^ ,}\r\n]+  			{ yypushback(yylength()); yybegin(INLINE_MAPPING_KEY);}
	","						{ yybegin(INLINE_MAPPING_KEY); return Comma;}
}
<INLINE_MAPPING,INLINE_MAPPING_VALUE,INLINE_SEQUENCE> {
		{EOL}			{ return RULE_EOL; }
		[\ ]+			{ return RULE_HIDDEN;  }
}
<MAPPING_EXPR> 		{
	{ANY_STRING}[\ ]* / ":"  {  yybegin(SEPERATOR); return RULE_KEY_STR; }
}

<SEPERATOR> {
		{SEPARATOR} [\ ][>|][+\-]?   / (   [\ ]* ({SL_COMMENT})? {EOL})		{ 	yybegin(FIRST_FOLDED_LINE); pendingTokens.push(Colon,yytext()); pushMarkerToken(currentIndent, START_OF_RHS);}
		{SEPARATOR}  / (({SL_COMMENT})? {EOL})    				{ 	yybegin(RHS_VAL); pendingTokens.push(Colon,yytext()); pushMarkerToken(currentIndent, START_OF_RHS);  }
		{SEPARATOR}  / [\ ]    					{ 	pendingTokens.push(Colon,yytext()); pushMarkerToken(currentIndent, START_OF_RHS);  }
		[\ ]									{ 	yybegin(RHS_VAL); return RULE_HIDDEN;  }
}

<SEQUENCE_EXPR> {
	"-" / [\ \r\n]  				{  return HyphenMinus; }
	[\ ]							{  yybegin(RHS_VAL); 	return RULE_HIDDEN;}
	{EOL}     						{  yybegin(RHS_VAL); 	return RULE_EOL;}
}

<MIXED_STRING> {
	{ANY_STRING}   	 |
	[^\# \r\n\-] [^#\r\n]* 		     		{  if( yycolumn<currentIndent) { yypushback(yylength());  yybegin(YYINITIAL); } else {return RULE_STR;}}
	{INDENT} / (({SL_COMMENT})? {EOL})		{  return RULE_HIDDEN; }
}

<YYINITIAL> {
{INDENT} / (({SL_COMMENT})? {EOL})				{return RULE_HIDDEN;}
{INDENT}? ( {ESCAPED_DQ_STRING} | {ESCAPED_SQ_STRING} | {SINGLE_QUOTED_STRING} | {DOUBLE_QUOTED_STRING} ) / ( ":" ([\ ] .*)? (({SL_COMMENT})? {EOL}) )
												{ 
													Matcher indent_matcher=INDENT.matcher(yytext());
													currentIndent=yycolumn+ ( indent_matcher.matches()?indent_matcher.end(1):0);
													handleINDENT();
													yybegin(SEPERATOR); return RULE_KEY_STR;
												}
{INDENT}? "-" {INDENT} ( {ESCAPED_DQ_STRING} | {ESCAPED_SQ_STRING} | {SINGLE_QUOTED_STRING} | {DOUBLE_QUOTED_STRING}  )  / ([\ ]* (({SL_COMMENT})? {EOL}))
												{  
													Matcher indent_matcher=INDENT.matcher(yytext());
													int firstIndent=( indent_matcher.matches()? indent_matcher.end(1):0);
													Matcher seq_start_matcher=SEQUENCE_START.matcher(yytext().substring(firstIndent));
													int secondIndent=(seq_start_matcher.matches()? seq_start_matcher.end(1):0); //although this should match always
													currentIndent=firstIndent+secondIndent;
													handleINDENT(firstIndent); //pushes a marker type INDENT, but with a lesser spread, same as first
													pushMarkerToken(currentIndent, START_OF_SEQ);
													pendingTokens.push(HyphenMinus,"-");
													pendingTokens.push(RULE_HIDDEN,yytext().substring(1,secondIndent));
													pushMarkerToken(currentIndent, START_OF_STR); 
													zzStartRead+=secondIndent; //yycolumn+=currentIndent; this is like yypushforward of marker
													return RULE_STR; 
												}
"---" / (({SL_COMMENT})? {EOL})					{
													currentIndent=0;handleINDENT();
													return HyphenMinusHyphenMinusHyphenMinus;
												}
{INDENT}? [\-] ([\ ]+ [^\'\"#\r\n]+)? / ( ":" ([\ ] .*)? (({SL_COMMENT})? {EOL}) )
												{
													Matcher indent_matcher=INDENT.matcher(yytext());
													int firstIndent=( indent_matcher.matches()? indent_matcher.end(1):0);
													Matcher seq_start_matcher=SEQUENCE_START.matcher(yytext().substring(firstIndent));
													int secondIndent=(seq_start_matcher.matches()? seq_start_matcher.end(1):0); //although this should match always
													currentIndent=firstIndent+secondIndent;
													handleINDENT(firstIndent); //pushes a marker type INDENT, but with a lesser spread, same as first
													pushMarkerToken(currentIndent, START_OF_SEQ);			
													yypushback(yylength()-1);
													return(HyphenMinus);
												}
//Jflex expressions were not cutting it, hence match whole line
{INDENT}? [^\'\"#\-\ \r\n] [^#\r\n]+ / (({SL_COMMENT})? {EOL})  					
												{
													String text = yytext();
													Matcher indent_matcher=INDENT.matcher(text);
													int firstIndent=( indent_matcher.matches()? indent_matcher.end(1):0);
													Matcher mapMatcher = MAP_SEPERATOR.matcher(text.substring(firstIndent));
													if ( mapMatcher.find() ) {
														currentIndent=firstIndent+yycolumn;
														handleINDENT(firstIndent);//pushes a marker type INDENT, but with a lesser spread, same as first
														yypushback(yylength() - mapMatcher.start(1));
														yybegin(SEPERATOR); return RULE_KEY_STR; 
													} else if ( (yycolumn+firstIndent) >= currentIndent ) {
														int start = yycolumn;
														pushMarkerToken(start+firstIndent, START_OF_STR_INDENT); //currentIndent=yycolumn+firstIndent; handleINDENT(); done here
														int str_indent = getMultilineStringIndent();
														if ( start != yycolumn) {
															yypushback(yylength());
														} else if ((start+firstIndent) > str_indent) {
															pendingTokens.push(RULE_MARGIN,yytext().substring(0,str_indent));
															pendingTokens.push(RULE_STR,yytext().substring(str_indent,(firstIndent-str_indent)));
															yypushback(yylength() - firstIndent);
														} else if ( (start+firstIndent) == currentIndent ) {
															pendingTokens.push(RULE_MARGIN,yytext().substring(0,str_indent));
															yypushback(yylength() - firstIndent);
														}																																										
														yybegin(MIXED_STRING);
													} else {
														return RULE_STR; //catch all , so that tokenizer does not fail
													}
												}
{INDENT}? [\-] {INDENT} [^\ \r\n] / (.* (({SL_COMMENT})? {EOL}) )
												{
													Matcher indent_matcher=INDENT.matcher(yytext());
													int firstIndent=( indent_matcher.matches()? indent_matcher.end(1):0);
													Matcher seq_start_matcher=SEQUENCE_START.matcher(yytext().substring(firstIndent));
													int secondIndent=(seq_start_matcher.matches()? seq_start_matcher.end(1):0); //although this should match always
													currentIndent=firstIndent+secondIndent;
													handleINDENT(firstIndent); //pushes a marker type INDENT, but with a lesser spread, same as first
													pushMarkerToken(currentIndent, START_OF_SEQ);
													pendingTokens.push(HyphenMinus,"-");
													pendingTokens.push(RULE_HIDDEN,yytext().substring(1,secondIndent));
													yypushback(yylength()-secondIndent); //for the one char we consumed after indent and before lookahead
													yybegin(RHS_VAL);
												}
}
<INLINE_SEQUENCE, INLINE_SEQUENCE_ENTRY,INLINE_MAPPING,INLINE_MAPPING_KEY,INLINE_MAPPING_VALUE> 
{
	{INDENT}				{ return RULE_HIDDEN; }
}

"["				{  inlineCollectionsStack.push(yycharat(0));yybegin(INLINE_SEQUENCE); return LeftSquareBracket;}
"{"				{  inlineCollectionsStack.push(yycharat(0)); yybegin(INLINE_MAPPING);return LeftCurlyBracket;}   
"}" 			{ int state=getNextState(START_OF_IN_MAP); if (state!=-100) {yybegin(state);} return RightCurlyBracket;}
"]" 			{ int state=getNextState(START_OF_IN_SEQ); if (state!=-100) {yybegin(state);} return RightSquareBracket;}
{EOL} 			{  yybegin(YYINITIAL); return RULE_EOL; }
{INDENT} / {SL_COMMENT} 	{  return RULE_HIDDEN; }
{SL_COMMENT} 	{  return RULE_SL_COMMENT; }