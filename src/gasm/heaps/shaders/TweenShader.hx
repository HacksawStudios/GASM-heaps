package gasm.heaps.shaders;

/**
	Extend if you need a shader that can be tweened.
	Override getters and setters to map to shader source params.
**/
class TweenShader extends hxsl.Shader {
	public var x(get, set):Float;
	public var y(get, set):Float;
	public var z(get, set):Float;
	public var w(get, set):Float;

	static var SRC = {}

	public function get_x():Float {
		return null;
	}

	public function get_y():Float {
		return null;
	}

	public function get_z():Float {
		return null;
	}

	public function get_w():Float {
		return null;
	}

	public function set_x(val:Float):Float {
		return null;
	}

	public function set_y(val:Float):Float {
		return null;
	}

	public function set_z(val:Float):Float {
		return null;
	}

	public function set_w(val:Float):Float {
		return null;
	}
}
