package gasm.heaps.shaders;

class PostMultiplyAlphaScreen extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture:Sampler2D;
		function fragment() {
			var color:Vec4 = texture.get(input.uv);
			color.rgb /= mix(1.0, pow(color.a, 2.2), ceil(color.a));
			output.color = color;
		}
	}
}
