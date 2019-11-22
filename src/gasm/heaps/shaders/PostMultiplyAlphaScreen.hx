package gasm.heaps.shaders;

class PostMultiplyAlphaScreen extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture:Sampler2D;
		function fragment() {
			var color:Vec4 = texture.get(input.uv);

			if (color.a > 0.0) {
				color.rgb /= color.a;
				// So nice we apply it twice!
				// Not sure why, should only need to be applied once
				color.rgb /= color.a;
			}
			output.color = color;
		}
	}
}
