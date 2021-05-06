package gasm.heaps.types;

/**
	Abstract Int with implicit conversions from float and string
**/
@:forward
@:forwardStatics
abstract IntVal(Int) from Int {
	inline public function new(val:Int) {
		this = val;
	}

	@:to inline public function toInt():Int {
		return Std.int(this);
	}

	@:from static inline public function fromString(val:String) {
		return new IntVal(Std.parseInt(val));
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
