package fronted;

import fronted.Ast.String_;
import fronted.Ast.LogicOperatorExpr;
import fronted.Ast.IfExpr;
import fronted.Ast.TernaryOperatorExpr;
import fronted.Ast.UnaryOpratorExpr;
import fronted.Ast.ReturnExpr;
import fronted.Ast.CallExpr;
import fronted.Ast.FuncExpr;
import fronted.Ast.ExprType;
import fronted.Ast.Expr;
import fronted.Ast.Program;
import fronted.Ast.AssignmentExpr;
import fronted.Ast.BinaryOpratorExpr;
import fronted.Ast.Identifier;
import fronted.Ast.Numerical;
import fronted.Ast.Stmt;
import fronted.Lexer.TokenType;
import fronted.Lexer.TokenItem;

class Parser {
	private static var tokens:Array<TokenItem>;

	private static function at(?index:Int) {
		return tokens[index == null ? 0 : index];
	}

	private static function shift():TokenItem {
		return tokens.shift();
	}

	private static function not_eof() {
		return at().type != TokenType.EOF;
	}

	private static function expect(tp:TokenType, ?msg:String):TokenItem {
		var it = shift();
		if (it.type != tp) {
			trace(it);
			if (msg == null) {
				throw "Unexpected token '" + it.value + "'";
			}
			throw msg + it.value;
		}
		return it;
	}

	public static function ast(src:String) {
		tokens = Lexer.tokenize(src);
		final program:Program = cast {
			kind: ExprType.Program,
			body: [],
		};
		while (not_eof()) {
			final expr = parse_stmt();
			if (expr != null) {
				program.body.push(expr);
			}
		}
		return program;
	}

	private static function parse_stmt():Expr {
		return parse_assignment_expr();
	}

	private static function parse_assignment_expr():Expr {
		var tt = at().type;
		if (tt == TokenType.Semic) {
			shift();
			var expr:Expr = {kind: ExprType.EndStmt,};
			return expr;
		} else if (tt == TokenType.Return) {
			shift();
			var expr_:Expr;
			if (at().type == TokenType.Identifier || at().type == TokenType.Number) {
				expr_ = parse_function_expr();
			} else {
				expr_ = {kind: ExprType.EndStmt,};
			}
			var expr:ReturnExpr = {
				kind: ExprType.ReturnExpr,
				value: expr_
			}
			return expr;
		} else {
			var isIdentifier = tt == TokenType.Identifier;
			if (isIdentifier || tt == TokenType.Dim) {
				var isDim = false;
				if (!isIdentifier) {
					isDim = true;
					shift();
					isIdentifier = true;
				}
				if (isIdentifier) {
					if (at().type == TokenType.Function) {
						var expr:FuncExpr = cast parse_function_expr();
						expr.scope = isDim;
						return expr;
					} else if (at(1).type == TokenType.Equals) {
						var expr:Expr;
						var dimname = shift().value;
						shift();
						if (at().type == TokenType.Function) {
							shift();
							expr = parse_callbody_expr(dimname);
						} else {
							expr = cast {
								kind: ExprType.AssignmentExpr,
								name: dimname,
								value: parse_function_expr(),
								scope: isDim
							}
						}
						if (at().type == TokenType.Comma || at().type == TokenType.Semic) { // 连续赋值 a=1,b=2....
							shift();
						}
						return expr;
					}
				}
			}
		}

		return parse_();
	}

	private static function parse_():Expr {
		var tt = at().type;
		if (tt == TokenType.If) {
			shift();
			var expr:IfExpr = {
				kind: ExprType.IfExpr,
				condition: {
					kind: ExprType.UnaryOpratorExpr,
					oprator: "!",
					value: parse_function_expr(),
				},
				body: parse_block_expr(),
				elseif: null
			};
			if (at().type == TokenType.Else) {
				shift();
				if (at().type == TokenType.If) {
					expr.elseif = cast parse_();
				} else {
					expr.elseif = {
						kind: ExprType.IfExpr,
						condition: null,
						// {
						// 	kind: ExprType.UnaryOpratorExpr,
						// 	oprator: "!",
						// 	value: cast {kind: ExprType.Number, value: 1,},
						// },
						body: parse_block_expr(),
						elseif: null
					};
				}
			}
			return expr;
		}
		return parse_function_expr();
	}

	private static function parse_function_expr():Expr {
		var tt = at().type;
		if (tt == TokenType.Function) {
			shift();
			final funname = expect(TokenType.Identifier).value;
			return parse_callbody_expr(funname);
		}
		return parse_expr();
	}

	private static function parse_callbody_expr(funname:String) {
		final args:Array<String> = [];
		expect(TokenType.OpenBrace);
		if (at().type == TokenType.Identifier) {
			args.push(shift().value);
		}
		while (at().type == TokenType.Comma) {
			shift(); // 移除一个逗号
			args.push(shift().value);
		}
		expect(TokenType.CloseBrace);

		final body = parse_block_expr();

		final func:FuncExpr = {
			kind: ExprType.FuncExpr,
			name: funname,
			body: body,
			args: args,
			scope: false,
		}
		return func;
	}

