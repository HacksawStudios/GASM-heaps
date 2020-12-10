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

	final _tweens:Array<{vector:TweenVector, def:VectorTween}> = [];

	public function tween(tweens:Array<VectorTween>) {
		return Future.async(cb -> {
			final all = [];
			for (tween in tweens) {
				final def:VectorTween = {
					from: tween.from != null ? tween.from.clone() : null,
					to: tween.to != null ? tween.to.clone() : null,
					duration: tween.duration,
					onUpdate: tween.onUpdate,
					delay: tween.delay,
				};
				final vector = new TweenVector(0, 0, 0, 0);
				final val = {vector: vector, def: def};
				_tweens.push(val);
				final handler = vector.tween(def);
				handler.handle(() -> _tweens.remove(val));
				all.push(handler);
			}
			Future.ofMany(all).handle(() -> cb(Noise));
		});
	}

	public function update(dt:Float) {
		time += dt;
		for (t in _tweens) {
			t.vector.update(dt);
			if (t.vector.isActive) {
				if (t.def.to.x != null) {
					x = t.vector.x;
				}
				if (t.def.to.y != null) {
					y = t.vector.y;
				}
				if (t.def.to.z != null) {
					z = t.vector.z;
				}
				if (t.def.to.w != null) {
					w = t.vector.w;
				}
			}
		}
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
