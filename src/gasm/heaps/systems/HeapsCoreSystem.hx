package gasm.heaps.systems;

import h2d.Sprite;
import gasm.heaps.components.HeapsSpriteComponent;
import gasm.core.components.SpriteModelComponent;
import gasm.core.Component;
import gasm.core.enums.ComponentType;
import gasm.core.System;
import gasm.core.ISystem;
import gasm.core.enums.SystemType;
import h2d.Scene;

class HeapsCoreSystem extends System implements ISystem {
    public var root(default, null):Scene;


    public function new(root:Scene) {
        super();
        this.root = root;
        type = SystemType.CORE;
        componentFlags.set(ComponentType.GraphicsModel);
    }

    public function update(comp:Component, delta:Float) {
        if (!comp.inited) {
            comp.init();
            comp.inited = true;
        }
        comp.update(delta);
    }
}
