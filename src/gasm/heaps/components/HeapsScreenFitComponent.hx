package gasm.heaps.components;

import gasm.core.Component;
import gasm.core.Entity;
import gasm.core.api.singnals.TResize;
import gasm.core.components.AppModelComponent;
import gasm.core.enums.ComponentType;
import gasm.core.math.geom.Point;
import gasm.core.utils.Assert;
import gasm.heaps.components.Heaps3DComponent;
import gasm.heaps.components.Heaps3DViewportComponent;
import gasm.heaps.components.HeapsScene3DComponent;
import h3d.Engine;
import h3d.Vector;
import h3d.col.Bounds;
import tink.CoreApi.Future;
import tweenx909.TweenX;
import tweenxcore.Tools.Easing;

using tweenxcore.Tools;

/**
 * Make object or entire scene fit to screen given object.z
 * object is prioritized above scene
 * Entity containing Scene + Object -> object is fitted
 * Entity containing Scene -> scene is fitted
 * Entity containing Object -> object is fitted
 */
class HeapsScreenFitComponent extends Component {
	final _config:ScreenFitConfig;
	var _object:h3d.scene.Object;
	var _camera:h3d.Camera;

	public var margins(get, set):ScreenFitMargins;

	function get_margins() {
		return _config.margins;
	}

	function set_margins(margins:ScreenFitMargins) {
		return _config.margins = margins;
	}

	function get_bounds() {
		return _config.bounds;
	}

	function set_bounds(bounds:Bounds) {
		return _config.bounds = bounds;
	}

	public function new(config:ScreenFitConfig) {
		_config = config;
		componentType = ComponentType.Actor;
	}

	override public function init() {
		final targetScene = owner.get(HeapsScene3DComponent);
		final targetObject = owner.get(Heaps3DComponent);
		final parentScene = owner.getFromParents(HeapsScene3DComponent);

		Assert.that(targetScene != null || targetObject != null,
			"HeapsScreenFitComponent must have either a HeapsScene3DComponent or Heaps3DComponent in entity");

		_object = targetObject != null ? targetObject.object : targetScene.scene3d;
		_camera = targetObject != null ? parentScene.scene3d.camera : targetScene.scene3d.camera;

		super.init();
	}

	override public function update(dt:Float) {
		super.update(dt);

		final engine = Engine.getCurrent();

		// Get center Z for screen at _object.z
		final screenZ = _camera.project(0.0, 0.0, _object.z, engine.width, engine.height).z;

		// get outer edges of screen
		final screen3DPosition = _camera.unproject(1.0, 1.0, screenZ);

		final screenW = screen3DPosition.x * 2.0;
		final screenH = screen3DPosition.y * 2.0;

		// Create a new "virtual" screen with included margin
		final screenTop = screen3DPosition.y - margins.top * screenH;
		final screenBottom = (-screen3DPosition.y) + margins.bottom * screenH;
		final screenRight = screen3DPosition.x - margins.right * screenW;
		final screenLeft = (-screen3DPosition.x) + margins.left * screenW;

		// Place object in the middle of the virtual screen, reset scaling to 1
		_object.setScale(1.0);
		_object.x = screenLeft + (screenRight - screenLeft) * 0.5;
		_object.y = screenBottom + (screenTop - screenBottom) * 0.5;

		final bounds = _config.bounds != null ? _config.bounds : _object.getBounds();

		// Detect how much scaling is needed to fit the new screen
		final scaleX = determineScale((screenRight - _object.x) / (bounds.xMax - _object.x), (_object.x - screenLeft) / (_object.x - bounds.xMin));
		final scaleY = determineScale((screenTop - _object.y) / (bounds.yMax - _object.y), (_object.y - screenBottom) / (_object.y - bounds.yMin));
		_object.setScale(determineScale(scaleX, scaleY));
	}

	inline function determineScale(x:Float, y:Float):Float {
		return _config.crop ? Math.max(x, y) : Math.min(x, y);
	}
}

@:structInit
class ScreenFitMargins {
	public var top:Float = 0.0;
	public var bottom:Float = 0.0;
	public var left:Float = 0.0;
	public var right:Float = 0.0;
}

@:structInit
class ScreenFitConfig {
	/**
		percentual margins for object to be fitted
	**/
	public var margins:ScreenFitMargins = {};

	/**
		Override object bounds with fixed bounds
	**/
	public var bounds:Null<h3d.col.Bounds> = null;

	/**
		Instead of fitting for largest bound, the smallest bound is used
	**/
	public var crop = false;
}
