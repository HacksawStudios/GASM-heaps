package gasm.heaps.types;

/**
	Abstract Int with implicit conversions from float and string
**/
@:forward
@:forwardStatics
abstract IntVal(Int) from Int to Int {
	inline public function new(val:Int) {
		this = val;
	}

	@:from static inline public function fromFloat(val:Int) {
		final int:Int = cast val;
		return new IntVal(int);
	}

	@:from static inline public function fromString(val:String) {
		return new IntVal(Std.parseInt(val));
	}

	@:from static inline public function fromDynamic(val:Dynamic) {
		return new IntVal(Std.parseInt(Std.string(val)));
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

	@:op(A == B) function eq(b) {
		return this == b;
	}

	@:op(A <= B) function leq(b) {
		return this <= b;
	}

	@:op(A >= B) function beq(b) {
		return this >= b;
	}
}
