package fronted;

import haxe.ds.Map;

enum TokenType {
	RelationalOprator;
	Oprator;
	Identifier;
	String;
	Number;
	Equals; // =
	Dim;
	OpenBrace; // (
	CloseBrace; // )
	OpenBracket; // {
	CloseBracket; // }
	Function;
	Comma; // ,
	Semic; // ;
	Dot; // .
	Return;
	Not; // !
	If;
	Else;
	TernaryOperator; // ?
	LogicOperator; // && ||
	BitOperator; // & |
	Nil;
	True;
	False;
	EOF;
}

typedef TokenItem = {
	var type:TokenType;
	var value:String;
}

class Lexer {
	private static function token(type:TokenType, value:String):TokenItem {
		return {
			type: type,
			value: value,
		};
	}

	private static function isint(s:String, ?dot:Bool) {
		if (dot != true && s == ".")
			return true;

		var code = s.charCodeAt(0);
		return code >= "0".charCodeAt(0) && code <= "9".charCodeAt(0);
	}

	private static function isascii(s:String) {
		return s.toLowerCase() != s.toUpperCase() || s == "_";
	}

	private static function isskipchar(s:String) {
		return s == "\t" || s == "\n" || s == "\r" || s == " " || s == ";";
	}

	private static function issymbol(s:String) {
		if (s == "(" || s == ")") {
			return true;
		} else if (s == "{" || s == "}") {
			return true;
		} else if (s == "[" || s == "]") {
			return true;
		} else if (s == ";" || s == "," || s == "." || s == ":") {
			return true;
		} else if (s == "=") {
			return true;
		} else if (s == ">" || s == "<" || s == "?") {
			return true;
		}
		return false;
	}

	private static function isclose(s:String) {
		return s == "}" || s == ")" || s == "]" || s == ";" || s == ",";
	}

	private static final KEY_WORDS:Map<String, TokenType> = [
		"dim" => TokenType.Dim,
		"fn" => TokenType.Function,
		"return" => TokenType.Return,
		"nil" => TokenType.Identifier,
		"if" => TokenType.If,
		"else" => TokenType.Else,
		// "false" => TokenType.Identifier,
		// "true" => TokenType.Identifier,
	];

	public static function tokenize(source:String):Array<TokenItem> {
		var tks:Array<TokenItem> = [];
		final chars = source.split("");
		while (chars.length > 0) {
			if (chars[0] == "+" || chars[0] == "-" || chars[0] == "*" || chars[0] == "/") {
				final char = chars.shift();
				if (chars[0] == "/") {
					while (chars.length > 0 && chars[0] != "\r" && chars[0] != "\n") {
						chars.shift();
					}
					continue;
				}
				tks.push(token(TokenType.Oprator, char));
			} else if (chars[0] == "?" || chars[0] == ":") {
				tks.push(token(TokenType.TernaryOperator, chars.shift()));
			} else if (chars[0] == ">" || chars[0] == "<") {
				tks.push(token(TokenType.RelationalOprator, chars.shift()));
			} else if (chars[0] == "=") {
				chars.shift();
				if (chars[0] == "=") {
					chars.shift();
					tks.push(token(TokenType.RelationalOprator, "="));
				} else {
					tks.push(token(TokenType.Equals, "="));
				}
			} else if (chars[0] == "(") {
				tks.push(token(TokenType.OpenBrace, chars.shift()));
			} else if (chars[0] == ")") {
				tks.push(token(TokenType.CloseBrace, chars.shift()));
			} else if (chars[0] == ".") {
				tks.push(token(TokenType.Dot, chars.shift()));
			} else if (chars[0] == ",") {
				tks.push(token(TokenType.Comma, chars.shift()));
			} else if (chars[0] == "{") {
				tks.push(token(TokenType.OpenBracket, chars.shift()));
			} else if (chars[0] == "}") {
				tks.push(token(TokenType.CloseBracket, chars.shift()));
			} else if (chars[0] == "}") {
				tks.push(token(TokenType.CloseBracket, chars.shift()));
			} else if (chars[0] == "!") {
				tks.push(token(TokenType.Not, chars.shift()));
			} else if (chars[0] == ";") {
				tks.push(token(TokenType.Semic, chars.shift()));
			} else if (chars[0] == "|") {
				chars.shift();
				if (chars[0] == "|") {
					chars.shift();
					tks.push(token(TokenType.LogicOperator, "|"));
				} else {
					tks.push(token(TokenType.BitOperator, "|"));
				}
			} else if (chars[0] == "&") {
				chars.shift();
				if (chars[0] == "&") {
					chars.shift();
					tks.push(token(TokenType.LogicOperator, "&"));
				} else {
					tks.push(token(TokenType.BitOperator, "&"));
				}
			} else {
				if (isint(chars[0])) {
					var str = "";
					var dot = false;
					while (chars.length > 0 && isint(chars[0], dot)) {
						dot = dot ? true : chars[0] == ".";
						str += chars.shift();
					}

					if (chars.length > 0 && isascii(chars[0])) {
						throw "Uncaught SyntaxError: Unexpected token '" + chars[0] + "'";
					}
					tks.push(token(TokenType.Number, str));
				} else if (isascii(chars[0])) {
					var str = "";
					while (chars.length > 0 && (isascii(chars[0]) || isint(chars[0]))) {
						str += chars.shift();
					}
					if (chars.length > 0 && !(isskipchar(chars[0]) || issymbol(chars[0]))) {
						throw "Uncaught SyntaxError: Unexpected token '" + chars[0] + "'";
					}
					var tt = KEY_WORDS[str];
					if (tt == null) {
						tks.push(token(TokenType.Identifier, str));
					} else {
						tks.push(token(tt, str));
					}
				} else if (chars[0] == '"') {
					chars.shift();
					var str = "";
					while (chars.length > 0 && chars[0] != '"') {
						str += chars.shift();
					}
					chars.shift();
					if (chars.length > 0 && !(isskipchar(chars[0]) || issymbol(chars[0]))) {
						throw "Uncaught SyntaxError: Unexpected token '" + chars[0] + "'";
					}
					tks.push(token(TokenType.String, str));
				} else if (isskipchar(chars[0])) {
					chars.shift();
				} else {
					trace(chars[0]);
					throw_("无法识别的内容");
				}
			}
		}
		tks.push(token(EOF, "EOF"));
		return tks;
	}

	public static function throw_(err:String) {
		// Sys.println(err);
		throw "";
	}
}
