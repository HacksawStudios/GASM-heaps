package gasm.heaps.systems;

import gasm.heaps.components.Heaps3DComponent;
import gasm.heaps.components.HeapsSpriteComponent;
import gasm.heaps.components.HeapsScene2DComponent;
import gasm.heaps.components.HeapsScene3DComponent;
import gasm.core.components.AppModelComponent;
import gasm.core.components.SceneModelComponent;
import gasm.core.components.SpriteModelComponent;
import gasm.core.Component;
import gasm.core.Entity;
import gasm.core.enums.ComponentType;
import gasm.core.System;
import gasm.core.ISystem;
import gasm.core.enums.SystemType;
import h2d.Scene;
import haxe.ds.StringMap;

using Lambda;

class HeapsCoreSystem extends System implements ISystem {
	public var root(default, null):Scene;
	public var sceneMap = new StringMap<SceneLayer>();

	var _appModel:AppModelComponent;
	var _scenes:Array<SceneLayer> = [];

	public function new(root:Scene) {
		super();
		this.root = root;
		type = SystemType.CORE;
		componentFlags.set(ComponentType.SceneModel);
	}

	public function update(comp:Component, delta:Float) {
		if (!comp.inited) {
			comp.init();
			comp.inited = true;
		}
		comp.update(delta);
	}
}
