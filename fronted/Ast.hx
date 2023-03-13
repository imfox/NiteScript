package fronted;

enum ExprType {
	Stmt;
	Program;
	Number;
	String;
	Identifier;
	FuncExpr;
	EndStmt;

	IfExpr;
	ReturnExpr;
	UnaryOpratorExpr;
	BinaryOpratorExpr;
	TernaryOperatorExpr;
	RelationalOperatorExpr;
	LogicOperatorExpr;
	AssignmentExpr;
	CallExpr;
}

typedef Stmt = {
	var kind:ExprType;
}

typedef Expr = Stmt & {}

typedef Program = Stmt & {
	var body:Array<Stmt>;
}

typedef Numerical = Expr & {
	var value:Float;
}

typedef String_ = Expr & {
	var value:String;
}

typedef Identifier = Expr & {
	var symbol:String;
}

typedef UnaryOpratorExpr = Expr & {
	var value:Expr;
	var oprator:String;
}

typedef BinaryOpratorExpr = Expr & {
	var left:Expr;
	var right:Expr;
	var oprator:String;
}

typedef TernaryOperatorExpr = Expr & {
	var condition:UnaryOpratorExpr;
	var left:Expr;
	var right:Expr;
}

typedef IfExpr = Expr & {
	var condition:UnaryOpratorExpr;
	var body:Array<Expr>;
	var elseif:IfExpr;
}

typedef RelationalOperatorExpr = Expr & {
	var left:Expr;
	var right:Expr;
	var oprator:String;
}

typedef LogicOperatorExpr = Expr & {
	var left:Expr;
	var right:Expr;
	var oprator:String;
}

typedef AssignmentExpr = Expr & {
	var name:String;
	var value:Expr;
	var scope:Bool;
}

typedef FuncExpr = Expr & {
	var name:String;
	var args:Array<String>;
	var body:Array<Expr>;
	var scope:Bool;
}

typedef CallExpr = Expr & {
	var name:String;
	var args:Array<Expr>;
}

typedef ReturnExpr = Expr & {
	var value:Expr;
}
