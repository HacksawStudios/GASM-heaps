package gasm.heaps.components;

import gasm.core.Component;
import gasm.core.Entity;
import gasm.core.enums.ComponentType;
import gasm.core.math.geom.Point;
import gasm.core.utils.Assert;
import gasm.heaps.components.Heaps3DComponent;
import gasm.heaps.components.Heaps3DViewportComponent;
import gasm.heaps.components.HeapsScene3DComponent;
import tweenx909.TweenX;
import tweenxcore.Tools.Easing;

using tweenxcore.Tools;

/**
 * Make camera of scene fit Heaps3DComponent
 *
 * Note that you can only use one camera fit component per stage graph, otherwise they will fight eachother.
 */
class HeapsCameraFitComponent extends Component {
	public var enabled = true;

	final _config:CameraFitConfig;
	var _s3d:h3d.scene.Scene;
	var _targetComponent:Heaps3DComponent;
	var _time = 0.0;
	var _currentPos:h3d.Vector;
	var _startPos:h3d.Vector;

	public function new(config:CameraFitConfig) {
		_config = config;
		componentType = ComponentType.Actor;
	}

	override public function init() {
		_targetComponent = owner.get(Heaps3DComponent);
		Assert.that(_targetComponent != null, "CameraFitObjectComponent requires Heaps3DComponent in owner");
		_s3d = owner.getFromParents(HeapsScene3DComponent).scene3d;
		_startPos = _s3d.camera.pos;
		super.init();
	}

	override public function update(dt:Float) {
		super.update(dt);
		if (enabled) {
			_time += dt;
			var c = _time / _config.fitSpeed;
			final target = calculateObjectFit();
			if (target != _currentPos) {
				fit(target, c);
				_time = 0.0;
			}
			_currentPos = target;
			_s3d.camera.update();
		}
	}

	public function setFitSpeed(fs:Float) {
		_config.fitSpeed = fs;
	}

	inline function fit(target:h3d.Vector, pos:Float) {
		if (pos < 1.0) {
			_s3d.camera.pos.x = pos.lerp(_startPos.x, target.x);
			_s3d.camera.pos.y = pos.lerp(_startPos.y, target.y);
			_s3d.camera.pos.z = pos.lerp(_startPos.z, target.z);
		} else {
			_startPos = _s3d.camera.pos = target;
		}
	}

	function calculateObjectFit():h3d.Vector {
		final obj = _targetComponent.object;
		final sx = hxd.Window.getInstance().width;
		final sy = hxd.Window.getInstance().height;
		_s3d.camera.update();

		final bounds = obj.getBounds();
		final objectZ = _s3d.camera.project(obj.x, obj.y, obj.z, sx, sy).z;
		final boundMax = Math.max(bounds.xMax, bounds.yMax);
		final cameraSides = _s3d.camera.unproject(1.0, 1.0, objectZ);

		var distance = 0.0;

		if (sx < sy) {
			final diffY = cameraSides.y - (boundMax + _config.margins.y);
			final angleY = Math.atan(cameraSides.y / Math.abs(_s3d.camera.pos.z));
			distance = diffY / Math.tan(angleY);
		} else {
			final diffX = cameraSides.x - (boundMax + _config.margins.x);
			final angleX = Math.atan(cameraSides.x / Math.abs(_s3d.camera.pos.z));
			distance = diffX / Math.tan(angleX);
		}
		if (distance > 10000 || Math.isNaN(distance) || !Math.isFinite(distance)) {
			distance = 0.0;
		}

		return new h3d.Vector(_s3d.camera.pos.x, _s3d.camera.pos.y, _s3d.camera.pos.z - distance);
	}
}

@:structInit
class CameraFitConfig {
	public var margins:Point = {x: 0.0, y: 0.0};
	public var fitSpeed = 1.0;
	public var fitCurve = (val:Float) -> val.linear();
}
