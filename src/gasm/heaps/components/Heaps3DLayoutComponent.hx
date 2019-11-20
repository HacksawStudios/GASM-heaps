package gasm.heaps.components;

import h3d.scene.Object;
import gasm.core.Component;
import gasm.core.api.singnals.TResize;
import gasm.core.components.AppModelComponent;
import gasm.core.components.ThreeDModelComponent;
import gasm.core.enums.ScaleType;
import gasm.core.enums.Anchor;
import gasm.core.enums.ComponentType;
import gasm.core.math.geom.Point;
import gasm.core.math.geom.Vector;
import gasm.core.utils.Assert;
import h3d.scene.Scene;

class Heaps3DLayoutComponent extends Component {
	public var enabled = true;

	final _config:Heaps3DLayoutConfig;
	final _margins:Margins;
	var _s3d:Scene;
	var _sceneComponent:HeapsScene3DComponent;
	var _comp:Heaps3DComponent;
	var _appModel:AppModelComponent;
	var _stageW = 0.0;
	var _stageH = 0.0;
	var _model:ThreeDModelComponent;

	public function new(config:Heaps3DLayoutConfig) {
		componentType = Actor;
		_config = config;
		_margins = _config.margins;
	}

	override public function init() {
		_sceneComponent = owner.getFromParents(HeapsScene3DComponent);
		Assert.that(_sceneComponent != null, 'Heaps3DLayoutComponent needs to be on a scene with a HeapsScene3DComponent.');
		_s3d = _sceneComponent.scene3d;
		_comp = owner.get(Heaps3DComponent);
		Assert.that(_comp != null, 'Heaps3DLayoutComponent needs to be in an enitity with a Heaps3DComponent.');
		_appModel = owner.getFromParents(AppModelComponent);
		_model = owner.get(ThreeDModelComponent);
		layout();
		super.init();
	}

	override public function dispose() {
		_comp = null;
		_s3d = null;
		super.dispose();
	}

	public function updateMargins(m:Margins) {
		_margins.top = m.top != null ? m.top : _margins.top;
		_margins.bottom = m.bottom != null ? m.bottom : _margins.bottom;
		_margins.left = m.left != null ? m.left : _margins.left;
		_margins.right = m.right != null ? m.right : _margins.right;
		layout();
	}

	override public function update(dt:Float) {
		if (_s3d == null) {
			_s3d = _sceneComponent.scene3d;
			if (_s3d != null) {
				layout();
			}
		}
	}

	public function layout() {
		if (_appModel == null || !enabled || _s3d == null) {
			return;
		}

		_stageW = _appModel.stageSize.x;
		_stageH = _appModel.stageSize.y;
		final zDepth = _s3d.camera.zFar - _s3d.camera.zNear;
		final zPos = (_s3d.camera.zNear + _comp.object.z) / zDepth;
		_sceneComponent.syncCamera();
		final p = _s3d.camera.project(_comp.object.x, _comp.object.y, _comp.object.z, _stageW, _stageH);
		final bottomLeft = _s3d.camera.unproject(-1, -1, p.z);
		final topRight = _s3d.camera.unproject(1, 1, p.z);
		final width = Math.abs(bottomLeft.x - topRight.x);
		final height = Math.abs(bottomLeft.y - topRight.y);
		var size:h3d.col.Point;
		if (_config.size != null) {
			size = new h3d.col.Point(_config.size.x, _config.size.y, 0);
		} else {
			final bounds = _comp.object.getBounds();
			size = bounds.getSize();
			// If size is empty we are trying to layout too early
			if (size.x == -2e20) {
				haxe.Timer.delay(layout, 10);
				return;
			}
			_config.size = {x: size.x, y: size.y};
		}

		switch _config.scale {
			case PROPORTIONAL:
				scaleProportional(width, height, size, _comp.object);
			case FIT:
				scaleFit(width, height, size, _comp.object);
			case CROP:
				scaleCrop(width, height, size, _comp.object);
			default:
				null;
		}

		if (_config.anchor != null) {
			final sz = _comp.object.getBounds().getSize();
			_comp.object.x = switch (_config.anchor) {
				case Anchor.RIGHT: (topRight.x - sz.x * 0.5);
				case Anchor.LEFT: (bottomLeft.x + sz.x * 0.5);
				default: _comp.object.x;
			}
			_comp.object.y += switch (_config.anchor) {
				case Anchor.TOP: (topRight.y - sz.y * 0.5);
				case Anchor.BOTTOM: (bottomLeft.y + sz.y * 0.5);
				default: _comp.object.y;
			}
		}

		// Update model to ensure it will not misbehave if it becomes dirty by changing a prop
		_model.pos = new Vector(_comp.object.x, _comp.object.y, _comp.object.z);
		_model.scale = new Vector(_comp.object.scaleX, _comp.object.scaleY, _comp.object.scaleZ);
		_model.dirty = false;
	}

