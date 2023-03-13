package runtime;

import runtime.Values.RuntimeVal;

class Environment {
	public var scope:Environment;

	private var parent:Environment;
	private var dims:Map<String, RuntimeVal>;

	public function new(?parent:Environment) {
		dims = new Map();
		if (parent == null) {
			this.scope = this;
		} else {
			this.parent = parent;
			this.scope = parent.scope;
		}
	}

	public function assignment(name:String, value:RuntimeVal) {
		dims.set(name, value);
	}

	public function resolve(name:String):RuntimeVal {
		var val = this.dims[name];
		if (val != null)
			return val;
		if (this.parent != null)
			return this.parent.resolve(name);
		return null;
	}
}
