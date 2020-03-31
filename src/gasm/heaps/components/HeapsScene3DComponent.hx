package gasm.heaps.components;

import gasm.core.enums.ComponentType;
import gasm.core.math.geom.Point;
import hacksaw.core.filters.h2d.TextureShader;

class HeapsScene3DComponent extends HeapsSceneBase {
	public var scene3d:h3d.scene.Scene;

	final _passes = new Map<TextureShader, h3d.pass.ScreenFx<TextureShader>>();
	final _engine:h3d.Engine;

	var _size:Point;
	var _postProcess = false;
	var _postProcessingTexture:h3d.mat.Texture;

	public function new(scene:h3d.scene.Scene) {
		componentType = ComponentType.Model;
		scene3d = scene;
		_engine = h3d.Engine.getCurrent();
		super(scene);
	}

	public function allocPostProcessingTexture() {
		if (_postProcessingTexture == null) {
			_postProcessingTexture = new h3d.mat.Texture(_engine.width, _engine.height);
		} else if (_postProcessingTexture.width != _engine.width || _postProcessingTexture.height != _engine.height) {
			_postProcessingTexture.resize(_engine.width, _engine.height);
		}
	}

	public function render(e:h3d.Engine) {
		if (_postProcess) {
			allocPostProcessingTexture();
			_postProcessingTexture.clear(0, 0);
			_engine.pushTarget(_postProcessingTexture);
			scene3d.render(_engine);
			_engine.popTarget();
			for (pass in _passes) {
				final shader = pass.getShader(hacksaw.core.filters.h2d.TextureShader);
				shader.texture = _postProcessingTexture;
				pass.render();
				return;
			}
		} else {
			scene3d.render(_engine);
		}
	}

	public function addPostProcessingShader(shader:hacksaw.core.filters.h2d.TextureShader, ?blendMode:h3d.mat.BlendMode) {
		
		blendMode = blendMode != null ? blendMode : h3d.mat.BlendMode.Alpha;
		allocPostProcessingTexture();
		_postProcess = true;
		shader.texture = _postProcessingTexture;
		final pass = new h3d.pass.ScreenFx<hacksaw.core.filters.h2d.TextureShader>(shader);
		pass.pass.setBlendMode(blendMode);
		_passes.set(shader, pass);
	}

	public function removePostProcessingShader(shader:hacksaw.core.filters.h2d.TextureShader) {
		_postProcess = false;
		shader.texture = null;
		_passes.remove(shader);
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
