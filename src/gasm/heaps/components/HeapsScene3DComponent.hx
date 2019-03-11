package gasm.heaps.components;

import gasm.core.Component;
import gasm.core.enums.ComponentType;

class HeapsScene3DComponent extends HeapsSceneBase {
	public var scene3d:h3d.scene.Scene;

	public function new(scene:h3d.scene.Scene) {
		componentType = ComponentType.Model;
		this.scene3d = scene;
		super(scene);
	}
}