package gasm.heaps.components;

import gasm.heaps.components.Heaps3DComponent;
import gasm.heaps.components.Heaps3DViewportComponent;
import gasm.core.enums.ComponentType;
import gasm.core.Entity;
import gasm.core.Component;
import gasm.core.math.geom.Point;
import gasm.heaps.components.HeapsScene3DComponent;
import tweenx909.TweenX;
import tweenxcore.Tools.Easing;
import gasm.core.utils.Assert;

using tweenxcore.Tools;

/**
 * Make camera of scene fit Heaps3DComponent
 *
 * Note that you can only use one camera fit component per stage graph, otherwise they will fight eachother.
 */
class HeapsCameraShakeComponent extends Component {
	final _config:CameraShakeConfig;

	var _s3d:h3d.scene.Scene;
	var _time:Float;
	var _duration:Float;
	var _magnitude:Float;
	var _shake = false;
	var _currentPos:h3d.Vector;
	var _startPos:h3d.Vector;

	public function new(config:CameraShakeConfig) {
		_config = config;
		componentType = ComponentType.Actor;
	}

	override public function init() {
		final scene = owner.getFromParents(HeapsScene3DComponent);
		Assert.that(scene != null, "HeapsCameraShakeComponent requires HeapsScene3DComponent in parent graph");
		_s3d = scene.scene3d;
		_startPos = _s3d.camera.pos;
		super.init();
	}

	public function shake(duration = 1.0, magnitude = 0.1) {
		_time = 0.0;
		_shake = true;
		_duration = duration;
		_magnitude = magnitude;
		_startPos = _s3d.camera.pos.clone();
	}

	public function stop() {
		_shake = false;
	}

	override public function update(dt:Float) {
		super.update(dt);
		if (_shake) {
			_time += dt;
			final part = _time / _duration;
			if (part <= 1.0) {
				final inPart = (part / _config.increment) * _magnitude;
				final outPart = (1 - ((part - _config.increment) / (1 - _config.increment))) * _magnitude;
				final scale = part <= _config.increment ? inPart : outPart;
				final xPos = scale.shake(0.0, _config.curve);
				final yPos = scale.shake(0.0, _config.curve);
				_s3d.camera.pos.x = xPos;
				_s3d.camera.pos.y = yPos;
			} else {
				_s3d.camera.pos = _startPos;
				_shake = false;
			}
			_s3d.camera.update();
		}
	}
}

@:structInit
class CameraShakeConfig {
	public var curve = () -> Math.random().backOutIn();
	public var increment = 0.95;
}
