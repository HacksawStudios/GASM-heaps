package gasm.heaps.components;

import gasm.core.Component;
import gasm.core.enums.ComponentType;

class HeapsSceneComponent extends Component {
	public var scene:Any;

	public function new(scene:Any) {
		componentType = ComponentType.Model;
		this.scene = scene;
	}
}
