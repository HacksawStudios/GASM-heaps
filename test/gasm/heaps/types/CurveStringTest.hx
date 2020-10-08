package gasm.heaps.types;

import buddy.BuddySuite;
import gasm.heaps.types.CurveString;

using buddy.Should;

class CurveStringTest extends BuddySuite {
	public function new() {
		describe("fromString", {
			it("should return 0.5 when calling with 0.5 and 'rate' as string", {
				final str = 'rate';
				final curve:CurveString = str;
				final func:(rate:Float) -> Float = curve;
				final res = func(0.5);
				res.should.be(0.5);
			});
			it("should return 0.5 when calling with 1.0 and 'rate / 2' as string", {
				final str = 'rate / 2';
				final curve:CurveString = str;
				final func:(rate:Float) -> Float = curve;
				final res = func(1.0);
				res.should.be(0.5);
			});
			it("should return 0.0 when calling with 0.9 and 'Math.floor(rate)' as string", {
				final str = 'Math.floor(rate)';
				final curve:CurveString = str;
				final func:(rate:Float) -> Float = curve;
				final res = func(0.9);
				res.should.be(0.0);
			});
			it("should return 0.5 when calling with 0.5 and 'Easing.linear(rate)' as string", {
				final str = 'Easing.linear(rate)';
				final curve:CurveString = str;
				final func:(rate:Float) -> Float = curve;
				final res = func(0.5);
				res.should.be(0.5);
			});
			it("should return 0.125 when calling with 0.5 and 'Easing.cubicIn(rate)' as string", {
				final str = 'Easing.cubicIn(rate)';
				final curve:CurveString = str;
				final func:(rate:Float) -> Float = curve;
				final res = func(0.5);
				res.should.be(0.125);
			});
			it("should return 0.1 when calling with 0.0 and 'FloatTools.clamp(rate, 0.1, 0.9)' as string", {
				final str = 'FloatTools.clamp(rate, 0.1, 0.9)';
				final curve:CurveString = str;
				final func:(rate:Float) -> Float = curve;
				final res = func(0.0);
				res.should.be(0.1);
			});
		});
	}
}
