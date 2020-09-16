package gasm.heaps.transform;

import gasm.core.utils.Assert;
import h3d.Vector;

using Lambda;
using Safety;
using tink.CoreApi;
using tweenxcore.Tools;

@:structInit
class VectorTween {
	/**
		Target to tween to
		Can be assigned from vector or from dynamic object specifying the axis to transform
		So if you wish to only transform z axis 20 units, assign `{z:20}`
	**/
	public var to:TweenTarget = null;

	/**
		Target to tween from
		Optional, and if omitted it will use current object transform
		Can be assigned from vector or from dynamic object specifying the axis to transform
	**/
	public var from:TweenTarget = null;

	/**
		Called when tween is complete
		@param done True when tween was completed 100%. False when tween was cancelled or replaced
	**/
	public var onDone:(done:Bool) -> Void = null;

	/**
		Delay start of tween in seconds
	**/
	public var delay = 0.0;

	/**
		Duration of tween in seconds
	**/
	public var duration = 1.0;

	/**
		Current elapsed time of running tween, or 0 if not running
	**/
	public var time = 0.0;

	/**
		Easing curve to use for tween
	**/
	public var curve:(x:Float) -> Float = f -> f;

	/**
		If true, to and from values will be in relation to objects current transform instead of absolute
	**/
	public var relative = false;

	/**
		For how many seconds of tween curve should be applied.
	**/
	public var curveDuration:Null<Float> = null;

	/**
		If true, tween will repeat until manually stopped
	**/
	public var repeat = false;
}

/**
	3d space position with all values optional so one can describe change in only one axis.
	Construct by assigning.
	```
	final pos:TweenPos = {x:10};
	```
**/
@:structInit
@:allow(TweenTarget)
class TweenPos {
	public var x:Float = null;
	public var y:Float = null;
	public var z:Float = null;
	public var w:Float = null;
}

/**
	Abstract over TweenPos, providing implicit casting to and from Vector
**/
@:forward
abstract TweenTarget(TweenPos) from TweenPos to TweenPos {
	public inline function new(val:TweenPos) {
		this = val;
	}

	public function clone():TweenTarget {
		return {
			x: this.x,
			y: this.y,
			z: this.z,
			w: this.w,
		};
	}

	/**

	**/
	public function set(tp:TweenTarget, overwriteNulls = false) {
		this.x = (this.x != null || overwriteNulls) ? tp.x : null;
		this.y = (this.y != null || overwriteNulls) ? tp.y : null;
		this.z = (this.z != null || overwriteNulls) ? tp.z : null;
		this.w = (this.w != null || overwriteNulls) ? tp.w : null;
	}

	public function add(tp:TweenTarget) {
		this.x = (this.x != null) ? this.x + tp.x : null;
		this.y = (this.y != null) ? this.y + tp.y : null;
		this.z = (this.z != null) ? this.z + tp.z : null;
		this.w = (this.w != null) ? this.w + tp.w : null;
	}

	@:from
	public static function fromVector(v:Vector) {
		return new TweenTarget({
			x: v.x,
			y: v.y,
			z: v.z,
			w: v.w,
		});
	}

	@:to
	public function toVector():Vector {
		if (this == null) {
			return null;
		}
		return new Vector(this.x.or(0.0), this.y.or(0.0), this.z.or(0.0), this.w.or(1.0));
	}
}

