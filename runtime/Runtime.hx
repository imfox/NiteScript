package runtime;

import fronted.Ast.String_;
import fronted.Parser;
import fronted.Ast.IfExpr;
import fronted.Ast.TernaryOperatorExpr;
import fronted.Ast.LogicOperatorExpr;
import fronted.Ast.UnaryOpratorExpr;
import runtime.Values.StringVal;
import fronted.Ast.ReturnExpr;
import runtime.Values.FuncVal;
import fronted.Ast.Stmt;
import fronted.Ast.FuncExpr;
import runtime.Values.NativeFuncVal;
import fronted.Ast.CallExpr;
import fronted.Ast.Identifier;
import runtime.Values.BooleanVal;
import runtime.Values.NumberVal;
import fronted.Ast.Numerical;
import runtime.Values.RuntimeVal;
import runtime.Values.NullVal;
import fronted.Ast.Expr;
import fronted.Ast.Program;
import fronted.Ast.AssignmentExpr;
import fronted.Ast.BinaryOpratorExpr;
import fronted.Ast.ExprType;

class Runtime {
	public static function register(env:Environment) {
		env.assignment("pi", MK_NUMBER(3.1415926));
		env.assignment("nil", MK_NIL());
		env.assignment("add", MK_NITIVE_FUNC((values:Array<NumberVal>) -> {
			var sum:Float = 0;
			for (item in values) {
				sum += item.value;
			}
			return MK_NUMBER(sum);
		}));
		env.assignment("typeof", MK_NITIVE_FUNC((values:Array<RuntimeVal>) -> {
			var item:RuntimeVal = values[0];
			if (item == null || item.type == "nil") {
				return MK_STRING("nil");
			} else {
				return MK_STRING(item.type);
			}
			return MK_NIL();
		}));
		env.assignment("eval", MK_NITIVE_FUNC((values:Array<StringVal>) -> {
			var item:StringVal = values[0];
			if (item == null) {
				return MK_NIL();
			} else if (item.type == "string") {
				return cast excute(Parser.ast(item.value), env.scope);
			}
			return item;
		}));
		env.assignment("print", MK_NITIVE_FUNC((values:Array<RuntimeVal>) -> {
			var str:String = "";
			final len = values.length;
			for (i in 0...len) {
				final item = values[i];
				if (i > 0)
					str += "\t";
				if (item == null || item.type == "nil") {
					str += "nil";
				} else if (item.type == "number") {
					final nv:NumberVal = cast item;
					str += Std.string(nv.value);
				} else if (item.type == "string") {
					final nv:StringVal = cast item;
					str += nv.value;
				} else if (item.type == "bool") {
					final nv:BooleanVal = cast item;
					str += nv.value ? "true" : "false";
				} else if (item.type == "function") {
					str += "function";
				} else if (item.type == "native-func") {
					str += "native-func";
				}
			}
			#if !js 
			Sys.println(str);
			#else
			trace(str);
			#end
			return MK_NIL();
		}));
		env.assignment("floor", MK_NITIVE_FUNC((values:Array<RuntimeVal>) -> {
			var value = values[0];
			if (values != null) {
				if (value.type == "number") {
					var nv:NumberVal = cast value;
					return cast MK_NUMBER(Std.int(nv.value));
				} else if (value.type == "string") {
					// var nv:NumberVal = cast value;
					// return MK_NUMBER(Std.parseInt(values[0].value));
				}
			}
			return MK_NIL();
		}));
	}

	public static function excute(pr:Program, env:Environment):RuntimeVal {
		var val:RuntimeVal = MK_NIL();
		while (pr.body.length > 0) {
			val = evaluate(pr.body.shift(), env);
		}
		return val;
	}

