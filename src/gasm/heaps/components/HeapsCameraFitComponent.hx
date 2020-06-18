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
 * Make camera of scene fit Heaps3DComponent
 *
 * Note that you can only use one camera fit component per stage graph, otherwise they will fight eachother.
 */
class HeapsCameraFitComponent extends Component {
	public var enabled(default, set) = true;
	public var duration = 1.0;

	final _config:CameraFitConfig;

	var _s3d:h3d.scene.Scene;
	var _targetComponent:Heaps3DComponent;
	var _time = 0.0;
	var _startPos:Vector;
	var _targetPos:Vector;

	var _oldObjBounds:Bounds;
	var _oldStageSize:Point;
	var _appModel:AppModelComponent;
	var _forceFit = false;
	var _shouldFit = false;

	public function set_enabled(e:Bool) {
		if (e == true) {
			_forceFit = true;
		}
		return enabled = e;
	}

	public var margins(get, set):CameraFitMargins;

	public var bounds(get, set):Bounds;

	function get_margins() {
		return _config.margins;
	}

	function set_margins(margins:CameraFitMargins) {
		return _config.margins = margins;
	}

	function get_bounds() {
		return _config.bounds;
	}

	function set_bounds(bounds:Bounds) {
		return _config.bounds = bounds;
	}

	var _onFitCallback:Null<Void->Void> = null;

	public function new(config:CameraFitConfig) {
		_config = config;
		componentType = ComponentType.Actor;
	}

	override public function init() {
		_targetComponent = owner.get(Heaps3DComponent);
		Assert.that(_targetComponent != null, "CameraFitObjectComponent requires Heaps3DComponent in owner");
		_appModel = owner.getFromParents(AppModelComponent);
		_s3d = owner.getFromParents(HeapsScene3DComponent).scene3d;
		_startPos = _s3d.camera.pos;
		duration = _config.duration;

		_appModel.resizeSignal.connect((?size:TResize) -> {
			_forceFit = true;
		});

		super.init();
	}

	inline function detectChange(objectBounds:Bounds):Bool {
		final camPos = _s3d.camera.pos.clone();
		final stageSize:Point = cast {x: Engine.getCurrent().width, y: Engine.getCurrent().height};
		final cb = objectBounds;
		final ob = _oldObjBounds;
		final objChanged = ob == null
			|| (cb.xMax != ob.xMax || cb.xMin != ob.xMin || cb.yMax != ob.yMax || cb.yMin != ob.yMin || cb.yMax != ob.yMax);
		final stageChanged = _oldStageSize == null || stageSize.x != _oldStageSize.x || stageSize.y != _oldStageSize.y;

		_oldStageSize = stageSize;
		_oldObjBounds = cb;

		return (stageChanged || objChanged);
	}

	override public function update(dt:Float) {
		super.update(dt);
		if (enabled) {
			final bounds = _targetComponent.object.getBounds();

			// At some initial parts, the bounds are in a initial state of a very big value. ignore that frame and skip to the next
			if (bounds.xMin >= 1e20) {
				return;
			}

			// As long as there's a change detected, or forced fit, set a flag and skip to next frame to ensure cameras and scene is settled
			if (detectChange(bounds) || _forceFit) {
				_shouldFit = true;
				_forceFit = false;
				return;
			}

			// At this point, all the properties for fitting are sure to be settled and we can calculate a new camera position
			if (_shouldFit) {
				_shouldFit = false;
				_s3d.syncOnly(0.0);
				_time = 0.0;
				_startPos = _s3d.camera.pos;
				_targetPos = calculateObjectFit(bounds);
			}

			_time += dt;
			final part = duration > 0.0 ? Math.min(1.0, _time / duration) : 1.0;
			fit(part);
		} else {
			_time = 0.0;
		}
	}

	public function animateFit(duration:Float) {
		return Future.async(cb -> {
			_time = 0.0;
			final oldDuration = this.duration;
			this.duration = duration;
			_forceFit = true;
			_onFitCallback = () -> {
				this.duration = oldDuration;
				cb(null);
			};
		});
	}

