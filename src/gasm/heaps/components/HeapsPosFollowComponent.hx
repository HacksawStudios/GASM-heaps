package gasm.heaps.components;

import gasm.core.Component;
import gasm.core.Entity;
import gasm.core.enums.ComponentType;
import gasm.core.utils.Assert;

enum PosFollowOffset {
	/**
		Offset by given pixels.
	**/
	OffsetPixels(x:Int, y:Int);

	/**
		Offset by given units
	**/
	Offset3D(x:Float, y:Float, z:Float);

	/**
		No offset
	**/
	None;
}

enum OffsetScaleFollow {
	Target;
	This;
	None;
}

class HeapsPosFollowComponent extends Component {
	/**
		Disable pos follow
	**/
	public var freeze = false;

	final _config:HeapsPosFollowComponentConfig;

	// Source for position
	var _target2d:h2d.Object = null;
	var _target3d:h3d.scene.Object = null;

	// Target for position
	var _this2d:h2d.Object = null;
	var _this3d:h3d.scene.Object;

	var _camera:h3d.Camera = null;

	final _engine:h3d.Engine;

	public function new(config:HeapsPosFollowComponentConfig) {
		_config = config;
		componentType = ComponentType.Actor;
		_engine = h3d.Engine.getCurrent();
	}

	override public function init() {
		// Determine target (this, target for position)

		final comp2d = owner.get(HeapsSpriteComponent);
		final comp3d = owner.get(Heaps3DComponent);
		_this2d = (comp2d != null) ? comp2d.sprite : null;
		_this3d = (comp3d != null) ? comp3d.object : null;
		Assert.that(_this3d != null || _this2d != null, "No 3d or 2dcomponent found");

		// Determine follow
		final followComp2d = _config.target.get(HeapsSpriteComponent);
		final followComp3d = _config.target.get(Heaps3DComponent);
		_target2d = (followComp2d != null) ? followComp2d.sprite : null;
		_target3d = (followComp3d != null) ? followComp3d.object : null;
		Assert.that(_target3d != null || _target2d != null, "follow component needs to be a 3DComponent or a SpriteComponent");

		if (_target3d != null) {
			final scene = _config.target.getFromParents(HeapsScene3DComponent);
			Assert.that(scene != null, "No scene found in graph");
			_camera = scene.scene3d.camera;
		}

		// Use heaps internal mechanic for 3d follow 3d
		if (_this3d != null && _target3d != null) {
			_this3d.follow = _target3d;
		}

		super.init();
	}

	override public function update(dt:Float) {
		if (freeze) {
			return;
		}

		// Get bounds if needed later
		final bounds = (_this2d != null) ? _this2d.getBounds() : null;

		// Get target scaling
		final targetScaleX = (_target2d != null) ? _target2d.scaleX : _target3d.scaleX;
		final targetScaleY = (_target2d != null) ? _target2d.scaleY : _target3d.scaleY;
		final targetScaleZ = (_target2d != null) ? 1.0 : _target3d.scaleZ;

		// Get 'this' scaling
		final thisScaleX = (_this2d != null) ? _this2d.scaleX : _this3d.scaleX;
		final thisScaleY = (_this2d != null) ? _this2d.scaleY : _this3d.scaleY;
		final thisScaleZ = (_this2d != null) ? 1.0 : _this3d.scaleZ;

		// Calculate pixel offsets
		var offsetPixelsX = 0.0;
		var offsetPixelsY = 0.0;
		var offsetUnitsX = 0.0;
		var offsetUnitsY = 0.0;
		var offsetUnitsZ = 0.0;

		switch (_config.offset) {
			case OffsetPixels(x, y):
				offsetPixelsX += x;
				offsetPixelsY += y;
			case Offset3D(x, y, z):
				offsetUnitsX = x;
				offsetUnitsY = y;
				offsetUnitsZ = z;
			case None:
		}

		switch (_config.offsetScale) {
			case This:
				offsetPixelsX *= thisScaleX;
				offsetPixelsY *= thisScaleY;
				offsetUnitsX *= thisScaleX;
				offsetUnitsY *= thisScaleY;
				offsetUnitsZ *= thisScaleZ;
			case Target:
				offsetPixelsX *= targetScaleX;
				offsetPixelsY *= targetScaleY;
				offsetUnitsX *= targetScaleX;
				offsetUnitsY *= targetScaleY;
				offsetUnitsZ *= targetScaleZ;
			case None:
		}

		// 2D component following 3d component
		if (_this2d != null && _target3d != null) {
			final engine = h3d.Engine.getCurrent();
			// Find source world position
			final worldPos = _target3d.localToGlobal();
			final pos2d = _camera.project(worldPos.x + offsetUnitsX, worldPos.y + offsetUnitsY, worldPos.z + offsetUnitsZ, engine.width, engine.height);

			// Center
			_this2d.x = pos2d.x - bounds.width * 0.5 + offsetPixelsX;
			_this2d.y = pos2d.y - bounds.height * 0.5 + offsetPixelsY;
		}
		// 3d following 2d
		else if (_this3d != null && _target2d != null) {
			final px = _target2d.x + offsetPixelsX;
			final px = _target2d.y + offsetPixelsY;

			// Coordinates needs to be [-1,1]
			final x = 2.0 * (px / _engine.width) - 1.0;
			final y = 2.0 * (px / _engine.height) - 1.0;

			// Fetch 2d coordinate on scree
			final pos = _camera.unproject(x, y, _this3d.z);
			_this3d.x = pos.x + offsetUnitsX;
			_this3d.y = pos.y + offsetUnitsY;
		}
		// 2d following 3d
		else if (_this2d != null && _target2d != null) {
			_this2d.x = _target2d.x + offsetPixelsX;
			_this2d.y = _target2d.y + offsetPixelsY;
		} else {
			// 3d following 3d
			_this3d.x = offsetUnitsX;
			_this3d.y = offsetUnitsY;
			_this3d.z = offsetUnitsZ;
		}
	}

	override public function dispose() {
		if (_this3d != null && _target3d != null) {
			_this3d.follow = null;
		}
	}
}

@:structInit
class HeapsPosFollowComponentConfig {
	/**
		Follow this entity. Must contain a HeapsSpriteComponent or Heaps3DComponent
	**/
	public var target:Entity;

	/**
		How to offset.
	**/
	public var offset:PosFollowOffset = None;

	public var offsetScale:OffsetScaleFollow = Target;
}
