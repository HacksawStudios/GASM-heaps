package gasm.heaps.components;

import tink.CoreApi.Future;
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
	var _startPos:h3d.Vector;
	var _fitSpeed = 0.0;

	var _onFitCallbacks:Array<() -> Void>;

	public function new(config:CameraFitConfig) {
		_config = config;
		_onFitCallbacks = new Array<() -> Void>();
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
			fit(calculateObjectFit(), dt * _fitSpeed);
			_s3d.camera.update();
		}
	}

	public function animateFit(speed:Float) {
		return Future.async(cb -> {
			final oldFs = _fitSpeed;
			setFitSpeed(speed);
			addOnFitCallback(() -> {
				setFitSpeed(oldFs);
				cb(null);
			});
		});
	}

	public function addOnFitCallback(cb:() -> Void) {
		_onFitCallbacks.push(cb);
	}

	public function setFitSpeed(fs:Float) {
		_fitSpeed = fs;
	}

	inline function fit(target:h3d.Vector, x:Float) {
		final p = Math.min(1.0, x);

		_s3d.camera.pos.x = p.lerp(_startPos.x, target.x);
		_s3d.camera.pos.y = p.lerp(_startPos.y, target.y);
		_s3d.camera.pos.z = p.lerp(_startPos.z, target.z);
		final remaining = target.sub(_s3d.camera.pos);

		// Close enough for fit
		if (remaining.lengthSq() < 0.001) {
			while (_onFitCallbacks.length > 0) {
				final cb = _onFitCallbacks.shift();
				cb();
			}
		}

		_startPos = _s3d.camera.pos;
	}

	function calculateObjectFit():h3d.Vector {
		final obj = _targetComponent.object;
		final sx = hxd.Window.getInstance().width;
		final sy = hxd.Window.getInstance().height;
		_s3d.camera.update();

		final bounds = obj.getBounds();
		final objectZ = _s3d.camera.project(obj.x, obj.y, obj.z, sx, sy).z;
		final cameraSides = _s3d.camera.unproject(1.0, 1.0, objectZ);

		// fit vertical
		final diffY = cameraSides.x - (bounds.xMax + _config.margins.y);
		final angleY = Math.atan(Math.abs(cameraSides.x) / Math.abs(_s3d.camera.pos.z));
		final distanceY = diffY / Math.tan(angleY);

		// fit horizontal
		final diffX = cameraSides.y - (bounds.yMax + _config.margins.x);
		final angleX = Math.atan(Math.abs(cameraSides.y) / Math.abs(_s3d.camera.pos.z));
		final distanceX = diffX / Math.tan(angleX);

		var distance = Math.min(distanceX, distanceY);

		if (distance > 10000 || Math.isNaN(distance) || !Math.isFinite(distance)) {
			distance = 0.0;
		}

		return new h3d.Vector(_s3d.camera.pos.x, _s3d.camera.pos.y, _s3d.camera.pos.z - distance);
	}
}

@:structInit
class CameraFitConfig {
	public var margins:Point = {x: 0.0, y: 0.0};
	public var fitSpeed = 10.0;
	public var fitCurve = (val:Float) -> val.linear();
}
