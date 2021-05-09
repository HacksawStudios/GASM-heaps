package gasm.heaps.shaders;

import gasm.heaps.transform.TweenVector;

using tink.CoreApi;

/**
	Extend if you need a shader that can be tweened.
	Override getters and setters to map to shader source params.
**/
class TweenShader extends hxsl.Shader {
	public var x(get, set):Float;
	public var y(get, set):Float;
	public var z(get, set):Float;
	public var w(get, set):Float;

	final _tweenVector:TweenVector = new TweenVector(0, 0, 0, 0);

	public function tween(tweens:Array<VectorTween>) {
		final futures = [
			for (tween in tweens) {
				_tweenVector.tween({
					from: tween.from != null ? tween.from.clone() : null,
					to: tween.to != null ? tween.to.clone() : null,
					duration: tween.duration,
					onUpdate: tween.onUpdate,
					delay: tween.delay,
				});
			}
		];

		return Future.ofMany(futures);
	}

	public function update(dt:Float) {
		time += dt;
		_tweenVector.update(dt);
		x = _tweenVector.x;
		y = _tweenVector.y;
		z = _tweenVector.z;
		w = _tweenVector.w;
	}

	static var SRC = {
		@param var time:Float;
	}

	public function get_x():Float {
		return null;
	}

	public function get_y():Float {
		return null;
	}

	public function get_z():Float {
		return null;
	}

	public function get_w():Float {
		return null;
	}

	public function set_x(val:Float):Float {
		return null;
	}

	public function set_y(val:Float):Float {
		return null;
	}

	public function set_z(val:Float):Float {
		return null;
	}

	public function set_w(val:Float):Float {
		return null;
	}
}
