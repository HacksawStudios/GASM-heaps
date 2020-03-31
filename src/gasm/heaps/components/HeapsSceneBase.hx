package gasm.heaps.components;

import gasm.core.Component;
import gasm.core.enums.ComponentType;

class HeapsSceneBase extends Component {
	public var scene:Any;
	static public var sceneCounter = 0;
	final _sceneId:Int;

	public function new(scene:Any) {
		_sceneId = sceneCounter++;
		this.scene = scene;
	}
}
