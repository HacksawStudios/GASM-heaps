package gasm.heaps.components.actor.render;

import gasm.core.Component;
import gasm.core.enums.ComponentType;
import gasm.core.utils.Assert;
import gasm.heaps.components.HeapsScene3DComponent;
import gasm.heaps.shaders.PostProcessingShaderBase;
import h3d.Engine;
import h3d.mat.BlendMode;
import h3d.mat.Data.TextureFormat;
import h3d.mat.Data.Wrap;
import h3d.mat.DepthBuffer;
import h3d.mat.Texture;
import h3d.pass.ScreenFx;
import h3d.scene.Object;
import haxe.ds.IntMap;

using Safety;

/**
	The PostProcessingComponent creates a post processing pipeline.
	PostProcessingChainComponents will be picked up from owner and used for rendering.
	If no chain is supplied, a standard chain is set.
	The render-stage needs to be manually called before any rendering can happen.
**/
class PostProcessingComponent extends Component {
	// These variables are globally unique ensuring chains can be passed between postprocessors
	static final _passes = new IntMap<PostProcessingPass>();
	static final _chains = new IntMap<Array<Int>>();
	static final _noiseTextures = new IntMap<h3d.mat.Texture>();
	static var _id = 0;

	final _config:PostProcessingComponentConfig;
	var _activeChainComponent:PostProcessingChainComponent = null;
	var _lastUpdatedChainComponent:PostProcessingChainComponent = null;
	var _baseTexture:h3d.mat.Texture = null;
	var _enabled = true;

	final _defaultChain:Int = null;
	var _dt = 0.0;

	public function new(config:PostProcessingComponentConfig) {
		_config = config;
		componentType = ComponentType.Actor;

		if (_config.defaultChain != null) {
			var passes = [];
			for (cfg in _config.defaultChain) {
				passes.push(createPass(cfg));
			}
			_defaultChain = createChain(passes);
		} else {
			_defaultChain = createDefaultChain();
		}
	}

	override public function update(dt:Float) {
		final engine = Engine.getCurrent();
		_dt = dt;
		if (_baseTexture == null) {
			return;
		}

		// In case we are rendering to a scene, we need to set the blendMode for alpha a bit differently
		// because when rendering to an empty backbuffer, the equation needs to change to preserve the alpha values correctly
		final scene3d = owner.get(HeapsScene3DComponent);
		if (scene3d != null) {
			final materials = scene3d.scene3d.getMaterials();
			for (mat in materials) {
				switch (mat.blendMode) {
					case Alpha:
						mat.mainPass.blendSrc = SrcAlpha;
						mat.mainPass.blendDst = OneMinusSrcAlpha;
						mat.mainPass.blendAlphaSrc = OneMinusDstAlpha;
						mat.mainPass.blendAlphaDst = One;
					default:
				}
			}
		}
	}

	/**
		Create a a pass
		@param config Configuration for this pass
		@return unique id for this pass
	**/
	public function createPass(config:PostProcessingPassConfig):Int {
		final pass = new PostProcessingPass(config);
		_passes.set(_id, pass);
		return _id++;
	}

	/**
		Create a chain from a set of pass-ids
		@param passes Array of pass-ids
		@return Int id of chain
	**/
	public function createChain(passes:Array<Int>):Int {
		_chains.set(_id, passes);
		return _id++;
	}

	/**
		Destroys a chain and dispose shaders
		@param chainId id of chain
	**/
	public function destroyChain(chainId):Void {
		final passes = _chains.get(chainId);
		_chains.remove(chainId);
		for (passId in passes) {
			final pass = _passes.get(passId);
			pass.dispose();
			_passes.remove(passId);
		}
	}

	/**
		Render the postprocessing chain, ending up on the canvas
		@param baseRender All thing rendered inside this function will be rendered to the first stage of the pipeline
	**/
	public function render(baseRender:(engine:h3d.Engine) -> Void):Void {
		final engine = Engine.getCurrent();

		// No base texture yet created
		if (_baseTexture == null) {
			_baseTexture = new h3d.mat.Texture(engine.width, engine.height, [Target]);
			_baseTexture.depthBuffer = new DepthBuffer(engine.width, engine.height, DepthFormat.Depth24Stencil8);
		} else if (_baseTexture.width != engine.width || _baseTexture.height != engine.height) {
			_baseTexture.depthBuffer.dispose();
			_baseTexture.dispose();
			_baseTexture = new h3d.mat.Texture(engine.width, engine.height, [Target]);
			_baseTexture.depthBuffer = new DepthBuffer(engine.width, engine.height, DepthFormat.Depth24Stencil8);
		}

		final chain = updateAndGetChain(engine, _dt);

		// Make initial render
		engine.pushTarget(_baseTexture);
		engine.clear(0x0, 1, 0x0);
		baseRender(engine);
		engine.popTarget();

		for (i in 0...chain.length) {
			final passInstance = _passes.get(chain[i]);
			final isLast = i == chain.length - 1;

			if (isLast == false) {
				if (passInstance.targets.length > 1) {
					engine.pushTargets(passInstance.targets);
				} else {
					engine.pushTarget(passInstance.targets[0]);
				}
				engine.clear(0x0);
			}

			passInstance.pass.render();

			if (isLast == false) {
				engine.popTarget();
			}
		}
	}

	function resetChain(chainId:Int) {
		final passes = _chains.get(chainId);
		for (p in passes) {
			_passes.get(p).reset();
		}
	}

