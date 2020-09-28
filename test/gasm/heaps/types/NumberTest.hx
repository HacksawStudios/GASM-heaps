package gasm.heaps.types;

import buddy.BuddySuite;
import gasm.heaps.types.Number;

using buddy.Should;

class NumberTest extends BuddySuite {
	public function new() {
		describe("fromInt", {
			it("should return 1.0 from 1", {
				final int:Int = 1;
				final num:Number = int;
				final float = 1.0;
				num.should.be(float);
			});
			it("should return -999.0 from -999", {
				final int:Int = -999;
				final num:Number = int;
				final float = -999.0;
				num.should.be(float);
			});
		});
		describe("fromString", {
			it("should return 1.0 from '1'", {
				final str:String = '1';
				final num:Number = str;
				final float = 1.0;
				num.should.be(float);
			});
			it("should return 1.0 from '1.000'", {
				final str:String = '1.000';
				final num:Number = str;
				final float = 1.0;
				num.should.be(float);
			});
			it("should return -999.0 from '-999'", {
				final str:String = '-999';
				final num:Number = str;
				final float = -999.0;
				num.should.be(float);
			});
		});
	}
}
