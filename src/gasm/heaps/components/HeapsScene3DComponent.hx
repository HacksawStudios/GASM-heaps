package gasm.heaps.components;

import gasm.core.enums.ComponentType;
import gasm.core.math.geom.Point;
import hacksaw.core.components.actor.render.BasicChainComponent;
import hacksaw.core.components.actor.render.PostProcessingComponent;
import hacksaw.core.h3d.shaders.postprocessing.PostProcessingShaderBase;

using Lambda;

class HeapsScene3DComponent extends HeapsSceneBase {
	public var scene3d:h3d.scene.Scene;

	final _engine:h3d.Engine;

	var _passes = new Array<PostProcessingPassConfig>();

	public function new(scene:h3d.scene.Scene) {
		componentType = ComponentType.Model;
		scene3d = scene;
		_engine = h3d.Engine.getCurrent();
		super(scene);
	}

	public function render(e:h3d.Engine) {
		final postProcessor = owner.get(PostProcessingComponent);
		if (postProcessor != null) {
			postProcessor.render(engine -> scene3d.render(engine));
		} else {
			scene3d.render(e);
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
			owner.add(new BasicChainComponent(_passes));
		}
	}

	public function removePostProcessingShader(shader:PostProcessingShaderBase) {
		_passes = _passes.filter(p -> p.shader != shader);
		updateChainComponent();
	}

	public function syncCamera() {
		var t = _engine.getCurrentTarget();
		if (t == null) {
			scene3d.camera.screenRatio = _engine.width / _engine.height;
		} else {
			scene3d.camera.screenRatio = t.width / t.height;
		}
		scene3d.camera.update();
	}
}
