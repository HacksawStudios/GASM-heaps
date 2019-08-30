package gasm.heaps.systems;

import gasm.core.enums.ComponentType;
import gasm.heaps.components.HeapsTextComponent;
import gasm.core.components.SpriteModelComponent;
import gasm.core.Component;
import gasm.core.enums.SystemType;
import gasm.core.ISystem;
import gasm.core.System;
import gasm.core.utils.Assert;
import gasm.heaps.components.Heaps3DComponent;
import gasm.heaps.components.HeapsSpriteComponent;
import gasm.heaps.components.HeapsSceneBase;
import gasm.heaps.components.HeapsScene2DComponent;
import gasm.heaps.components.HeapsScene3DComponent;
import haxe.ds.StringMap;

/**
 * ...
 * @author Leo Bergman
 */
class HeapsRenderingSystem extends System implements ISystem {
	public var root(default, null):h2d.Scene;

	public function new(root:h2d.Scene) {
		super();
		this.root = root;
		type = SystemType.RENDERING;
		componentFlags.set(ComponentType.Graphics);
		componentFlags.set(ComponentType.Graphics3D);
		componentFlags.set(ComponentType.Text);
	}

	public function update(comp:Component, delta:Float) {
		if (!comp.inited) {
			// For all types or display components add them to display graph
			switch comp.componentType {
				case Graphics, Text:
					// Find scenecomponent in tree, if not found this is a spritecomponent on a baseEntity and this is not permitted
					Assert.that(comp.owner.getFromParents(HeapsSceneBase) != null, "You can't add a HeapsSpriteComponent on baseEntity");
					var spriteComponent:HeapsSpriteComponent = cast comp;
					var parentEntity = comp.owner.parent;
					// If the entity has a parent,it can be either a scene or a sprite
					// In case of root sprite, parent is baseEntity
					if (parentEntity != null) {
						var parentSpriteComponent = comp.owner.parent.getFromParents(HeapsSpriteComponent);
						if (parentSpriteComponent == null) {
							// Parent has no sprite component, we are root
							spriteComponent.root = true;
						} else {
							// Else, add to parent
							parentSpriteComponent.sprite.addChild(spriteComponent.sprite);
						}
					}
				case Graphics3D:
					// Find scenecomponent in tree, if not found this is a 3d component on a baseEntity and this is not permitted
					Assert.that(comp.owner.getFromParents(HeapsSceneBase) != null, "You can't add a Heaps3DComponent on baseEntity");
					var component:Heaps3DComponent = cast comp;
					var parentEntity = comp.owner.parent;
					// If the entity has a parent,it can be either a scene or a sprite
					// In case of root sprite, parent is baseEntity
					if (parentEntity != null) {
						var parentComponent = comp.owner.parent.getFromParents(Heaps3DComponent);
						if (parentComponent == null) {
							// Parent has no sprite component, we are root
							component.root = true;
						} else {
							// Else, add to parent
							parentComponent.object.addChild(component.object);
						}
					}
				default:
					null;
			}

			// We have a parent, component ready to init
			comp.inited = true;
			comp.init();

			// Component initialized, should be able to pick up original size to use when scaling
			switch comp.componentType {
				case Graphics, Text:
					var model = comp.owner.get(SpriteModelComponent);
					var size = cast(comp, HeapsSpriteComponent).sprite.getSize();
					model.origWidth = size.width;
					model.origHeight = size.height;
				default:
					null;
			}
		}
		comp.update(delta);
	}
}
