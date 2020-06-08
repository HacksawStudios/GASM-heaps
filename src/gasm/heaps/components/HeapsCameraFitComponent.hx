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

	public var enabled = true;

	var _s3d:h3d.scene.Scene;
	var _targetComponent:Heaps3DComponent;
	var _time = 0.0;
	var _startPos:Vector;
	var _fitSpeed = 0.0;
	var _oldCamPos:Vector;
	var _oldObjBounds:Bounds;
	var _oldStageSize:Point;
	var _appModel:AppModelComponent;
	var _resize = true;

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
			_resize = true;
		});
		super.init();
	}

	override public function update(dt:Float) {
		super.update(dt);
		if (enabled) {
			_time += dt;
			final part = _time / _fitSpeed;
			final p = _fitSpeed == 0 ? 1 : part;
			if (p <= 1) {
				final camPos = _s3d.camera.pos.clone();
				final stageSize:Point = cast {x: Engine.getCurrent().width, y: Engine.getCurrent().height};
				final cb = _targetComponent.object.getBounds();
				final ob = _oldObjBounds;

				final camMoved = _oldCamPos == null || camPos.distanceSq(_oldCamPos) > 0.001;
				final objChanged = ob == null
					|| (cb.xMax != ob.xMax || cb.xMin != ob.xMin || cb.yMax != ob.yMax || cb.yMin != ob.yMin || cb.yMax != ob.yMax);
				final stageChanged = _oldStageSize == null || stageSize.x != _oldStageSize.x || stageSize.y != _oldStageSize.y;

				// Calculate fit if this is first update or cam, object or scene has updated
				if (_resize == true || camMoved || objChanged || stageChanged) {
					fit(calculateObjectFit(cb), Math.min(1.0, part));
					_oldStageSize = stageSize;
					_oldCamPos = camPos;
					_oldObjBounds = cb;
					_resize = false;
				}
			}
		}
	}

	public function animateFit(speed:Float) {
		return Future.async(cb -> {
			_time = 0.0;
			final oldFs = _fitSpeed;
			setFitSpeed(speed);
			_startPos = _s3d.camera.pos;
			_onFitCallback = () -> {
				setFitSpeed(oldFs);
				cb(null);
			};
		});
	}

	public function setFitSpeed(fs:Float) {
		_fitSpeed = fs;
	}

	inline function fit(target:Vector, pos:Float) {
		_s3d.camera.pos.x = pos.lerp(_startPos.x, target.x);
		_s3d.camera.pos.y = pos.lerp(_startPos.y, target.y);
		_s3d.camera.pos.z = pos.lerp(_startPos.z, target.z);
		final remaining = target.sub(_s3d.camera.pos);

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

	function calculateDistance(cameraY:Float, objectY:Float, cameraZ:Float):Float {
		final diffY = cameraY - objectY;
		final angleY = Math.atan(Math.abs(cameraY) / Math.abs(cameraZ));
		return diffY / Math.tan(angleY);
	}

	function calculateObjectFit(objBounds:Bounds):Vector {
		final obj = _targetComponent.object;
		final sx = hxd.Window.getInstance().width;
		final sy = hxd.Window.getInstance().height;

		final bounds = _config.bounds != null ? _config.bounds : objBounds;
		final objectZ = _s3d.camera.project(obj.x, obj.y, obj.z, sx, sy).z;

		final dist = [];

		final m = _config.margins;

		final diffx = m.right - m.left;
		final diffy = m.top - m.bottom;

		_s3d.camera.pos.x = diffx;
		_s3d.camera.pos.y = diffy;

		_s3d.camera.target.load(_s3d.camera.pos);
		_s3d.camera.target.z = -_s3d.camera.zFar;

		_s3d.camera.update();
		final cameraSidesP = _s3d.camera.unproject(1.0, 1.0, objectZ);
		final cameraSidesN = _s3d.camera.unproject(-1.0, -1.0, objectZ);

		dist.push(calculateDistance(cameraSidesP.x, bounds.xMax + m.right, _s3d.camera.pos.z));
		dist.push(calculateDistance(Math.abs(cameraSidesN.x), Math.abs(bounds.xMin) + m.left, _s3d.camera.pos.z));
		dist.push(calculateDistance(cameraSidesP.y, bounds.yMax + m.top, _s3d.camera.pos.z));
		dist.push(calculateDistance(Math.abs(cameraSidesN.y), Math.abs(bounds.yMin) + m.bottom, _s3d.camera.pos.z));

		var max:Float = null;
		var min:Float = null;

		for (d in dist) {
			max = max == null || d > max ? d : max;
			min = min == null || d < min ? d : min;
		}

		var distance = _config.crop ? max : min;

		// HACK: There is a problem with fit sometimes having a hard time finding position, causing jerking
		// This limit will patch over the issue, but should preferably be properly addressed.
		final distanceLimit = 222 * _s3d.camera.fovY;
		if (Math.abs(distance) > distanceLimit || Math.isNaN(distance) || !Math.isFinite(distance)) {
			distance = 0.0;
		}

		final result = _s3d.camera.pos.clone();
		result.z -= distance;
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