/**
	Holds vector data adding tweening functionality
**/
@:forward
abstract TweenVector(TweenVectorBacking) from TweenVectorBacking to TweenVectorBacking {
	public inline function new(x:Float, y:Float, z:Float, w:Float = 1.0) {
		this = new TweenVectorBacking(x, y, z, w);
	}

	/**
		Tween values to target
		@param target Tweening config
	**/
	public function tween(target:VectorTween):Future<Bool> {
		return Future.async(done -> {
			// Find _activeTweens already animating the target properties
			if (this._activeTweens == null) {
				this._activeTweens = [];
			}

			final hasFrom = target.from != null;
			final hasTo = target.to != null;

			Assert.that(target.to != null || target.from != null, 'Must supply to or from to tween');

			// Ensure all input values have a valid start and endpoint
			// If no target is specified. Tween to position at activation time
			if (!hasTo) {
				// Clone target from to preserve nulls
				target.to = target.from.clone();
				target.to.set(this);
			}

			// If only target is specified. Tween from origin
			if (!hasFrom) {
				// Clone target from to preserve nulls
				target.from = target.to.clone();
				target.from.set(this);
			}

			// Add relative coords if needed
			if (target.relative) {
				if (hasTo) {
					target.to.add(this);
				}
				if (hasFrom) {
					target.from.add(this);
				}
			}

			// Replace on going tweens
			cancelUsedAxis(target);

			target.time = 0.0;
			// Add animation
			this._activeTweens.push(target);
			target.onDone = (tweenDone:Bool) -> {
				this._activeTweens.remove(target);
				done(tweenDone);
			}
		});
	}

	public function cancelUsedAxis(t:VectorTween) {
		if (this._activeTweens != null) {
			var remove = [];
			for (tween in this._activeTweens) {
				// Replace axis if input not null
				tween.to.x = t.to.x == null ? tween.to.x : null;
				tween.to.y = t.to.y == null ? tween.to.y : null;
				tween.to.z = t.to.z == null ? tween.to.z : null;
				tween.to.w = t.to.w == null ? tween.to.w : null;

				// All parts gone? Remove tween
				if (tween.to.x == null && tween.to.y == null && tween.to.z == null && tween.to.w == null) {
					remove.push(tween);
				}
			}
			for (tween in remove) {
				tween.onDone(false);
				this._activeTweens.remove(tween);
			}
		}
	}

	inline public function set(x:Float, y:Float, z:Float, w:Float = null) {
		this.x = x.or(this.x);
		this.y = y.or(this.y);
		this.z = z.or(this.z);
		this.w = w.or(this.w);
	}

	inline public function scale(s:Float) {
		this.x *= s;
		this.y *= s;
		this.z *= s;
		this.w *= s;
	}

	inline public function reset() {
		cancel();
		this._activeTweens = [];
	}

	public function cancel() {
		if (this._activeTweens != null) {
			for (tween in this._activeTweens) {
				cancelTween(tween);
			}
		}
	}

	/**
		Stop repetition of all active tweens, results in onDone when current repetition is complete
	**/
	public function stopRepeat() {
		if (this._activeTweens != null) {
			for (tween in this._activeTweens) {
				tween.repeat = false;
			}
		}
	}

	/**
		Instantly finish all active tweens
	**/
	public function finish() {
		if (this._activeTweens != null) {
			for (tween in this._activeTweens) {
				tween.time = tween.duration + tween.delay;
			}
		}
	}

	public function clone() {
		return new TweenVector(this.x, this.y, this.z, this.w);
	}

	function cancelTween(tween:VectorTween) {
		tween.to.x = null;
		tween.to.y = null;
		tween.to.z = null;
		tween.to.w = null;
		tween.onDone(false);
	}

	/**
		Update current animating vector
		@param dt Delta time
	**/
	public function update(dt:Float) {
		final tweening = this._activeTweens != null && this._activeTweens.length > 0;
		if (!tweening) {
			return false;
		}

		for (tween in this._activeTweens) {
			tween.time += dt;
			if (tween.time < tween.delay) {
				continue;
			}
			var done = false;
			var p = (tween.time - tween.delay) / tween.duration;
			if (p >= 1.0) {
				done = tween.repeat ? false : true;
				tween.time = tween.repeat ? 0.0 : tween.time;
				p = 1.0;
			}
			final curveDuration = tween.curveDuration.or(tween.duration);
			final curveStart = tween.duration - Math.min(tween.curveDuration, tween.duration);
			final curvePart = curveStart / tween.duration;

			// Animate X
			if (tween.to.x != null) {
				if (tween.curveDuration != null) {
					final curveStart = tween.to.x - ((tween.to.x - tween.from.x) * curvePart);
					if (p < 1 - curvePart) {
						this.x = p.lerp(tween.from.x, curveStart);
					} else {
						this.x = tween.curve(p).lerp(curveStart, tween.to.x);
					}
				} else {
					this.x = tween.curve(p).lerp(tween.from.x, tween.to.x);
				}
			}

			// Animate Y
			if (tween.to.y != null) {
				if (tween.curveDuration != null) {
					final curveStart = tween.to.y - ((tween.to.y - tween.from.y) * curvePart);
					if (p < 1 - curvePart) {
						this.y = p.lerp(tween.from.y, curveStart);
					} else {
						this.y = tween.curve(p).lerp(curveStart, tween.to.y);
					}
				} else {
					this.y = tween.curve(p).lerp(tween.from.y, tween.to.y);
				}
			}

			// Animate Z
			if (tween.to.z != null) {
				if (tween.curveDuration != null) {
					final curveStart = tween.to.z - ((tween.to.z - tween.from.z) * curvePart);
					if (p < 1 - curvePart) {
						this.z = p.lerp(tween.from.z, curveStart);
					} else {
						this.z = tween.curve(p).lerp(curveStart, tween.to.z);
					}
				} else {
					this.z = tween.curve(p).lerp(tween.from.z, tween.to.z);
				}
			}

			// Animate W
			if (tween.to.w != null) {
				if (tween.curveDuration != null) {
					final curveStart = tween.to.w - ((tween.to.w - tween.from.w) * curvePart);
					if (p < 1 - curvePart) {
						this.w = p.lerp(tween.from.w, curveStart);
					} else {
						this.w = tween.curve(p).lerp(curveStart, tween.to.w);
					}
				} else {
					this.w = tween.curve(p).lerp(tween.from.w, tween.to.w);
				}
			}

			if (done) {
				tween.onDone(true);
				continue;
			}
		}
		return true;
	}

	@:from
	inline public static function fromTweenPos(v:TweenPos):TweenVector {
		return new TweenVector(v.x, v.y, v.z, v.w);
	}

	@:from
	inline public static function fromVector(v:Vector):TweenVector {
		return new TweenVector(v.x, v.y, v.z, v.w);
	}

	@:to
	inline public function toVector():Vector {
		return cast this;
	}
}

/**
	Backing class for TweenVector to hold active tweens
**/
class TweenVectorBacking extends Vector {
	/**
		Returns true if an animation is active
	**/
	public var isTweening(get, never):Bool;

	// All active animations
	@:allow(gasm.heaps.transform.TweenVector)
	var _activeTweens:Array<VectorTween>;

	public function new(x = 0.0, y = 0.0, z = 0.0, w = 1.0) {
		super(x, y, z, w);
		_activeTweens = [];
	}

	public function dispose() {
		_activeTweens = null;
	}

	function get_isTweening():Bool {
		return _activeTweens != null && _activeTweens.length > 0;
	}
}