	inline function fit(pos:Float) {
		_s3d.camera.pos.x = pos.lerp(_startPos.x, _targetPos.x);
		_s3d.camera.pos.y = pos.lerp(_startPos.y, _targetPos.y);
		_s3d.camera.pos.z = pos.lerp(_startPos.z, _targetPos.z);

		// Close enough for fit
		if (pos >= 1.0) {
			if (_onFitCallback != null) {
				final old = _onFitCallback;
				_onFitCallback();
				if (_onFitCallback == old) {
					_onFitCallback = null;
				}
			}
			_startPos = _s3d.camera.pos;
		}
	}

	function calculateTargetZ(cameraY:Float, objectY:Float, cameraZ:Float, objectZ:Float):Float {
		final diffY = objectY - cameraY;
		final angleY = Math.atan(cameraY / Math.abs(cameraZ));

		// Distance from object is calculated given a triangle formula tan(v) = opp/adj
		// tan(v) = diffY/distance
		// tan(v)*distance = diffY
		// distance = diffY / tan(v)
		final distance = (diffY / Math.tan(angleY));

		// In case we have a scene where camera is facing towards positive, we need to invert
		final direction = (cameraZ - objectZ) > 0 ? 1.0 : -1.0;

		return cameraZ + distance * direction;
	}

	function calculateObjectFit(objBounds:Bounds):Vector {
		final obj = _targetComponent.object;
		final engine = Engine.getCurrent();
		final sx = engine.width;
		final sy = engine.height;

		// Since calculations are done centered, we need to reset camera position and save the old position
		final oldPos = _s3d.camera.pos.clone();
		_s3d.camera.pos.x = 0.0;
		_s3d.camera.pos.y = 0.0;
		_s3d.camera.target.load(_s3d.camera.pos);
		_s3d.camera.target.z = -_s3d.camera.zFar;
		_s3d.camera.update();

		final bounds = _config.bounds != null ? _config.bounds : objBounds;
		final objectZ = _s3d.camera.project(obj.x, obj.y, obj.z, sx, sy).z;

		final cameraSidesP = _s3d.camera.unproject(1.0, 1.0, objectZ);
		final cameraSidesN = _s3d.camera.unproject(-1.0, -1.0, objectZ);

		final dist = [];
		final m = _config.margins;

		dist.push(calculateTargetZ(cameraSidesP.x, bounds.xMax + m.right, _s3d.camera.pos.z, obj.z));
		dist.push(calculateTargetZ(Math.abs(cameraSidesN.x), Math.abs(bounds.xMin) + m.left, _s3d.camera.pos.z, obj.z));
		dist.push(calculateTargetZ(cameraSidesP.y, bounds.yMax + m.top, _s3d.camera.pos.z, obj.z));
		dist.push(calculateTargetZ(Math.abs(cameraSidesN.y), Math.abs(bounds.yMin) + m.bottom, _s3d.camera.pos.z, obj.z));

		var max:Float = null;
		var min:Float = null;

		for (d in dist) {
			max = max == null || d > max ? d : max;
			min = min == null || d < min ? d : min;
		}

		final result = _s3d.camera.pos.clone();
		result.z = _config.crop ? min : max;

		// How much do we have to move in camera X,Y to meet the corresponding camera XY ?
		final diffx = m.right - m.left;
		final diffy = m.top - m.bottom;
		result.x = diffx;
		result.y = diffy;

		_s3d.camera.pos.load(oldPos);
		_s3d.camera.update();

		return result;
	}
}

@:structInit
class CameraFitMargins {
	public var top:Float = 0.0;
	public var bottom:Float = 0.0;
	public var left:Float = 0.0;
	public var right:Float = 0.0;
}

@:structInit
class CameraFitConfig {
	/**
		Margins for object to be fitted
	**/
	public var margins:CameraFitMargins = {};

	/**
		Duration of fit
	**/
	public var duration = 1.0;

	/**
		Curve used for fitting
	**/
	public var fitCurve = (val:Float) -> val.linear();

	/**
		Override object bounds with fixed bounds
	**/
	public var bounds:Null<h3d.col.Bounds> = null;

	/**
		Instead of fitting for largest bound, the smallest bound is used
	**/
	public var crop = false;
}
