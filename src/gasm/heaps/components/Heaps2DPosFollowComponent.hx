package gasm.heaps.components;

import gasm.core.Component;
import gasm.core.enums.ComponentType;
import gasm.core.utils.Assert;

@:deprecated("Please use HeapsPosFollow instead")
class Heaps2DPosFollowComponent extends Component {
	public var freeze = false;

	final _config:Heaps2DPosFollowConfig;
	var _comp:HeapsSpriteComponent;

	public function new(config:Heaps2DPosFollowConfig) {
		_config = config;
		componentType = ComponentType.Actor;
	}

	override public function init() {
		_comp = owner.get(HeapsSpriteComponent);
		Assert.that(_comp != null, 'Heaps2DPosFollowComponent needs to be added to an entity with a Heaps2DComponent');
	}

	override public function update(dt:Float) {
		if (!freeze) {
			final o = _comp.sprite;
			final offset = _config.offset;
			final follow = _config.follow;
			o.x = follow.x + offset.x;
			o.y = follow.y + offset.y;
		}
	}

	public function setOffset(x:Float, y:Float) {
		_config.offset.x = x;
		_config.offset.y = y;
	}
}

@:structInit
class Heaps2DPosFollowConfig {
	public var follow:h2d.Object;
	public var offset = new h2d.col.Point(0, 0);
}
