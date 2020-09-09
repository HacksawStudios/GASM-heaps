package gasm.heaps.components.actor.render;

import gasm.core.Component;
import gasm.core.components.AppModelComponent;
import gasm.core.enums.ComponentType;
import gasm.core.utils.Assert;
import gasm.heaps.components.actor.render.PostProcessingComponent.PostProcessingPassConfig;
import gasm.heaps.components.actor.render.PostProcessingComponent.TextureInput;
import gasm.heaps.components.actor.render.PostProcessingComponent.TextureSource;
import gasm.heaps.shaders.PostProcessingShaderBase;
import h3d.Engine;
import h3d.mat.BlendMode;
import haxe.ds.IntMap;

using Safety;

class BasicChainComponent extends PostProcessingChainComponent {
	final _passConfigs:Array<PostProcessingPassConfig>;

	override public function new(passConfigs:Array<PostProcessingPassConfig>) {
		super();
		_passConfigs = passConfigs;
	}

	override function setupChain():Int {
		final passes = [];
		for (passConfig in _passConfigs) {
			passes.push(_processor.createPass(passConfig));
		}
		return _processor.createChain(passes);
	}
}
