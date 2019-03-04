package gasm.heaps.systems;

import gasm.core.enums.ComponentType;
import gasm.heaps.components.HeapsTextComponent;
import gasm.core.components.SpriteModelComponent;
import gasm.core.Component;
import gasm.core.enums.SystemType;
import gasm.core.ISystem;
import gasm.core.System;
import gasm.heaps.components.HeapsSpriteComponent;
import gasm.heaps.components.HeapsSceneComponent;
import gasm.heaps.components.HeapsScene2DComponent;
import gasm.heaps.components.HeapsScene3DComponent;
import haxe.ds.StringMap;

/**
 * ...
 * @author Leo Bergman
 */
class HeapsRenderingSystem extends System implements ISystem {
	public var root(default, null):h2d.Scene;
	public var sceneMap = new StringMap<Any>();

	public function new(root:h2d.Scene) {
		super();
		this.root = root;
		type = SystemType.RENDERING;
		componentFlags.set(ComponentType.Graphics);
		componentFlags.set(ComponentType.Graphics3D);
		componentFlags.set(ComponentType.Text);
	}

	public function addScene(name:String, is3D = false) {
		var scene:Any;
		if (!is3D) {
			var scene2d = new h2d.Scene();
			// if we don't do this. all is blocky.
			scene2d.defaultSmooth = true;
			scene = scene2d;
		} else {
			scene = new h3d.scene.Scene();
		}
		sceneMap.set(name, scene);
		return scene;
	}

	public function update(comp:Component, delta:Float) {
		if (!comp.inited) {
			switch comp.componentType {
				case Graphics, Text:
					var model = comp.owner.get(SpriteModelComponent);

					// find scenecomponent in tree. if not found, this is a spritecomponent on a baseEntity and this is not permitted
					if (comp.owner.getFromParents(HeapsScene2DComponent) == null && comp.owner.get(HeapsScene2DComponent) == null) {
						throw("You can't add a HeapsSpriteComponent on baseEntity");
					}

					var spriteComponent:HeapsSpriteComponent = cast comp;
					var parentEntity = comp.owner.parent;
					// If the entity has a parent,it can be either a scene or a sprite
					// in case of root sprite, parent is baseEntity
					if (parentEntity != null) {
						var parentSpriteComponent:HeapsSpriteComponent = comp.owner.parent.get(HeapsSpriteComponent);
						// parent has no sprite component. means, we are root
						if (parentSpriteComponent == null) {
							spriteComponent.root = true;
						} else {
							// else, we make sure we parent
							parentSpriteComponent.sprite.addChild(spriteComponent.sprite);
						}
					}
					comp.inited = true;
					comp.init();

					var size = spriteComponent.sprite.getSize();
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
