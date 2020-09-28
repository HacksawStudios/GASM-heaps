package gasm.heaps.types;

import gasm.heaps.transform.TweenVector.TweenPos;

@:structInit
class TweenDef {
	public var type:TweenType;
	public var from:TweenPos;
	public var to:TweenPos;
	public var duration:Number;
	public var curve:CurveString = null;

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
