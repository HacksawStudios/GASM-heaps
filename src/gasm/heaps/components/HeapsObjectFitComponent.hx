package gasm.heaps.components;

import gasm.core.utils.Assert;
import gasm.heaps.components.Heaps3DComponent;
import gasm.heaps.components.HeapsScene3DComponent;
import gasm.heaps.transform.TweenObject.ObjectTween;
import h3d.Engine;
import h3d.Vector;
import h3d.col.Bounds;
import h3d.col.Point;
import hacksaw.core.components.view.h3d.TileTargetComponent;

using tink.CoreApi;

/**
	Make object or entire scene fit to screen given object.z och scene.z

	Note that it needs to be parent to object to fit

	@example
	final plane = new TilePlaneComponent({tile: tile});
	final fit = new HeapsObjectFitComponent();
	final holder = new Entity().add(fit);
	holder.addChild(new Entity().add(plane));

 */
class HeapsObjectFitComponent extends Heaps3DComponent {
	public var enable = true;

	public var margins(get, set):ObjectFitMargins;

	public var bounds(get, set):Bounds;
	public var scale(get, null):Vector;

	final _config:ObjectFitConfig;
	var _object:h3d.scene.Object;
	var _camera:h3d.Camera;
	var _tweening = false;
	var _scheduledTweens:Array<ObjectTween> = null;
	var _tweenDone = Future.trigger();

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

	inline function calculateBounds():h3d.col.Bounds {
		// Object needs worlspace calculation if configured. Is performed in getBounds()
		var realBounds = _object.getBounds().clone();
		if (_config.bounds != null) {
			final configBounds = _config.bounds.clone();
			configBounds.transform(_object.getAbsPos());
			return configBounds;
		}
		return realBounds;
	}

	override public function update(dt:Float) {
		super.update(dt);

		if (!enable || _object == null || _tweening) {
			return;
		}

		final engine = Engine.getCurrent();
		_object.setScale(1.0);

		final preBounds = calculateBounds();

		if (Math.abs(preBounds.zMax) >= _camera.zFar) {
			return;
		}

		// Get center Z for screen at _object.z
		final screenZ = _camera.project(0.0, 0.0, preBounds.zMax, engine.width, engine.height, false).z;

		// Get outer edges of screen
		final screen3DPositionPos = _camera.unproject(1.0, 1.0, screenZ);
		final screen3DPositionNeg = _camera.unproject(-1.0, -1.0, screenZ);

		final screenW = Math.abs(screen3DPositionPos.x - screen3DPositionNeg.x);
		final screenH = Math.abs(screen3DPositionNeg.y - screen3DPositionPos.y);
		// Create a new "virtual" screen with included margin
		final screenTop = screen3DPositionPos.y - margins.top * screenH;
		final screenBottom = screen3DPositionNeg.y + margins.bottom * screenH;
		final screenRight = screen3DPositionPos.x - margins.right * screenW;
		final screenLeft = screen3DPositionNeg.x + margins.left * screenW;

		// Place object in the middle of the virtual screen
		_object.x = screenLeft + (screenRight - screenLeft) * 0.5;
		_object.y = screenBottom + (screenTop - screenBottom) * 0.5;

		final bounds = calculateBounds();

		var rotScale = 1.0;
		final tileTarget = owner.firstChild != null ? owner.firstChild.get(TileTargetComponent) : null;
		if (tileTarget != null && _config.crop) {
			final rot = tileTarget.mesh.getRotationQuat().clone();
			tileTarget.mesh.setRotation(0, 0, 0);
			final straightBounds = tileTarget.mesh.getBounds().clone();
			tileTarget.mesh.setRotationQuat(rot);
			final xDiff = Math.abs(bounds.xMin / straightBounds.xMin);
			final yDiff = Math.abs(bounds.yMin / straightBounds.yMin);
			// Kinda works, but not really correct. If value is not a mod of 45 degrees it will trim a bit much.
			// But typically we would use 0, 45 or 90 degrees, which are fine.
			rotScale = Math.max(xDiff, yDiff) * 1.42;
		}

		// Detect how much scaling is needed to fit the new screen
		final xMaxScale = Math.abs((screenRight - _object.x) / (bounds.xMax - _object.x));
		final xMinScale = Math.abs((_object.x - screenLeft) / (_object.x - bounds.xMin));
		var scaleX = determineScale(xMaxScale, xMinScale) * rotScale;

		final yMaxScale = Math.abs((screenTop - _object.y) / (bounds.yMax - _object.y));
		final yMinScale = Math.abs((_object.y - screenBottom) / (_object.y - bounds.yMin));
		var scaleY = determineScale(yMaxScale, yMinScale) * rotScale;

		var scale = determineScale(scaleX, scaleY);
		if (_config.maxScale != null) {
			scale = Math.min(scale, _config.maxScale);
			scaleX = Math.min(scaleX, _config.maxScale);
			scaleY = Math.min(scaleY, _config.maxScale);
		}

		if (_config.keepRatio) {
			_object.scaleX = scale;
			_object.scaleY = scale;
		} else {
			_object.scaleX = scaleX;
			_object.scaleY = scaleY;
		}
		_object.scaleZ = _config.scaleZ ? scale : _object.scaleZ;
		if (_scheduledTweens != null && inited) {
			tween(_scheduledTweens);
			_scheduledTweens = null;
		}
	}

	public function tween(tweens:Array<ObjectTween>) {
		if (!inited) {
			_scheduledTweens = tweens;
			return _tweenDone;
		}

		_tweening = true;
		for (tween in tweens) {
			switch tween {
				case Scale(v):
					final leftMarg = margins != null ? margins.left : 0.0;
					final topMarg = margins != null ? margins.top : 0.0;
					v.from.x *= scale.x;
					v.from.y *= scale.y;
					v.from.z *= scale.x;
					v.to.x *= scale.x + leftMarg;
					v.to.y *= scale.y + topMarg;
					v.to.z *= scale.z;
				default:
					null;
			}
		}
		final handler = object.tween(tweens);
		handler.handle(() -> {
			_tweening = false;
			_tweenDone.trigger(Noise);
		});
		return _tweenDone;
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

	function get_scale() {
		if (_object == null) {
			return new Vector();
		}
		return new Vector(_object.scaleX, _object.scaleY, _object.scaleZ);
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
		right: 0.0,
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
