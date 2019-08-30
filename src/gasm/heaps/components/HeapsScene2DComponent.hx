package gasm.heaps.components;

import gasm.core.enums.ComponentType;
import gasm.core.components.LayoutComponent;
import gasm.heaps.components.HeapsSceneBase;

class HeapsScene2DComponent extends HeapsSceneBase {
	public var scene2d:h2d.Scene;

	public function new(scene:h2d.Scene) {
		componentType = ComponentType.Model;
		this.scene2d = scene;
		super(scene);
	}
}
