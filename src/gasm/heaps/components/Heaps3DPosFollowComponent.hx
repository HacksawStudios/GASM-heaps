package gasm.heaps.components;

import gasm.core.Component;
import gasm.core.enums.ComponentType;
import gasm.core.utils.Assert;

class Heaps3DPosFollowComponent extends Component {
	public var freeze = false;

	final _config:Heaps3DPosFollowConfig;
	var _comp:Heaps3DComponent;

	public var offset:h3d.Vector;

	public function new(config:Heaps3DPosFollowConfig) {
		_config = config;
		componentType = ComponentType.Actor;
		offset = _config.offset;
	}

	override public function init() {
		_comp = owner.get(Heaps3DComponent);
		Assert.that(_comp != null, 'Heaps3DScaleFollowComponent needs to be added to an entity with a Heaps3DComponent');
	}

	override public function update(dt:Float) {
		if (!freeze) {
			final o = _comp.object;
			final follow = _config.follow;
			final offsetScaleX = switch (_config.offsetScaleFollow) {
				case OffsetScaleFollow.None: 1.0;
				case OffsetScaleFollow.This: o.scaleX;
				case OffsetScaleFollow.Target: follow.scaleX;
			}
			final offsetScaleY = switch (_config.offsetScaleFollow) {
				case OffsetScaleFollow.None: 1.0;
				case OffsetScaleFollow.This: o.scaleY;
				case OffsetScaleFollow.Target: follow.scaleY;
			}
			final offsetScaleZ = switch (_config.offsetScaleFollow) {
				case OffsetScaleFollow.None: 1.0;
				case OffsetScaleFollow.This: o.scaleZ;
				case OffsetScaleFollow.Target: follow.scaleZ;
			}
			o.x = follow.x + (offset.x * offsetScaleX);
			o.y = follow.y + (offset.y * offsetScaleY);
			o.z = follow.z + (offset.z * offsetScaleZ);
		}
	}
}

enum OffsetScaleFollow {
	None;
	This;
	Target;
}

@:structInit
class Heaps3DPosFollowConfig {
	public var follow:h3d.scene.Object;
	public var offset = new h3d.Vector(0, 0, 0);
	public var offsetScaleFollow = OffsetScaleFollow.None;
}
