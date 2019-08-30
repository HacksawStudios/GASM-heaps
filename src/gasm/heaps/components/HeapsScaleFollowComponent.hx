package gasm.heaps.components;

import gasm.core.Component;
import gasm.core.Entity;
import gasm.core.enums.ComponentType;
import gasm.core.utils.Assert;

class HeapsScaleFollowComponent extends Component {
	final _config:HeapsScaleFollowConfig;
	var _comp3d:Heaps3DComponent;
	var _comp2d:HeapsSpriteComponent;
	var _follow3d:Heaps3DComponent;
	var _follow2d:HeapsSpriteComponent;

	public var scale:Float;

	public function new(config:HeapsScaleFollowConfig) {
		_config = config;
		componentType = ComponentType.Actor;
		scale = _config.scale;
	}

	override public function init() {
		_comp3d = owner.get(Heaps3DComponent);
		if (_comp3d == null) {
			_comp2d = owner.get(HeapsSpriteComponent);
		}
		Assert.that(_comp3d != null || _comp2d != null,
			'HeapsScaleFollowComponent needs to be added to an entity with a Heaps3DComponent or HeapsSpriteComponent');
		_follow3d = _config.follow.get(Heaps3DComponent);
		if (_follow3d == null) {
			_follow2d = _config.follow.get(HeapsSpriteComponent);
		}
		Assert.that(_follow3d != null || _follow2d != null,
			'HeapsScaleFollowComponent needs to have a follow entity with a Heaps3DComponent or HeapsSpriteComponent');
	}

	override public function update(dt:Float) {
		if (_comp3d != null) {
			if (_follow3d != null) {
				_comp3d.object.scaleX = _follow3d.object.scaleX * scale;
				_comp3d.object.scaleY = _follow3d.object.scaleY * scale;
				_comp3d.object.scaleZ = _follow3d.object.scaleZ * scale;
			} else {
				_comp3d.object.scaleX = _follow2d.sprite.scaleX * scale;
				_comp3d.object.scaleY = _follow2d.sprite.scaleY * scale;
			}
		} else {
			if (_follow3d != null) {
				_comp2d.sprite.scaleX = _follow3d.object.scaleX * scale;
				_comp2d.sprite.scaleY = _follow3d.object.scaleY * scale;
			} else {
				_comp2d.sprite.scaleX = _follow2d.sprite.scaleX * scale;
				_comp2d.sprite.scaleY = _follow2d.sprite.scaleY * scale;
			}
		}
	}
}

@:structInit
class HeapsScaleFollowConfig {
	public var follow:Entity;
	public var scale = 1.0;
}
