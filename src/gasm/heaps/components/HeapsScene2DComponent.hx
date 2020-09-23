package gasm.heaps.components;

import gasm.core.components.LayoutComponent;
import gasm.core.enums.ComponentType;
import gasm.core.math.geom.Point;
import gasm.heaps.components.HeapsSceneBase;
import gasm.heaps.components.actor.render.BasicChainComponent;
import gasm.heaps.components.actor.render.PostProcessingComponent;
import gasm.heaps.shaders.PostProcessingShaderBase;
import hacksaw.core.filters.h2d.TextureShader;

class HeapsScene2DComponent extends HeapsSceneBase {
	public var scene2d:h2d.Scene;

	final _engine:h3d.Engine;
	var _passes = new Array<PostProcessingPassConfig>();
	var _size:Point;
	var _postProcessingTexture:h3d.mat.Texture;
	var _textureRender = false;
	var _texturePasses = new Map<TextureShader, h3d.pass.ScreenFx<TextureShader>>();

	public function new(scene:h2d.Scene) {
		componentType = ComponentType.Model;
		this.scene2d = scene;
		_engine = h3d.Engine.getCurrent();
		super(scene);
	}

	public function render(e:h3d.Engine) {
		if (_textureRender) {
			if (_size == null || (_engine.width != _size.x || _engine.height != _size.y)) {
				_postProcessingTexture = new h3d.mat.Texture(_engine.width, _engine.height);
				_size = {x: _engine.width, y: _engine.height};
			} else {
				_postProcessingTexture.clear(0, 0);
			}

			_engine.pushTarget(_postProcessingTexture);
			scene2d.render(_engine);
			_engine.popTarget();
			for (pass in _texturePasses) {
				final shader = pass.getShader(hacksaw.core.filters.h2d.TextureShader);
				shader.texture = _postProcessingTexture;
				pass.render();
			}
		} else {
			final postProcessor = owner.get(PostProcessingComponent);
			if (postProcessor != null) {
				postProcessor.render(engine -> scene2d.render(engine));
			} else {
				scene2d.render(e);
			}
		}
	}

	/**
		Add a postprocessing shader.

		@param shader Shader to add
		@param blendMode Blend mode to use
	**/
	public function addPostProcessingShader(shader:PostProcessingShaderBase, ?blendMode:h3d.mat.BlendMode) {
		_passes.push({
			shader: shader,
			blendMode: blendMode,
			textureInput: [TextureInput.COLOR => TextureSource.LastPass(0)]
		});
		updateChainComponent();
	}

	/**
		Add a postprocessing shader that renders to an internal texture instead of using postprocessing chains.
		Using addPostProcessingShader is preferred, but can cause issues with alpha blending.

		@param shader Shader to add
		@param blendMode Blend mode to use
	**/
	public function addPostProcessingTextureShader(shader:hacksaw.core.filters.h2d.TextureShader, ?blendMode:h3d.mat.BlendMode) {
		blendMode = blendMode != null ? blendMode : h3d.mat.BlendMode.AlphaAdd;

		allocPostProcessingTexture();

		_textureRender = true;
		shader.texture = _postProcessingTexture;
		final pass = new h3d.pass.ScreenFx<hacksaw.core.filters.h2d.TextureShader>(shader);
		pass.pass.setBlendMode(blendMode);
		_texturePasses.set(shader, pass);
	}

	/**
		Remove a post processing shader added with addPostProcessingShader

		@param shader Shader to remove
	**/
	public function removePostProcessingShader(shader:PostProcessingShaderBase) {
		_passes = _passes.filter(p -> p.shader != shader);
		updateChainComponent();
	}

	/**
		Remove a post processing shader added with addPostProcessingTextureShader

		@param shader Shader to remove
	**/
	public function removePostProcessingTextureShader(shader:hacksaw.core.filters.h2d.TextureShader) {
		_textureRender = false;
		shader.texture = null;
		_texturePasses.remove(shader);
	}

	inline function allocPostProcessingTexture() {
		if (_postProcessingTexture == null) {
			_postProcessingTexture = new h3d.mat.Texture(_engine.width, _engine.height);
		} else if (_postProcessingTexture.width != _engine.width || _postProcessingTexture.height != _engine.height) {
			_postProcessingTexture.resize(_engine.width, _engine.height);
		}
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
}
