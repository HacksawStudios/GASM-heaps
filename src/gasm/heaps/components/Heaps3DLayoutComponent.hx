package gasm.heaps.components;

import h3d.scene.Object;
import gasm.core.Component;
import gasm.core.api.singnals.TResize;
import gasm.core.components.AppModelComponent;
import gasm.core.enums.ScaleType;
import gasm.core.enums.ComponentType;
import gasm.core.math.geom.Point;
import gasm.core.utils.Assert;
import gasm.core.utils.SignalConnection;
import h3d.scene.Scene;

class Heaps3DLayoutComponent extends Component {
	public final margins:Margins;

	final _config:Heaps3DLayoutConfig;
	var _s3d:Scene;
	var _comp:Heaps3DComponent;
	var _resizeConnection:SignalConnection;
	var _appModel:AppModelComponent;
	var _stageW = 0.0;
	var _stageH = 0.0;
	var _origSize:h3d.col.Point;

	public function new(config:Heaps3DLayoutConfig) {
		componentType = Actor;
		_config = config;
		margins = _config.margins;
	}

	override public function init() {
		var sceneComp = owner.getFromParents(HeapsScene3DComponent);
		Assert.that(sceneComp != null, 'Heaps3DLayoutComponent needs to be on a scene with a HeapsScene3DComponent.');
		_s3d = sceneComp.scene3d;
		_comp = owner.getFromParents(Heaps3DComponent);
		Assert.that(_comp != null, 'Heaps3DLayoutComponent needs to be in an enitity with a Heaps3DComponent.');
		_appModel = owner.getFromParents(AppModelComponent);
		_resizeConnection = _appModel.resizeSignal.connect(onResize);
		_origSize = _comp.object.getBounds().getSize();
		// HACK: For some reason layout need repeated triggers, which should not be the case, espacially since unlike 2d layout it is not heirarchical
		haxe.Timer.delay(layout, 0);
		haxe.Timer.delay(layout, 50);
		haxe.Timer.delay(layout, 100);
		haxe.Timer.delay(layout, 150);
		haxe.Timer.delay(() -> {
			layout();
		}, 200);
		super.init();
	}

	override public function dispose() {
		_comp = null;
		_s3d = null;
		_appModel.resizeSignal.disconnect(_resizeConnection);
		super.dispose();
	}

	function onResize(?size:TResize) {
		layout();
		haxe.Timer.delay(layout, 100);
	}

	function layout() {
		_stageW = _appModel.stageSize.x;
		_stageH = _appModel.stageSize.y;
		final zDepth = _s3d.camera.zFar - _s3d.camera.zNear;
		final zPos = (_s3d.camera.zNear + _comp.object.z) / zDepth;
		_s3d.camera.update();
		final p = _s3d.camera.project(_comp.object.x, _comp.object.y, _comp.object.z, _stageW, _stageH);
		final a = _s3d.camera.unproject(-1, -1, p.z);
		final b = _s3d.camera.unproject(1, 1, p.z);
		final width = Math.abs(a.x - b.x);
		final height = Math.abs(a.y - b.y);
		final depth = a.z;

		switch _config.scale {
			case PROPORTIONAL:
				scaleProportional(width, height, _comp.object);
			case FIT:
				scaleFit(width, height, _comp.object);
			case CROP:
				scaleCrop(width, height, _comp.object);
		}
	}

	function scaleProportional(width:Float, height:Float, object:Object) {
		var size:h3d.col.Point;
		if (_config.size != null) {
			size = new h3d.col.Point(_config.size.x, _config.size.y, 0);
		} else {
			final bounds = object.getBounds();
			size = bounds.getSize();
		}
		var tMarg = 0.0;
		var bMarg = 0.0;
		var lMarg = 0.0;
		var rMarg = 0.0;
		if (margins != null) {
			lMarg = margins.left != null ? margins.left * 0.01 : 0;
			rMarg = margins.right != null ? margins.right * 0.01 : 0;
			tMarg = margins.top != null ? margins.top * 0.01 : 0;
			bMarg = margins.bottom != null ? margins.bottom * 0.01 : 0;
		}
		final xoff = lMarg + rMarg;
		final yoff = tMarg + bMarg;
		final xRatio = Math.abs((width / size.x) - yoff);
		final yRatio = Math.abs((height / size.y) - xoff);
		final ratio = Math.min(xRatio, yRatio);

		object.scale(ratio);
		object.x = xRatio == ratio ? tMarg - (yoff * 0.5) : 0;
		object.y = yRatio == ratio ? rMarg - (xoff * 0.5) : 0;
	}

	function scaleFit(width:Float, height:Float, object:Object) {
		Assert.that(margins == null, 'Margins for FIT scale to be done...');
		var size:h3d.col.Point;
		if (_config.size != null) {
			size = new h3d.col.Point(_config.size.x, _config.size.y, 0);
		} else {
			final bounds = object.getBounds();
			size = bounds.getSize();
		}
		final xRatio = Math.abs((width / size.x));
		final yRatio = Math.abs((height / size.y));
		object.scaleX = xRatio;
		object.scaleY = yRatio;
	}

	function scaleCrop(width:Float, height:Float, object:Object) {
		var size:h3d.col.Point;
		if (_config.size != null) {
			size = new h3d.col.Point(_config.size.x, _config.size.y, 0);
		} else {
			final bounds = object.getBounds();
			size = bounds.getSize();
		}
		var tMarg = 0.0;
		var bMarg = 0.0;
		var lMarg = 0.0;
		var rMarg = 0.0;
		if (margins != null) {
			lMarg = margins.left != null ? margins.left * 0.01 : 0;
			rMarg = margins.right != null ? margins.right * 0.01 : 0;
			tMarg = margins.top != null ? margins.top * 0.01 : 0;
			bMarg = margins.bottom != null ? margins.bottom * 0.01 : 0;
		}
		final xoff = lMarg + rMarg;
		final yoff = tMarg + bMarg;
		final xRatio = Math.abs((width / size.x) - yoff);
		final yRatio = Math.abs((height / size.y) - xoff);
		final shortest = Math.min(xRatio, yRatio);
		final longest = xRatio == shortest ? yRatio : xRatio;
		final ratio = xRatio == longest ? Math.abs(longest - yoff) : Math.abs(longest - xoff);
		object.setScale(ratio);
		object.x = xRatio == ratio ? tMarg - (yoff * 0.5) : 0;
		object.y = yRatio == ratio ? rMarg - (xoff * 0.5) : 0;
	}
}

@:structInit
class Heaps3DLayoutConfig {
	public var scale = ScaleType.PROPORTIONAL;
	public var margins:Null<Margins> = null;
	public var size:Null<Point> = null;
}

@:structInit
class Margins {
	public var bottom:Null<Float> = null;
	public var top:Null<Float> = null;
	public var left:Null<Float> = null;
	public var right:Null<Float> = null;
}
