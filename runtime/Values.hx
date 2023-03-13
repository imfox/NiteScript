package runtime;

import fronted.Ast.Stmt;

typedef RuntimeVal = {
	var type:String;
}

typedef NullVal = RuntimeVal & {
	var value:String;
}

typedef BooleanVal = RuntimeVal & {
	var value:Bool;
}

typedef NumberVal = RuntimeVal & {
	var value:Float;
}

typedef StringVal = RuntimeVal & {
	var value:String;
}

typedef FuncVal = RuntimeVal & {
	var body:Array<Stmt>;
	var params:Array<String>;
}

typedef NativeFuncVal = RuntimeVal & {
	var fun:(val:Array<RuntimeVal>) -> RuntimeVal;
}
