package gasm.heaps.components;

import h3d.Vector;
import h3d.col.Bounds;
import h3d.mat.BlendMode;
import h3d.mat.Texture;
import h3d.parts.GpuParticles;
import hacksaw.core.h3d.shaders.DarkToAlphaShader;

/**
	3D GPU particles component
**/
class HeapsGpuParticleComponent extends Heaps3DComponent {
	public var pos(get, set):Vector;
	public var enabled(get, set):Bool;

	final _config:GpuParticleConfig;
	var _particles:GpuParticles;
	var _enabled = true;

	public function new(config:GpuParticleConfig) {
		_config = config;
		super();
	}

	override public function init() {
		_particles = new GpuParticles(object);
		for (g in _config.groups) {
			final group = new h3d.parts.GpuParticles.GpuPartGroup(_particles);
			group.amount = g.amount;
			group.animationRepeat = g.animationRepeat;
			group.clipBounds = g.clipBounds;
			group.colorGradient = g.colorGradient;
			group.emitAngle = g.emitAngle;
			group.emitDist = g.emitDist;
			group.emitLoop = g.emitLoop;
			group.emitLoop = g.emitLoop;
			group.emitMode = g.emitMode;
			group.emitOnBorder = g.emitOnBorder;
			group.emitStartDist = g.emitStartDist;
			group.fadeIn = g.fadeIn;
			group.fadeOut = g.fadeOut;
			group.fadePower = g.fadePower;
			group.gravity = g.gravity;
			group.isRelative = g.isRelative;
			group.life = g.life;
			group.lifeRand = g.lifeRand;
			group.nparts = g.nparts;
			group.rotSpeed = g.rotSpeed;
			group.rotSpeedRand = g.rotSpeedRand;
			group.size = g.size;
			group.sizeIncr = g.sizeIncr;
			group.sizeRand = g.sizeRand;
			group.sortMode = g.sortMode;
			group.speed = g.speed;
			group.speedRand = g.speedRand;
			group.speedIncr = g.speedIncr;
			group.texture = g.texture;
			_particles.addGroup(group);
		}
		_particles.setPosition(_config.pos.x, _config.pos.y, _config.pos.z);
		_particles.setRotation(_config.direction.x, _config.direction.y, _config.direction.x);
		_particles.material.blendMode = _config.blendMode;
		_particles.volumeBounds = _config.bounds;
	}

	function get_pos() {
		return new Vector(_particles.x, _particles.y, _particles.z);
	}

	function get_enabled() {
		return _enabled;
	}

	function set_pos(val:Vector) {
		_particles.setPosition(val.x, val.y, val.z);
		return val;
	}

	function set_enabled(val:Bool) {
		for (g in _particles.getGroups()) {
			g.enable = val;
		}
		return _enabled = val;
	}
}

@:structInit
class GpuParticleConfig {
	/**
		Particle groups
	**/
	public var groups:Array<GpuParticleGroup>;

	/**
		Blend mode for particles
	**/
	public var blendMode:BlendMode = BlendMode.AlphaAdd;

	/**
		Postion of particles
	**/
	public var pos = new Vector(0, 0, 0);

	/**
		Direction of particles
	**/
	public var direction = new Vector(0, 0, 0);

	/**
		Volume bounds of particle field. If null field is boundless.
	**/
	public var bounds:Null<Bounds> = null;
}

@:structInit
class GpuParticleGroup {
	public var amount = 1.0;
	public var animationRepeat = 1.0;
	public var clipBounds = false;
	public var colorGradient:Null<Texture> = null;
	public var emitAngle = 0.5;
	public var emitDist = 2.0;
	public var emitLoop = true;
	public var emitMode:GpuEmitMode = GpuEmitMode.Point;
	public var emitOnBorder = false;
	public var emitStartDist = 0.0;
	public var fadeIn = 0.8;
	public var fadeOut = 0.8;
	public var fadePower = 1.0;
	public var gravity = 0.0;
	public var isRelative = false;
	public var life = 2.0;
	public var lifeRand = 0.5;
	public var nparts = 1000;
	public var rotSpeed = 10.0;
	public var rotSpeedRand = 2.0;
	public var size = 0.5;
	public var sizeIncr = 0.0;
	public var sizeRand = 0.5;
	public var sortMode = GpuSortMode.None;
	public var speed = 2.0;
	public var speedIncr = 0.0;
	public var speedRand = 0.5;
	public var texture:Texture;
}
