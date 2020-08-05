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
		super.init();
		if (_config.autoStart) {
			shake(_config.duration, _config.magnitude);
		}
	}

	/**
	 * Start shake
	 * @param duration Duration of shake in seconds. If null, duration from config is used.
	 * @param magnitude Magnitude of shake in units. If null, magnitude from config is used.
	 */
	public function shake(?duration:Null<Float>, ?magnitude:Null<Float>) {
		Assert.that(_s3d != null, 'Cannot shake before component is inited. Use autoStart or trigger shake later.');

		duration = duration == null ? _config.duration : duration;
		magnitude = magnitude == null ? _config.magnitude : magnitude;

		_time = 0.0;
		_shake = true;
		_duration = duration;
		_magnitude = magnitude;
		_startPos = _s3d.camera.pos.clone();
	}

	/**
	 * Stop shake and return to original position immediately.
	 */
	public function stop() {
		_s3d.camera.pos.load(_startPos);
		_shake = false;
		_config.onDone();
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
				final xPos = scale.shake(_startPos.x, _config.curve);
				final yPos = scale.shake(_startPos.y, _config.curve);
				_s3d.camera.pos.x = xPos;
				_s3d.camera.pos.y = yPos;
			} else {
				stop();
				if (_config.autoStart) {
					remove();
				}
			}
			_s3d.camera.update();
		}
	}

	override public function dispose() {
		super.dispose();
	}
}

@:structInit
class CameraShakeConfig {
	/**
	 * Curve to use for shake
	 */
	public var curve = () -> Math.random().backOutIn();

	/**
	 * How fast shake should gain intensity. 0.0 means it will increment half of the time and decrement rest. 0.66 means it will increment 2/3 of the time.
	 */
	public var increment = 0.95;

	/**
	 * If set to true, component will automaticlly start when added, and remoive itself when complete.
	 */
	public var autoStart = false;

	/**
	 * Duration of shake
	 */
	public var duration:Float = 1.0;

	/**
	 * How manu units maximum position offset will be.
	 */
	public var magnitude:Float = 1.0;

	/**
	 * Called when shake is complete.
	 */
	public var onDone = () -> {};
}
