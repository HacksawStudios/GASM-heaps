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
	final _config:CameraFitConfig;

	public var enabled(default, set) = true;

	var _s3d:h3d.scene.Scene;
	var _targetComponent:Heaps3DComponent;
	var _time = 0.0;
	var _startPos:Vector;
	var _targetPos:Vector;
	var _fitSpeed = 0.0;
	var _oldCamPos:Vector;
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
		setFitSpeed(_config.fitSpeed);

		_appModel.resizeSignal.connect((?size:TResize) -> {
			_forceFit = true;
		});

		super.init();
	}

	public function detectChange(objectBounds:Bounds):Bool {
		final camPos = _s3d.camera.pos.clone();
		final stageSize:Point = cast {x: Engine.getCurrent().width, y: Engine.getCurrent().height};
		final cb = objectBounds;
		final ob = _oldObjBounds;

		final camMoved = _oldCamPos == null || camPos.distanceSq(_oldCamPos) > 0.001;
		final objChanged = ob == null
			|| (cb.xMax != ob.xMax || cb.xMin != ob.xMin || cb.yMax != ob.yMax || cb.yMin != ob.yMin || cb.yMax != ob.yMax);
		final stageChanged = _oldStageSize == null || stageSize.x != _oldStageSize.x || stageSize.y != _oldStageSize.y;

		_oldStageSize = stageSize;
		_oldCamPos = camPos;
		_oldObjBounds = cb;

		return (stageChanged || objChanged);
	}

	override public function update(dt:Float) {
		super.update(dt);
		if (enabled) {
			final bounds = _targetComponent.object.getBounds();

			// At some initial parts, the bounds are in a initial state of a very big value. ignore that frame and skip to the next
			if (bounds.xMin > 100000.0) {
				return;
			}

			if (detectChange(bounds) || _forceFit) {
				_shouldFit = true;
				_forceFit = false;
				return;
			}

			if (_shouldFit) {
				_shouldFit = false;
				_s3d.camera.update();
				_s3d.syncOnly(0.0);
				final bounds = _targetComponent.object.getBounds();
				_time = 0.0;
				_startPos = _s3d.camera.pos;
				_targetPos = calculateObjectFit(bounds);
			}

			_time += dt;
			final part = _time / _fitSpeed;
			final p = _fitSpeed == 0 ? 1 : Math.min(1.0, part);

			fit(p);
		} else {
			_time = 0.0;
		}
	}

	public function animateFit(speed:Float) {
		return Future.async(cb -> {
			_time = 0.0;
			final oldFs = _fitSpeed;
			setFitSpeed(speed);
			_forceFit = true;
			_onFitCallback = () -> {
				setFitSpeed(oldFs);
				cb(null);
			};
		});
	}

	public function setFitSpeed(fs:Float) {
		_fitSpeed = fs;
	}

	inline function fit(pos:Float) {
		final x = pos;
		_s3d.camera.pos.x = x.lerp(_startPos.x, _targetPos.x);
		_s3d.camera.pos.y = x.lerp(_startPos.y, _targetPos.y);
		_s3d.camera.pos.z = x.lerp(_startPos.z, _targetPos.z);

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

		final oldPos = _s3d.camera.pos.clone();
		_s3d.camera.pos.x = 0.0;
		_s3d.camera.pos.y = 0.0;
		_s3d.camera.target.load(_s3d.camera.pos);
		_s3d.camera.target.z = -_s3d.camera.zFar;
		_s3d.camera.update();

		final bounds = _config.bounds != null ? _config.bounds : objBounds;
		final objectZ = _s3d.camera.project(obj.x, obj.y, obj.z, sx, sy).z;

		final dist = [];

		final m = _config.margins;

		// _s3d.camera.pos.x = diffx;
		// _s3d.camera.pos.y = diffy;

		final cameraSidesP = _s3d.camera.unproject(1.0, 1.0, objectZ);
		final cameraSidesN = _s3d.camera.unproject(-1.0, -1.0, objectZ);

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
		Fitting speed
	**/
	public var fitSpeed = 1.0;

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
