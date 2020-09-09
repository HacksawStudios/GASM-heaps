package gasm.heaps.components.actor.render;

import gasm.core.Component;
import gasm.core.components.AppModelComponent;
import gasm.core.enums.ComponentType;
import gasm.core.utils.Assert;
import h3d.Engine;
import haxe.ds.IntMap;

using Safety;

class PostProcessingChainComponent extends Component {
	public var chainId:Int = null;

	var _processor:PostProcessingComponent;
	#if debug
	var _superCalled = false;
	#end

	public function new() {
		componentType = ComponentType.Actor;
	}

	override public function init() {
		_processor = owner.get(PostProcessingComponent);
		chainId = setupChain();
		#if debug
		_superCalled = true;
		#end
	}

	#if debug
	override public function update(dt:Float) {
		Assert.that(_superCalled == true, "PostProcessingChainComponent super.init() wasn't called");
	}
	#end

	/**
		Called when chain is enabled
	**/
	public function onEnabled() {}

	/**
		Called when chain is disabled
	**/
	public function onDisabled() {}

	override public function dispose() {
		_processor.destroyChain(chainId);
	}

	function setupChain():Int {
		throw('PostProcessingChainComponent.setupChain() override in subclass');
	}
}
