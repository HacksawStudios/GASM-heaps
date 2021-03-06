package gasm.heaps.components;

import gasm.core.Component;
import gasm.core.enums.ComponentType;
import gasm.core.enums.EventType;
import gasm.core.events.InteractionEvent;
import gasm.core.utils.Assert;
import h3d.col.Collider;
import h3d.scene.Interactive;
import haxe.ds.EnumValueMap;
import tink.CoreApi.Callback;
import tink.CoreApi.Future;

class Heaps3DInteractiveComponent extends Component {
	var _interactCallbackMap = new EnumValueMap<EventType, Array<Callback<InteractionEvent>>>();
	var _comp:Heaps3DComponent;
	var _interactive:h3d.scene.Interactive;
	var _collider:Collider;

	public function new() {
		componentType = ComponentType.Actor;
	}

	override public function init() {
		_comp = owner.get(Heaps3DComponent);
		Assert.that(_comp != null, "Interactive component needs to have a Heaps3DComponent");
	}

	override public function update(dt:Float) {
		// Make sure collider is setup
		ensureColliderSetup();
	}

	override public function dispose() {
		if (_interactive != null) {
			_interactive.remove();
		}
	}

	// Makes sure the collider is setup. returns true on success.
	function ensureColliderSetup():Bool {
		if (_collider != null) {
			return true;
		}
		_collider = _comp.object.getCollider();
		final scene = _comp.object.getScene();
		if (_collider == null) {
			return false;
		}

		_interactive = new h3d.scene.Interactive(_collider, scene);
		_interactive.onClick = (e:hxd.Event) -> {
			// Todo, create event and pass needed data
			triggerInteractCallbacks(EventType.PRESS, null);
		}

		return true;
	}

	public function click():Future<InteractionEvent> {
		return interact(EventType.PRESS);
	}

	function interact(type:EventType):Future<InteractionEvent> {
		return Future.async(cb -> {
			if (!_interactCallbackMap.exists(type)) {
				_interactCallbackMap.set(type, new Array<Callback<InteractionEvent>>());
			}
			_interactCallbackMap.get(type).push(cast cb);
		});
	}

	function triggerInteractCallbacks(type:EventType, event:InteractionEvent) {
		if (!_interactCallbackMap.exists(type)) {
			return;
		}
		for (cbArray in _interactCallbackMap) {
			for (cb in cbArray) {
				cb.invoke(event);
			}
		}
		_interactCallbackMap = new EnumValueMap<EventType, Array<Callback<InteractionEvent>>>();
	}
}
