package gasm.heaps.shaders;

class Alpha extends hxsl.Shader {
	static var SRC = {
		var pixelColor:Vec4;
		@range(0, 1) @param var alpha:Float;
		function fragment() {
			pixelColor *= alpha;
		}
	}

	public function new(alpha) {
		super();
		this.alpha = alpha;
	}
}
