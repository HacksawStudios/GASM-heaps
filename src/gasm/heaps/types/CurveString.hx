package gasm.heaps.types;

import tweenxcore.Tools.Easing;
import tweenxcore.Tools.FloatTools;

/**
	Abstract over String to describe motion curves

	Has Math, tweenxcore.Tools.Easing and tweenxcore.Tools.FloatTools available.
	Input value is named 'rate'

	@examples
	"Math.sin(rate)" will become this when cast to a Float->Float `rate -> Math.sin(rate)`
	"Easing.expoIn(rate)" becomes `rate -> rate.expoIn()`
**/
abstract CurveString(String) from String to String {
	inline public function new(str:String) {
		this = str;
	}

	@:to inline public function toFunc():(rate:Float) -> Float {
		return rate -> {
			final parser = new hscript.Parser();
			final program = parser.parseString(this);
			final interp = new hscript.Interp();
			interp.variables.set('Math', Math);
			interp.variables.set('rate', rate);
			interp.variables.set('Easing', Easing);
			interp.variables.set('FloatTools', FloatTools);
			interp.execute(program);
		}
	}
}
