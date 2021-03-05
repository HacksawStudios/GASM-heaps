package gasm.heaps.components;

import gasm.core.Component;
import gasm.core.components.AppModelComponent;
import gasm.core.enums.ComponentType;
import gasm.heaps.components.HeapsScene3DComponent;
import h3d.Vector;

using Safety;

class Heaps3DViewportComponent extends Component {
	public var fov(default, set):Float;
	public var fovRatio(default, set):Float;

	var _config:Heaps3DViewportConfig;
	var _scale:Float;
	var _s3d:h3d.scene.Scene;
	var _hasBounds = false;
	var _appModel:AppModelComponent;

	public function new(config:Heaps3DViewportConfig) {
		_config = config;
		componentType = ComponentType.Actor;
	}

	public function getSizeAtZ(z:Float) {
		var a = _s3d.camera.unproject(1.0, 1.0, z);
		var b = _s3d.camera.unproject(-1.0, -1.0, z);
		return new h3d.Vector(Math.abs(a.x - b.x), Math.abs(a.y - b.y), z);
	}

	override public function init() {
		_appModel = owner.getFromParents(AppModelComponent);
		_s3d = owner.getFromParents(HeapsScene3DComponent).scene3d;
		final cam = _s3d.camera;
		cam.pos = _config.cameraPos;
		if (_config.rightHanded) {
			cam.rightHanded = true;
			cam.up = new h3d.Vector(0, 1, 0);
		}
		cam.target = _config.cameraTarget;
		cam.zNear = _config.zNear;
		cam.zFar = _config.zFar;

		fovRatio = _config.fovRatio;
		fov = _config.fov;
	}

	function set_fov(val:Float) {
		fov = val;
		_s3d.camera.setFovX(fov, fovRatio);
		return val;
	}

	function set_fovRatio(val:Float) {
		fovRatio = val;
		fov = fov;
		return val;
	}
}

@:structInit
class Heaps3DViewportConfig {
	public var name = 'default';
	public var cameraPos = new Vector(2, 3, 4);
	public var cameraTarget = new Vector(-0.00001);
	public var zNear = 1.0;
	public var zFar = 100.0;
	public var fov:Float = 45;
	public var fovRatio:Float = 16 / 9;
	public var rightHanded = true;
}
