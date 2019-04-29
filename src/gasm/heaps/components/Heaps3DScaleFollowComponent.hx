package gasm.heaps.components;

import gasm.core.Component;
import gasm.core.enums.ComponentType;
import gasm.core.utils.Assert;

class Heaps3DScaleFollowComponent extends Component {
	final _config:Heaps3DScaleFollowConfig;
	var _comp:Heaps3DComponent;

	public function new(config:Heaps3DScaleFollowConfig) {
		_config = config;
		componentType = ComponentType.Actor;
	}

	override public function init() {
		_comp = owner.get(Heaps3DComponent);
		Assert.that(_comp != null, 'Heaps3DScaleFollowComponent needs to be added to an entity with a Heaps3DComponent');
	}

	override public function update(dt:Float) {
		_comp.object.scaleX = _config.follow.scaleX * _config.scale;
		_comp.object.scaleY = _config.follow.scaleY * _config.scale;
		_comp.object.scaleZ = _config.follow.scaleZ * _config.scale;
	}
}

@:structInit
class Heaps3DScaleFollowConfig {
	public var follow:h3d.scene.Object;
	public var scale = 1.0;
}