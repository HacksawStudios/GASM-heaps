package gasm.heaps.types;

import gasm.heaps.transform.TweenObject.ObjectTween;
import gasm.heaps.transform.TweenVector.TweenPos;

/**
	Abstract over TweenDef which handles conversion to ObjectTween
**/
abstract TweenConf(TweenDef) from TweenDef to TweenDef {
	public inline function new(val:TweenDef) {
		this = val;
	}

	@:to inline public function toObjectTween():ObjectTween {
		return switch this.type {
			case TweenType.Scale:
				ObjectTween.Scale({
					from: {x: this.from.x, y: this.from.y, z: this.from.z},
					to: {x: this.to.x, y: this.to.y, z: this.to.z},
					duration: this.duration,
					curve: cast(this.curve, CurveString),
				});
			case TweenType.Position:
				ObjectTween.Position({
					from: {x: this.from.x, y: this.from.y, z: this.from.z},
					to: {x: this.to.x, y: this.to.y, z: this.to.z},
					duration: this.duration,
					curve: cast(this.curve, CurveString),
				});
			case TweenType.Color:
				ObjectTween.Color({
					from: {x: this.from.x, y: this.from.y, z: this.from.z},
					to: {x: this.to.x, y: this.to.y, z: this.to.z},
					duration: this.duration,
					curve: cast(this.curve, CurveString),
				});
			case TweenType.Rotate:
				ObjectTween.Rotate({
					from: {x: hxd.Math.degToRad(this.from.x), y: hxd.Math.degToRad(this.from.y), z: hxd.Math.degToRad(this.from.z)},
					to: {x: hxd.Math.degToRad(this.to.x), y: hxd.Math.degToRad(this.to.y), z: hxd.Math.degToRad(this.to.z)},
					duration: this.duration,
					curve: cast(this.curve, CurveString),
				});
		}
	}
}

/**
	TWeen definition
**/
@:structInit class TweenDef {
	/**
		Type of tween (position, scale, color, rotate)
	**/
	public var type:TweenType;

	/**
		Start tween with these values. If omitted tween will start with current values.
	**/
	public var from:TweenPos;

	/**
		Target tween values.
	**/
	public var to:TweenPos;

	/**
		Duration of tween in seconds.
	**/
	public var duration:Number;

	/**
		Curve to use for tweening. @see CurveString for description of notation.
	**/
	public var curve:CurveString = null;

	/**
		Construct TweenDef.

		@param type Type of tween (position, scale, color, rotate)
		@param from Start tween with these values. If omitted tween will start with current values.
		@param to Target tween values.
		@param duration Duration of tween in seconds.
		@param curve Curve to use for tweening. @see CurveString for description of notation.
	**/
	public function new(?type:TweenType, ?from:TweenPos, ?to:TweenPos, ?duration:Number, ?curve:CurveString) {
		this.type = type;
		this.from = from;
		this.to = to;
		this.curve = curve;
		this.duration = duration;
	}
}

enum abstract TweenType(String) from String to String {
	final Rotate = 'rotate';
	final Scale = 'scale';
	final Color = 'color';
	final Position = 'position';
}