	public static function evaluate(expr:Expr, env:Environment):RuntimeVal {
		if (expr.kind == ExprType.Number) {
			var e:Numerical = cast expr;
			return MK_NUMBER(e.value);
		} else if (expr.kind == ExprType.String) {
			var e:String_ = cast expr;
			return MK_STRING(e.value);
		} else if (expr.kind == ExprType.Identifier) {
			var e:Identifier = cast expr;
			return env.resolve(e.symbol);
		} else if (expr.kind == ExprType.AssignmentExpr) {
			return evalAssignment(cast expr, env);
		} else if (expr.kind == ExprType.UnaryOpratorExpr) {
			return unaryOprator(cast expr, env);
		} else if (expr.kind == ExprType.BinaryOpratorExpr) {
			return evalOprator(cast expr, env);
		} else if (expr.kind == ExprType.TernaryOperatorExpr) {
			return TernaryOperator(cast expr, env);
		} else if (expr.kind == ExprType.RelationalOperatorExpr) {
			return RelationalOperator(cast expr, env);
		} else if (expr.kind == ExprType.LogicOperatorExpr) {
			return LogicOperator(cast expr, env);
		} else if (expr.kind == ExprType.IfExpr) {
			return If(cast expr, env);
		} else if (expr.kind == ExprType.CallExpr) {
			return evalNativefunc(cast expr, env);
		} else if (expr.kind == ExprType.FuncExpr) {
			return evalFunction(cast expr, env);
		} else if (expr.kind == ExprType.ReturnExpr) {
			var e:ReturnExpr = cast expr;
			if (env.scope == env) {
				throw "错误的返回";
			}
			return evaluate(e.value, env);
		} else if (expr.kind == ExprType.EndStmt) {
			return MK_NIL();
		} else {
			trace(expr);
			throw "无法识别的语句";
		}
		return MK_NIL();
	}

	private static function LogicOperator(expr:LogicOperatorExpr, env:Environment):RuntimeVal {
		final a:NumberVal = cast evaluate(expr.left, env);
		if (expr.oprator == "&") {
			if (a == null || a.type == "nil") {} else {
				final b:NumberVal = cast evaluate(expr.right, env);
				if (a.type == "number" && a.type == b.type) {
					if (a.value == 0 || b.value == 0) {
						return MK_NUMBER(0);
					}
					return b;
				} else if (a.type == "string" && a.type == b.type) {
					return b;
				}
			}
		} else if (expr.oprator == "|") {
			if (a.type == "number" && a.value != 0) {
				return a;
			}
			return cast evaluate(expr.right, env);
		}
		return MK_NIL();
	}

	private static function If(expr:IfExpr, env:Environment) {
		final condition:BooleanVal = cast evaluate(expr.condition, env);
		if (!condition.value) {
			for (stmt in expr.body) {
				evaluate(stmt, env);
			}
		} else if (expr.elseif != null) {
			if (expr.elseif.condition == null) {
				for (stmt in expr.elseif.body) {
					evaluate(stmt, env);
				}
			} else {
				return If(expr.elseif, env);
			}
		}
		return MK_NIL();
	}

	public static function TernaryOperator(expr:TernaryOperatorExpr, env:Environment) {
		final condition:BooleanVal = cast evaluate(expr.condition, env);
		if (condition.value) {
			return evaluate(expr.left, env);
		}
		return evaluate(expr.right, env);
	}

	private static function RelationalOperator(expr:LogicOperatorExpr, env:Environment):RuntimeVal {
		final a:NumberVal = cast evaluate(expr.left, env);
		final b:NumberVal = cast evaluate(expr.right, env);
		if (expr.oprator == ">") {
			if (a.type == "number" && a.type == b.type) {
				return MK_BOOL(a.value > b.value);
			}
		} else if (expr.oprator == "<") {
			if (a.type == "number" && a.type == b.type) {
				return MK_BOOL(a.value < b.value);
			}
		} else if (expr.oprator == "=") {
			if (a.type == "number" && a.type == b.type) {
				return MK_BOOL(a.value == b.value);
			}
		}
		return MK_BOOL(false);
	}

