package gasm.heaps.shaders;

class PostMultiplyAlphaScreen extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture:Sampler2D;
		function fragment() {
			var color:Vec4 = texture.get(input.uv);

			if (color.a > 0.0) {
				color.rgb /= pow(color.a, 2.2);
			}
			output.color = color;
		}
	}
}
