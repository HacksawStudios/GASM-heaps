package gasm.heaps.shaders;

class Tint extends hxsl.Shader {
	static var SRC = {
		var pixelColor:Vec4;
		@range(0, 1) @param var tint:Float;
		@param var color:Vec4;
		function fragment() {
			pixelColor = pixelColor + (color * tint) * pixelColor.a;
		}
	}

	public function new(color, tint = 1.0) {
		super();
		this.color.setColor(color);
		this.tint = tint;
	}
}