	private static function unaryOprator(expr:UnaryOpratorExpr, env:Environment):RuntimeVal {
		if (expr.oprator == "-") {
			var val:NumberVal = cast evaluate(expr.value, env);
			if (val.type == "number") {
				return MK_NUMBER(-val.value);
			} else if (val.type == "string") {
				return MK_NUMBER(-Std.parseFloat(cast val.value));
			}
		} else if (expr.oprator == "!") {
			var val:NumberVal = cast evaluate(expr.value, env);
			if (val == null) {
				return MK_BOOL(true);
			} else if (val.type == "number") {
				return MK_BOOL(val.value == 0);
			} else if (val.type == "bool") {
				return MK_BOOL(!(cast val.value));
			}
			return MK_BOOL(true);
		} else {
			throw "无法识别的一元运算符";
		}
		return MK_NIL();
	}

	private static function evalFunction(expr:FuncExpr, env:Environment):RuntimeVal {
		if (expr.scope) {
			env.scope.assignment(expr.name, MK_FUNC(expr.args, expr.body));
		} else {
			env.assignment(expr.name, MK_FUNC(expr.args, expr.body));
		}
		return MK_NIL();
	}

	public static function evalNativefunc(expr:CallExpr, env:Environment):RuntimeVal {
		final val:NativeFuncVal = cast env.resolve(expr.name);
		if (val == null) {
			throw expr.name + " is not defined";
		} else if (val.type == "native-func") {
			final values:Array<RuntimeVal> = [];
			for (expr_ in expr.args) {
				values.push(evaluate(expr_, env));
			}
			return val.fun(values);
		} else if (val.type == "function") {
			final fun:FuncVal = cast val;
			final env_ = new Environment(env);
			if (fun.params.length > 0) {
				final values:Array<RuntimeVal> = [];
				for (expr_ in expr.args) {
					values.push(evaluate(expr_, env));
				}
				for (i in 0...values.length) {
					env_.assignment(fun.params[i], values[i]);
				}
			}
			var retVal:RuntimeVal = MK_NIL();
			for (stmt in fun.body) {
				retVal = evaluate(stmt, env_);
				if (stmt.kind == ExprType.ReturnExpr) {
					// throw "返回语句后不应该有其他语句";
					break;
				}
			}
			return retVal;
		}
		return MK_NIL();
	}

	public static function evalOprator(expr:BinaryOpratorExpr, env:Environment):RuntimeVal {
		final a:NumberVal = cast evaluate(expr.left, env);
		final b:NumberVal = cast evaluate(expr.right, env);
		if (expr.oprator == "+") {
			return MK_NUMBER(a.value + b.value);
		} else if (expr.oprator == "-") {
			return MK_NUMBER(a.value - b.value);
		} else if (expr.oprator == "*") {
			return MK_NUMBER(a.value * b.value);
		} else if (expr.oprator == "/") {
			return MK_NUMBER(a.value / b.value);
		}
		return MK_NIL();
	}

	public static function evalAssignment(expr:AssignmentExpr, env:Environment) {
		var val:RuntimeVal = expr.value == null ? MK_NIL() : evaluate(expr.value, env);
		if (expr.scope) {
			env.scope.assignment(expr.name, val);
		} else {
			env.assignment(expr.name, val);
		}
		return val; // MK_NIL();
	}

	public static function MK_NIL() {
		var nil:NullVal = {value: null, type: "nil"};
		return nil;
	}

	public static function MK_STRING(str) {
		var nil:StringVal = {value: str, type: "string"};
		return nil;
	}

	public static function MK_BOOL(b:Bool) {
		var bool:BooleanVal = {value: b, type: "bool"};
		return bool;
	}

	public static function MK_NUMBER(number:Float) {
		var val:NumberVal = {value: number, type: "number"};
		return val;
	}

	public static function MK_NITIVE_FUNC(fun:Dynamic) {
		var val:NativeFuncVal = {type: "native-func", fun: fun};
		return val;
	}

	private static function MK_FUNC(params:Array<String>, body:Array<Stmt>) {
		var val:FuncVal = {type: "function", body: body, params: params};
		return val;
	}
}
