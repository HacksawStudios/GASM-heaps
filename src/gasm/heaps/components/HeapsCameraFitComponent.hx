package gasm.heaps.components;

import gasm.core.Component;
import gasm.core.Entity;
import gasm.core.enums.ComponentType;
import gasm.core.math.geom.Point;
import gasm.core.utils.Assert;
import gasm.heaps.components.Heaps3DComponent;
import gasm.heaps.components.Heaps3DViewportComponent;
import gasm.heaps.components.HeapsScene3DComponent;
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
	var _startPos:h3d.Vector;
	var _fitSpeed = 0.0;

	public var margins(get, set):CameraFitMargins;

	function get_margins() {
		return _config.margins;
	}

	function set_margins(margins:CameraFitMargins) {
		return _config.margins = margins;
	}

	var _onFitCallback:Null<Void->Void> = null;

	public function new(config:CameraFitConfig) {
		_config = config;
		componentType = ComponentType.Actor;
	}

	override public function init() {
		_targetComponent = owner.get(Heaps3DComponent);
		Assert.that(_targetComponent != null, "CameraFitObjectComponent requires Heaps3DComponent in owner");
		_s3d = owner.getFromParents(HeapsScene3DComponent).scene3d;
		_startPos = _s3d.camera.pos;
		setFitSpeed(_config.fitSpeed);
		super.init();
	}

	override public function update(dt:Float) {
		super.update(dt);
		if (enabled) {
			_time += dt;
			fit(calculateObjectFit(), Math.min(1.0, _time / _fitSpeed));
		} else {
			_time = 0.0;
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

	inline function fit(target:h3d.Vector, pos:Float) {
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

	function calculateObjectFit():h3d.Vector {
		final obj = _targetComponent.object;
		final sx = hxd.Window.getInstance().width;
		final sy = hxd.Window.getInstance().height;
		_s3d.camera.update();
		final bounds = _config.bounds != null ? _config.bounds : obj.getBounds();
		final objectZ = _s3d.camera.project(obj.x, obj.y, obj.z, sx, sy).z;
		final cameraSides = _s3d.camera.unproject(1.0, 1.0, objectZ);

		final dist = [];

		final top = bounds.yMax;

		final m = _config.margins;
		final tMargin = m.top != null ? m.top : m.y;
		final bMargin = m.bottom != null ? m.bottom : m.y;
		final rMargin = m.right != null ? m.right : m.x;
		final lMargin = m.left != null ? m.left : m.x;

		dist.push(calculateDistance(cameraSides.x, bounds.xMax + rMargin, _s3d.camera.pos.z));
		dist.push(calculateDistance(cameraSides.x, Math.abs(bounds.xMin) + lMargin, _s3d.camera.pos.z));
		dist.push(calculateDistance(cameraSides.y, bounds.yMax + tMargin, _s3d.camera.pos.z));
		dist.push(calculateDistance(cameraSides.y, Math.abs(bounds.yMin) + bMargin, _s3d.camera.pos.z));

		var max:Float = null;
		var min:Float = null;

		for (d in dist) {
			max = max == null || d > max ? d : max;
			min = min == null || d < min ? d : min;
		}

		var distance = _config.crop ? max : min;

		if (Math.abs(distance) > 10000 || Math.isNaN(distance) || !Math.isFinite(distance)) {
			distance = 0.0;
		}

		return new h3d.Vector(_s3d.camera.pos.x, _s3d.camera.pos.y, _s3d.camera.pos.z - distance);
	}
}

@:structInit
class CameraFitMargins {
	public var x:Float = 0.0;
	public var y:Float = 0.0;
	public var top:Float = null;
	public var bottom:Float = null;
	public var left:Float = null;
	public var right:Float = null;
}

@:structInit
class CameraFitConfig {
	public var margins:CameraFitMargins = {x: 0.0, y: 0.0};
	public var fitSpeed = 1.0;
	public var fitCurve = (val:Float) -> val.linear();
	public var bounds:Null<h3d.col.Bounds> = null;
	public var crop = false;
}
