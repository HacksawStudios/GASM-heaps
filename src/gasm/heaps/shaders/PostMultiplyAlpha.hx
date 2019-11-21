package gasm.heaps.shaders;

class PostMultiplyAlpha extends hxsl.Shader {
	static var SRC = {
		var pixelColor:Vec4;
		function fragment() {
			if (pixelColor.a > 0.0) {
				pixelColor.rgb /= pixelColor.a;
			}
		}
	}

	public function new() {
		super();
	}
}
