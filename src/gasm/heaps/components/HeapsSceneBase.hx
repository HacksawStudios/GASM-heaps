package gasm.heaps.components;

import gasm.core.Component;
import gasm.core.enums.ComponentType;

class HeapsSceneBase extends Component {
	public var scene:Any;

	public function new(scene:Any) {
		this.scene = scene;
	}
}
