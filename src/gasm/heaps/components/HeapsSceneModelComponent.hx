package gasm.heaps.components;

import gasm.core.Entity;
import gasm.core.components.SceneModelComponent;
import gasm.heaps.components.Heaps3DComponent;
import gasm.heaps.components.HeapsScene2DComponent;
import gasm.heaps.components.HeapsScene3DComponent;
import gasm.heaps.components.HeapsSpriteComponent;
import hacksaw.core.components.actor.render.PostProcessingComponent;
import haxe.ds.StringMap;
import hex.di.ClassRef;
import hex.di.Injector;
import hxd.SceneEvents;

using Lambda;

class HeapsSceneModelComponent extends SceneModelComponent {
	final _injector:Injector;
	var _sceneEvents:SceneEvents;

	public function new(injector:Injector) {
		_injector = injector;
		super();
	}

	override public function init() {
		_sceneEvents = _injector.getInstance(SceneEvents);
	}

	override public function hideScene(name:String) {
		final scene = scenes.find(s -> s.name == name);
		if (scene.is3D) {
			final s3d:h3d.scene.Scene = scene.instance;
			s3d.visible = false;
		} else {
			final s2d:h2d.Scene = scene.instance;
			s2d.visible = false;
		}
	}

	override public function showScene(name:String) {
		final scene = scenes.find(s -> s.name == name);
		if (scene.is3D) {
			final s3d:h3d.scene.Scene = scene.instance;
			s3d.visible = true;
		} else {
			final s2d:h2d.Scene = scene.instance;
			s2d.visible = true;
		}
	}

	override public function disableScene(name:String) {
		final scene = sceneMap.get(name);
		if (scene != null) {
			_sceneEvents.removeScene(cast(scene, hxd.SceneEvents.InteractiveScene));
		}
	}

	override public function enableScene(name:String) {
		var scene = sceneMap.get(name);
		if (scene != null) {
			_sceneEvents.addScene(cast(scene, hxd.SceneEvents.InteractiveScene));
		}
	}

	override function addEntity(scene:SceneLayer, baseEntity:Entity) {
		final entity = scene.entity;
		var anyScene:Any;
		if (scene.is3D) {
			final s:h3d.scene.Scene = anyScene = new h3d.scene.Scene();
			entity.add(new HeapsScene3DComponent(s));
			entity.add(new Heaps3DComponent(s));
		} else {
			final s:h2d.Scene = anyScene = new h2d.Scene();
			s.defaultSmooth = true;
			entity.add(new HeapsScene2DComponent(s));
			entity.add(new HeapsSpriteComponent(s));
		}
		scene.instance = anyScene;
		if (scene.interactive) {
			final is = cast(anyScene, hxd.SceneEvents.InteractiveScene);
			_sceneEvents.addScene(is, scene.layerIndex);
		}
		_injector.map(Entity, scene.name).toValue(entity);
		sceneMap.set(scene.name, anyScene);

		baseEntity.addChild(entity);

		#if !DISABLE_POSTPROCESSING
		final postProcessor = new PostProcessingComponent({});
		entity.add(postProcessor);
		#end

		return entity;
	}

	override public function removeScene(name:String) {
		_injector.unmap(Entity, name);
		super.removeScene(name);
	}
}
