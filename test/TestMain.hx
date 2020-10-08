import buddy.*;

using buddy.Should;

// Implement "Buddy" and define an array of classes within the brackets:
class TestMain implements Buddy<[ //
	gasm.heaps.types.NumberTest, //
	gasm.heaps.types.CurveStringTest,]> {}