	function onResize(?size:TResize) {
		layout();
	}

	function scaleProportional(width:Float, height:Float, size:h3d.col.Point, object:Object) {
		var tMarg = 0.0;
		var bMarg = 0.0;
		var lMarg = 0.0;
		var rMarg = 0.0;
		if (_margins != null) {
			lMarg = _margins.left != null ? _margins.left * 0.01 : 0;
			rMarg = _margins.right != null ? _margins.right * 0.01 : 0;
			tMarg = _margins.top != null ? _margins.top * 0.01 : 0;
			bMarg = _margins.bottom != null ? _margins.bottom * 0.01 : 0;
		}
		final xoff = lMarg + rMarg;
		final yoff = tMarg + bMarg;
		final xRatio = Math.abs((width / size.x) * (1 - xoff));
		final yRatio = Math.abs((height / size.y) * (1 - yoff));

		final ratio = Math.min(xRatio, yRatio);

		object.setScale(ratio);

		object.x = width * (lMarg - (xoff * 0.5));
		object.y = height * (bMarg - (yoff * 0.5));
	}

	function scaleFit(width:Float, height:Float, size:h3d.col.Point, object:Object) {
		Assert.that(_margins == null, 'Margins for FIT scale to be done...');
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

	function scaleCrop(width:Float, height:Float, size:h3d.col.Point, object:Object) {
		var size:h3d.col.Point;
		if (_config.size != null) {
			size = new h3d.col.Point(_config.size.x, _config.size.y, 0);
		} else {
			final bounds = object.getBounds();
			size = bounds.getSize();
			// If size is empty we are trying to layout too early
			if (size.x == -2e20) {
				haxe.Timer.delay(layout, 10);
				return;
			}
			_config.size = {x: size.x, y: size.y};
		}
		var tMarg = 0.0;
		var bMarg = 0.0;
		var lMarg = 0.0;
		var rMarg = 0.0;
		if (_margins != null) {
			lMarg = _margins.left != null ? _margins.left * 0.01 : 0;
			rMarg = _margins.right != null ? _margins.right * 0.01 : 0;
			tMarg = _margins.top != null ? _margins.top * 0.01 : 0;
			bMarg = _margins.bottom != null ? _margins.bottom * 0.01 : 0;
		}
		final xoff = lMarg + rMarg;
		final yoff = tMarg + bMarg;
		final xRatio = Math.abs((width / size.x) - xoff);
		final yRatio = Math.abs((height / size.y) - yoff);
		final shortest = Math.min(xRatio, yRatio);
		final longest = xRatio == shortest ? yRatio : xRatio;
		final ratio = xRatio == longest ? Math.abs(longest - xoff) : Math.abs(longest - yoff);
		object.setScale(ratio);
		object.x = xRatio == ratio ? lMarg - (xoff * 0.5) : 0;
		object.y = yRatio == ratio ? bMarg - (yoff * 0.5) : 0;
	}
}

@:structInit
class Heaps3DLayoutConfig {
	public var scale = ScaleType.PROPORTIONAL;
	public var margins:Null<Margins> = null;
	public var size:Null<Point> = null;
	public var anchor:Null<Anchor> = null;
}

@:structInit
class Margins {
	public var bottom:Null<Float> = null;
	public var top:Null<Float> = null;
	public var left:Null<Float> = null;
	public var right:Null<Float> = null;
}
