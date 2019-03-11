package gasm.heaps.components;

import gasm.core.Component;
import gasm.core.enums.ComponentType;
import gasm.heaps.components.HeapsScene3DComponent;
import h3d.Vector;

class Heaps3DViewportComponent extends Component {
	var _config:Heaps3DViewportConfig;
	var _scale:Float;
	var _s3d:h3d.scene.Scene;
	var _hasBounds = false;

	public function new(config:Heaps3DViewportConfig) {
		_config = config;
		componentType = ComponentType.Actor;
	}

	override public function init() {
		_s3d = owner.getFromParents(HeapsScene3DComponent).scene3d;
		var cam = _s3d.camera;
		cam.pos = _config.cameraPos;
		cam.target = _config.cameraTarget;
		cam.zNear = _config.zNear;
		cam.zFar = _config.zFar;
		if (_config.fov != null) {
			cam.setFovX(_config.fov, cam.screenRatio);
		}
		_s3d.visible = false;
	}

	override public function update(dt:Float) {
		if (!_hasBounds) {
			var bounds = _config.boundsObject.getBounds();
			// Empty bounds has values between -1e20 and 1e20
			if (bounds.xMin != 1e20) {
				_s3d.visible = true;
				var top = bounds.ySize;
				var right = bounds.xSize;
				var pixelRatio = js.Browser.window.devicePixelRatio;
				var w = _config.bounds2d.width / pixelRatio;
				var h = _config.bounds2d.height / pixelRatio;
				var wFactor = top / w;
				var hFactor = right / h;
				var wRatio = w * wFactor * _config.boundsMult.x;
				var hRatio = h * hFactor * _config.boundsMult.y;
				var ratio = Math.min(wRatio, hRatio);
				if (_scale != ratio) {
					_s3d.setScale(ratio);
					_s3d.camera.update();
					_scale = ratio;
					if (_config.fov != null) {
						_s3d.camera.setFovX(_config.fov, ratio);
					}
				}
				_hasBounds = true;
			}
		}
	}
}

@:structInit
class Heaps3DViewportConfig {
	public var boundsObject:h3d.scene.Object;
	public var boundsMult = new Vector(1, 1, 1);
	public var bounds2d:h2d.col.Bounds;
	public var cameraPos = new Vector(2, 3, 4);
	public var cameraTarget = new Vector(-.00001);
	public var zNear = 1.;
	public var zFar = 100.;
	public var fov:Null<Float> = null;
}
