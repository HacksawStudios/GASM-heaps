package gasm.heaps.components;

import gasm.core.Component;
import gasm.core.enums.ComponentType;

class HeapsScene2DComponent extends HeapsSceneComponent {
	public var scene2d:h2d.Scene;

	public function new(scene:h2d.Scene) {
		super(scene);
		componentType = ComponentType.Model;
		this.scene2d = scene;
	}
}
