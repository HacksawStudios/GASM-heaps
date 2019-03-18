package gasm.heaps.components;

import haxe.ds.StringMap;
import hxd.SceneEvents;
import hex.di.ClassRef;
import hex.di.Injector;
import gasm.core.Entity;
import gasm.core.components.SceneModelComponent;
import gasm.heaps.components.HeapsScene2DComponent;
import gasm.heaps.components.HeapsScene3DComponent;
import gasm.heaps.components.Heaps3DComponent;
import gasm.heaps.components.HeapsSpriteComponent;

class HeapsSceneModelComponent extends SceneModelComponent {
	var _injector:Injector;
	var _sceneEvents:SceneEvents;

	public function new(injector:Injector) {
		_injector = injector;
		super();
	}

	override public function init() {
		_sceneEvents = _injector.getInstance(SceneEvents);
	}

	override function disableScene(name:String) {
		var scene = sceneMap.get(name);
		if (scene != null) {
			_sceneEvents.removeScene(cast(scene, hxd.SceneEvents.InteractiveScene));
		}
	}

	override function enableScene(name:String) {
		var scene = sceneMap.get(name);
		if (scene != null) {
			_sceneEvents.addScene(cast(scene, hxd.SceneEvents.InteractiveScene));
		}
	}

	override function addEntity(scene:SceneLayer, baseEntity:Entity) {
		var entity = scene.entity;
		var anyScene:Any;
		if (scene.is3D) {
			var s:h3d.scene.Scene = anyScene = new h3d.scene.Scene();
			entity.add(new HeapsScene3DComponent(s));
			entity.add(new Heaps3DComponent(s));
		} else {
			var s:h2d.Scene = anyScene = new h2d.Scene();
			s.defaultSmooth = true;
			entity.add(new HeapsScene2DComponent(s));
			entity.add(new HeapsSpriteComponent(s));
		}
		scene.instance = anyScene;
		if (scene.interactive) {
			var is = cast(anyScene, hxd.SceneEvents.InteractiveScene);
			_sceneEvents.addScene(is, scene.layerIndex);
		}
		_injector.map(Entity, scene.name).toValue(entity);
		sceneMap.set(scene.name, anyScene);

		baseEntity.addChild(entity);
		return entity;
	}
}
