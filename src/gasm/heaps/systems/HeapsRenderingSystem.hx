package gasm.heaps.systems;

import gasm.core.enums.ComponentType;
import gasm.heaps.components.HeapsTextComponent;
import gasm.core.components.SpriteModelComponent;
import gasm.core.Component;
import gasm.core.enums.SystemType;
import gasm.core.ISystem;
import gasm.core.System;
import gasm.heaps.components.HeapsSpriteComponent;
import h2d.Scene;

/**
 * ...
 * @author Leo Bergman
 */
class HeapsRenderingSystem extends System implements ISystem {
	public var root(default, null):Scene;

	public function new(root:Scene) {
		super();
		this.root = root;
		type = SystemType.RENDERING;
		componentFlags.set(ComponentType.Graphics);
		componentFlags.set(ComponentType.Graphics3D);
		componentFlags.set(ComponentType.Text);
	}

	public function update(comp:Component, delta:Float) {
		if (!comp.inited) {
			switch comp.componentType {
				case Graphics, Text:
						var model:SpriteModelComponent = comp.owner.get(SpriteModelComponent);
						var child:HeapsSpriteComponent = cast comp;
						if (comp.owner.parent != null) {
							var parent:HeapsSpriteComponent = comp.owner.parent.get(HeapsSpriteComponent);
							if (parent != null && parent != comp) {
								parent.sprite.addChild(child.sprite);
							} else {
								root.addChild(child.sprite);
							}
						} else if (Std.is(comp, HeapsSpriteComponent)) {
							// This is the root sprite, so flag it as such instead of adding
							var spc:HeapsSpriteComponent = cast comp;
							spc.root = true;
						}
						comp.inited = true;
						comp.init();

						var size = child.sprite.getSize();
						model.origWidth = size.width;
						model.origHeight = size.height;
				default: 
					// TODO: Add functionality for Graphics3D. Right now they just work as an actor, and for example getting camera or parent object will not work
					comp.inited = true;
					comp.init();
			}
		}
		comp.update(delta);
	}
}
