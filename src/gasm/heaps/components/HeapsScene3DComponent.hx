package gasm.heaps.components;

import gasm.core.Component;
import gasm.core.enums.ComponentType;

class HeapsScene3DComponent extends HeapsSceneComponent {
	public var scene3d:h3d.scene.Scene;

	public function new(scene:h3d.scene.Scene) {
		super(scene);
		componentType = ComponentType.Model;
		this.scene3d = scene;
	}
}
