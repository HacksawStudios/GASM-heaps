package gasm.heaps.components;

import gasm.core.components.LayoutComponent;
import gasm.core.enums.ComponentType;
import gasm.core.math.geom.Point;
import gasm.heaps.components.HeapsSceneBase;
import hacksaw.core.components.actor.render.BasicChainComponent;
import hacksaw.core.components.actor.render.PostProcessingComponent;
import hacksaw.core.h3d.shaders.postprocessing.PostProcessingShaderBase;

class HeapsScene2DComponent extends HeapsSceneBase {
	public var scene2d:h2d.Scene;

	var _passes = new Array<PostProcessingPassConfig>();
	var _size:Point;

	public function new(scene:h2d.Scene) {
		componentType = ComponentType.Model;
		this.scene2d = scene;
		super(scene);
	}

	public function render(e:h3d.Engine) {
		final postProcessor = owner.get(PostProcessingComponent);
		if (postProcessor != null) {
			postProcessor.render(engine -> scene2d.render(engine));
		} else {
			scene2d.render(e);
		}
	}

	public function addPostProcessingShader(shader:PostProcessingShaderBase, ?blendMode:h3d.mat.BlendMode) {
		_passes.push({
			shader: shader,
			blendMode: blendMode,
			textureInput: [TextureInput.COLOR => TextureSource.LastPass(0)]
		});
		updateChainComponent();
	}

	function updateChainComponent() {
		final existingChain = owner.get(BasicChainComponent);
		if (existingChain != null) {
			owner.remove(existingChain);
		}
		if (_passes.length != 0) {
			final chainComponent = new BasicChainComponent(_passes);
		}
	}

	public function removePostProcessingShader(shader:PostProcessingShaderBase) {
		var remove = [];
		_passes = _passes.filter(p -> p.shader != shader);
		updateChainComponent();
	}
}
