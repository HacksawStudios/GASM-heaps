package gasm.heaps.types;

/**
	Abstract Float with implicit conversions from int and string

	Useful when you have for example json data which will result in 1.0 being parsed as Int instead of float since js doesn't have the distiction.
	If you type to Number, 1.0, 1, '1', '1.0' will all result in a Float with value 1.0
**/
@:forward
@:forwardStatics
abstract Number(Float) from Float to Float {
	inline public function new(val:Float) {
		this = val;
	}

	@:to inline public function toInt() {
		return Std.int(this);
	}

	@:from static inline public function fromInt(val:Int) {
		final float:Float = cast val;
		return new Number(float);
	}

	@:from static inline public function fromString(val:String) {
		return new Number(Std.parseFloat(val));
	}

	@:op(A + B) function add(b) {
		return this + b;
	}

	@:op(A - B) function sub(b) {
		return this - b;
	}

	@:op(A * B) function mult(b) {
		return this * b;
	}
}