	private static function parse_block_expr():Array<Expr> {
		final body:Array<Expr> = [];
		expect(TokenType.OpenBracket);
		while (at().type != TokenType.CloseBracket) {
			body.push(parse_stmt());
		}
		expect(TokenType.CloseBracket);
		return body;
	}

	private static function parse_expr():Expr {
		return parse_logic_operator_expr();
	}

	private static function parse_logic_operator_expr():Expr {
		var left:LogicOperatorExpr = cast parse_ternary_operator_expr();
		if (at().type == TokenType.LogicOperator) {
			final operator_:String = shift().value;
			if (operator_ == "&") {
				left = {
					kind: ExprType.LogicOperatorExpr,
					left: left,
					right: parse_logic_operator_expr(),
					oprator: operator_,
				};
			} else if (operator_ == "|") {
				left = {
					kind: ExprType.LogicOperatorExpr,
					left: left,
					right: parse_logic_operator_expr(),
					oprator: operator_,
				};
			} else {
				throw "错误了";
			}
		}
		return left;
	}

	private static function parse_ternary_operator_expr() {
		var left:TernaryOperatorExpr = cast parse_relational_operator_expr();
		if (at().type == TokenType.TernaryOperator) {
			shift();
			left = {
				kind: ExprType.TernaryOperatorExpr,
				left: null,
				right: parse_relational_operator_expr(),
				condition: {
					kind: ExprType.UnaryOpratorExpr,
					oprator: "!",
					value: left,
				},
			};
			shift();
			left.left = parse_relational_operator_expr();
		}
		return left;
	}

	private static function parse_relational_operator_expr() {
		var left:BinaryOpratorExpr = cast parse_additive_expr();
		if (at().type == TokenType.RelationalOprator) {
			var oprator = shift().value;
			left = {
				kind: ExprType.RelationalOperatorExpr,
				left: left,
				right: parse_additive_expr(),
				oprator: oprator
			}
		}
		return left;
	}

	private static function parse_additive_expr():Expr {
		var left:BinaryOpratorExpr = cast parse_multiply_expr();
		while ((at().value == "+" || at().value == "-")) {
			var oprator = shift().value;
			left = {
				kind: ExprType.BinaryOpratorExpr,
				left: left,
				right: parse_multiply_expr(),
				oprator: oprator
			}
		}
		return left;
	}

	private static function parse_multiply_expr() {
		var left:BinaryOpratorExpr = cast parse_unaryoprator_expr();
		while (at().type == TokenType.Oprator && (at().value == "*" || at().value == "/")) {
			var oprator = shift().value;
			left = {
				kind: ExprType.BinaryOpratorExpr,
				left: left,
				right: parse_unaryoprator_expr(),
				oprator: oprator
			}
		}
		return left;
	}

	private static function parse_unaryoprator_expr():Expr {
		if (at().value == "-") {
			var oprator = shift().value;
			var left:UnaryOpratorExpr = {
				kind: ExprType.UnaryOpratorExpr,
				value: parse_primy_expr(),
				oprator: oprator
			}
			return left;
		} else if (at().value == "!") {
			var oprator = shift().value;
			var left:UnaryOpratorExpr = {
				kind: ExprType.UnaryOpratorExpr,
				value: parse_unaryoprator_expr(),
				oprator: oprator
			}
			return left;
		}
		return parse_primy_expr();
	}

	private static function parse_primy_expr():Expr {
		var type = at().type;
		switch (type) {
			case TokenType.Number:
				var num:Numerical = {kind: ExprType.Number, value: Std.parseFloat(shift().value)}
				return num;
			case TokenType.String:
				var str:String_ = {kind: ExprType.String, value: shift().value}
				return str;
			case TokenType.Identifier:
				var str:String = shift().value;
				if (at().type == TokenType.OpenBrace) { // 调用方法
					while (at().type == TokenType.OpenBrace) {
						shift();
						var args:Array<Expr> = [];
						if (at().type != TokenType.CloseBrace) {
							args.push(parse_function_expr());
						}
						while (at().type == TokenType.Comma) {
							shift();
							args.push(parse_function_expr());
						}
						expect(TokenType.CloseBrace);
						var call:CallExpr = {
							kind: ExprType.CallExpr,
							name: str,
							args: args,
						}
						return call;
					}
				} else {
					var num:Identifier = {kind: ExprType.Identifier, symbol: str}
					return num;
				}
			case TokenType.OpenBrace:
				shift();
				var expr = parse_expr();
				expect(TokenType.CloseBrace);
				return expr;
			case TokenType.EOF:
				throw "Unexpected end of input";
			default:
				throw "Unexpected token '" + shift().value + "'";
		}
		var stmt:Expr = {kind: ExprType.EndStmt,};
		return stmt;
	}
}
