import fronted.Parser;
import runtime.Environment;
import runtime.Runtime;

class Main {
	static public function main():Void {
		var source:String = "dim x = pi + 20 dim y = 10 x + y";
		#if !js 
		source = sys.io.File.getContent("sample/sample1.nt");
		#end
		final time = haxe.Timer.stamp();
		final ast = Parser.ast(source);
		// Sys.println(ast);
		// Sys.println("----------------------------------------------");

		final env:Environment = new Environment();
		Runtime.register(env);

		final result = Runtime.excute(ast, env);
		// Sys.println("----------------------------------------------");
		trace("执行花费时间:" + Std.string(haxe.Timer.stamp() - time));
		trace(result);
	}
}
