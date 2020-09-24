package gasm.heaps.components;

import gasm.core.Component;
import gasm.core.enums.ComponentType;
import gasm.core.utils.Assert;
import gasm.heaps.components.Heaps3DComponent;
import gasm.heaps.components.HeapsScene3DComponent;
import h3d.Engine;
import h3d.col.Bounds;

/**
 * Make object or entire scene fit to screen given object.z och scene.z
 */
class HeapsObjectFitComponent extends Heaps3DComponent {
	public var enable = true;

	public var margins(get, set):ObjectFitMargins;

	public var bounds(get, set):Bounds;

	final _config:ObjectFitConfig;
	var _object:h3d.scene.Object;
	var _camera:h3d.Camera;

	public function new(config:ObjectFitConfig, ?parent:h3d.scene.Object) {
		super(parent);
		_config = config;
	}

	override public function init() {
		final sceneComp = owner.getFromParents(HeapsScene3DComponent);

		Assert.that(sceneComp != null, "HeapsObjectFitComponent must have a HeapsScene3DComponent in graph");

		_object = object.object;
		_camera = sceneComp.scene3d.camera;

		super.init();
	}

	override public function update(dt:Float) {
		super.update(dt);
		if (!enable) {
			return;
		}

		final engine = Engine.getCurrent();
		_object.setScale(1.0);

		final preBounds = _object.getBounds();

		if (Math.abs(preBounds.zMax) >= _camera.zFar) {
			return;
		}

		// Get center Z for screen at _object.z
		final screenZ = _camera.project(0.0, 0.0, preBounds.zMax, engine.width, engine.height, false).z;

		// get outer edges of screen
		final screen3DPositionPos = _camera.unproject(1.0, 1.0, screenZ);
		final screen3DPositionNeg = _camera.unproject(-1.0, -1.0, screenZ);

		final screenW = screen3DPositionPos.x - screen3DPositionNeg.x;
		final screenH = screen3DPositionNeg.y - screen3DPositionNeg.y;

		// Create a new "virtual" screen with included margin
		final screenTop = screen3DPositionPos.y - margins.top * screenH;
		final screenBottom = screen3DPositionNeg.y + margins.bottom * screenH;
		final screenRight = screen3DPositionPos.x - margins.right * screenW;
		final screenLeft = screen3DPositionNeg.x + margins.left * screenW;

		// Place object in the middle of the virtual screen, reset scaling to 1
		_object.x = screenLeft + (screenRight - screenLeft) * 0.5;
		_object.y = screenBottom + (screenTop - screenBottom) * 0.5;

		final bounds = _config.bounds != null ? _config.bounds : _object.getBounds();

		// Detect how much scaling is needed to fit the new screen
		final scaleX = determineScale((screenRight - _object.x) / (bounds.xMax - _object.x), (_object.x - screenLeft) / (_object.x - bounds.xMin));
		final scaleY = determineScale((screenTop - _object.y) / (bounds.yMax - _object.y), (_object.y - screenBottom) / (_object.y - bounds.yMin));

		var scale = determineScale(scaleX, scaleY);
		if (_config.maxScale != null) {
			scale = Math.min(scale, _config.maxScale);
		}
		if (_config.keepRatio) {
			_object.scaleX = scale;
			_object.scaleY = scale;
		} else {
			_object.scaleX = scaleX;
			_object.scaleY = scaleY;
		}
		_object.scaleZ = _config.scaleZ ? scale : _object.scaleZ;
	}

	inline function determineScale(x:Float, y:Float):Float {
		return _config.crop ? Math.max(x, y) : Math.min(x, y);
	}

	function get_margins() {
		return _config.margins;
	}

	function set_margins(margins:ObjectFitMargins) {
		return _config.margins = margins;
	}

	function get_bounds() {
		return _config.bounds;
	}

	function set_bounds(bounds:Bounds) {
		return _config.bounds = bounds;
	}
}

@:structInit
class ObjectFitMargins {
	public var top:Float = 0.0;
	public var bottom:Float = 0.0;
	public var left:Float = 0.0;
	public var right:Float = 0.0;
}

@:structInit
class ObjectFitConfig {
	/**
		Percentual margins for object to be fitted
	**/
	public var margins:ObjectFitMargins = {
		top: 0.0,
		bottom: 0.0,
		left: 0.0,
		right: 0.0
	};

	/**
		Override object bounds with fixed bounds
	**/
	public var bounds:Null<h3d.col.Bounds> = null;

	/**
		Instead of fitting for largest bound, the smallest bound is used
	**/
	public var crop = false;

	/**
		If set to false, object will be stretched to fill screen
	**/
	public var keepRatio = true;

	/**
		Also apply scaling for z.
	**/
	public var scaleZ = false;

	/**
		Ensure scale never exceeds this value
	**/
	public var maxScale:Null<Float> = null;
}
