package gasm.heaps.shaders;

class PostProcessingShaderBase extends h3d.shader.ScreenShader {
	static var SRC = {
		// Standard texture inputs
		@param var colorMap:Sampler2D;
		@param var colorMap2:Sampler2D;
		@param var normalMap:Sampler2D;
		@param var depthMap:Sampler2D;
		@param var noiseMap:Sampler2D;
		@param var resolution:Vec2;
		@param var time:Float;
		function fragment() {
			output.color = colorMap.get(input.uv);
		}
	};
}
