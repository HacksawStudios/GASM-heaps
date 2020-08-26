package gasm.heaps.components;

import gasm.core.Component;
import gasm.core.Entity;
import gasm.core.enums.ComponentType;
import gasm.core.utils.Assert;

/**

**/
class HeapsCameraFollowCameraComponent extends Component {
	final _config:HeapsCameraFollowComponentConfig;
	var _target:h3d.Camera;

	public function new(config:HeapsCameraFollowComponentConfig) {
		_config = config;
		componentType = ComponentType.Actor;
	}

	override public function init() {
		final scene = owner.get(HeapsScene3DComponent);

		Assert.that(scene != null, "HeapsCameraFollowComponent must have a HeapsScene3DComponent in its owner");

		_target = scene.scene3d.camera;
	}

	override public function update(dt:Float) {
		_target.pos.load(_config.follow.pos);
	}
}

@:structInit
class HeapsCameraFollowComponentConfig {
	/**
		Follow this camera
	**/
	public var follow:h3d.Camera;
}