	function updateAndGetChain(engine:h3d.Engine, dt:Float):Array<Int> {
		// Detect active chain component
		// Tell chain about it's activation and deactivation
		var newChainComponent = owner.get(PostProcessingChainComponent);

		// Ignore new chain component until it is inited
		if (newChainComponent != null && !newChainComponent.inited) {
			newChainComponent = _activeChainComponent;
		}

		if (newChainComponent != _activeChainComponent) {
			if (newChainComponent != null) {
				resetChain(newChainComponent.chainId);
				newChainComponent.onEnabled();
			}

			if (_activeChainComponent != null) {
				_activeChainComponent.onDisabled();
			}
		}

		_activeChainComponent = newChainComponent;

		// Use default if active chain is null or it hasn't been updated yet
		final useDefault = _activeChainComponent == null
			|| (_activeChainComponent != null && _lastUpdatedChainComponent != _activeChainComponent);

		final chain = useDefault ? _chains.get(_defaultChain) : _chains.get(_activeChainComponent.chainId);
		_lastUpdatedChainComponent = _activeChainComponent;
		for (i in 0...chain.length) {
			final passInstance = _passes.get(chain[i]);
			passInstance.update(engine, dt);

			// update texture input parameters for this pass
			for (dst => src in passInstance.config.textureInput) {
				final texture = switch (src) {
					case Base: _baseTexture;
					case FromPass(passId, renderTarget): _passes.get(passId).targets[renderTarget];
					case External(t): t;
					case Noise(size): getNoiseTexture(size);
					case LastPass(renderTarget): {
							if (i == 0) {
								// In future, renderTarget 0 would maybe be normal maps and such
								Assert.that(renderTarget == 0,
									"PostProcessingComponent using LastPass as source for first stage only supports renderTarget 0.");
								_baseTexture;
							} else {
								final targets = _passes.get(chain[i - 1]).targets;
								Assert.that(targets.length > renderTarget, "PostProcessingComponent using LastPass trying to get unavailable renderTarget");
								targets[renderTarget];
							}
						}
				}

				switch (dst) {
					case COLOR:
						passInstance.shader.colorMap = texture;
					case COLOR2:
						passInstance.shader.colorMap2 = texture;
					case NORMAL:
						passInstance.shader.normalMap = texture;
					case DEPTH:
						passInstance.shader.depthMap = texture;
					case NOISE:
						passInstance.shader.noiseMap = texture;
				}
			}
		}
		return chain;
	}

	function createDefaultChain() {
		final shader = new PostProcessingShaderBase();
		final pass = createPass({
			shader: shader,
			textureInput: [TextureInput.COLOR => TextureSource.Base]
		});
		return createChain([pass]);
	}

	function getNoiseTexture(size:Int):h3d.mat.Texture {
		if (_noiseTextures.exists(size)) {
			return _noiseTextures.get(size);
		}

		final t = h3d.mat.Texture.genNoise(size);
		t.wrap = Wrap.Repeat;
		_noiseTextures.set(size, t);
		return t;
	}

	override function get_enabled():Bool {
		return _enabled;
	}

	override function set_enabled(val:Bool) {
		return _enabled = val;
	}
}

enum TextureSource {
	/**
		Base scene texture
	**/
	Base;

	/**
		Texture from last pass in chain
	**/
	LastPass(renderTarget:Int);

	/**
		Texture from output of given pass
	**/
	FromPass(passId:Int, renderTarget:Int);

	/**
		A random generated noise texture of specified size.
	**/
	Noise(size:Int);

	/**
		An external texture supplied from other than the postprocessor
	**/
	External(t:h3d.mat.Texture);
}

enum TextureInput {
	COLOR;
	COLOR2;
	NORMAL;
	DEPTH;
	NOISE;
}

class PostProcessingPass {
	public final shader:PostProcessingShaderBase;
	public final config:PostProcessingPassConfig;
	public final pass:ScreenFx<h3d.shader.ScreenShader>;
	public final targets = new Array<h3d.mat.Texture>();

	public function new(config:PostProcessingPassConfig) {
		this.config = config;

		pass = new ScreenFx<h3d.shader.ScreenShader>(config.shader);
		pass.pass.setBlendMode(config.blendMode);
		shader = config.shader;

		for (i in 0...config.targets) {
			targets.push(null);
		}

		reset();
	}

	public function reset() {
		shader.time = 0.0;
	}

	public function dispose() {
		if (pass != null) {
			pass.dispose();
		}
	}

	public function update(e:Engine, dt:Float) {
		final w = Std.int(e.width * config.scaleX);
		final h = Std.int(e.width * config.scaleY);
		shader.time += dt * config.speed;
		shader.resolution.x = e.width;
		shader.resolution.y = e.height;
		for (i in 0...config.targets) {
			if (targets[i] == null) {
				targets[i] = new h3d.mat.Texture(w, h, [Target]);
			} else {
				if (targets[i].width != w || targets[i].height != h) {
					targets[i].resize(w, h);
				}
			}
		}
	}
}

@:structInit
class PostProcessingPassConfig {
	public var shader:PostProcessingShaderBase;
	public var textureInput:Map<TextureInput, TextureSource>;
	public var blendMode = BlendMode.AlphaAdd;
	public var targets = 1;
	public var scaleX = 1.0;
	public var scaleY = 1.0;
	public var speed = 1.0;
}

@:structInit
class PostProcessingComponentConfig {
	public var defaultChain:Array<PostProcessingPassConfig> = null;
}
