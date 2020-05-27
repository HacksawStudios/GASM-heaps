package gasm.heaps.components;

import gasm.core.Component;
import gasm.core.Entity;
import gasm.core.components.AppModelComponent;
import gasm.core.enums.ComponentType;
import gasm.core.utils.Assert;

/**
	Follow target by screen absolute position
**/
class HeapsScreenPosFollowComponent extends Component {
	final _config:HeapsScreenPosFollowComponentConfig;

	var _source:h3d.scene.Object;
	var _target:h3d.scene.Object;
	var _sourceCamera:h3d.Camera;
	var _targetCamera:h3d.Camera;
	var _appModel:AppModelComponent;

	// World space coordinates
	var _targetWorld = new h3d.Vector(0.0, 0.0, 0.0);
	var _sourceWorld = new h3d.Vector(0.0, 0.0, 0.0);

	public function new(config:HeapsScreenPosFollowComponentConfig) {
		_config = config;
		componentType = ComponentType.Actor;
	}

	override public function init() {
		final target = _config.target.get(Heaps3DComponent);
		Assert.that(target != null, 'HeapsScreenPosFollowComponent target requires Heaps3DComponent in its entity');

		final source = owner.get(Heaps3DComponent);
		Assert.that(source != null, 'HeapsScreenPosFollowComponent requires Heaps3DComponent in its entity');

		final sourceScene = owner.getFromParents(HeapsScene3DComponent);
		Assert.that(sourceScene != null, 'HeapsScreenPosFollowComponent requires HeapsScene3DComponent in its graph');

		final targetScene = _config.target.getFromParents(HeapsScene3DComponent);
		Assert.that(targetScene != null, 'HeapsScreenPosFollowComponent target requires HeapsScene3DComponent in its graph');

		_appModel = owner.getFromParents(AppModelComponent);
		Assert.that(_appModel != null, 'HeapsScreenPosFollowComponent requires AppModelComponent in its graph');

		_source = source.object;
		_target = target.object;
		_sourceCamera = sourceScene.scene3d.camera;
		_targetCamera = targetScene.scene3d.camera;

		// Because of absolute coordinate, we no longer respect our parents
		_source.ignoreParentTransform = true;
	}

	override public function update(dt:Float) {
		// Parents transformations needs to be considered
		_target.getAbsPos().getPosition(_targetWorld);
		_source.getAbsPos().getPosition(_sourceWorld);

		// Offset is added before target projection to minimize calculation
		_targetWorld.x += _config.targetOffset.x;
		_targetWorld.y += _config.targetOffset.y;
		_targetWorld.z += _config.targetOffset.z;

		// Determine screen pos for target with offset
		final targetScreenPos = _targetCamera.project(_targetWorld.x, _targetWorld.y, _targetWorld.z, _appModel.stageSize.x, _appModel.stageSize.y);

		// Convert from target screen coordinates to -1 -> 1, inverted for Y
		final sx = (2.0 * (targetScreenPos.x / _appModel.stageSize.x) - 1.0);
		final sy = (2.0 * (targetScreenPos.y / _appModel.stageSize.y) - 1.0) * -1;

		// Determine z in frustum 0->1 for source
		final sz = _sourceCamera.project(_sourceWorld.x, _sourceWorld.y, _sourceWorld.z, _appModel.stageSize.x, _appModel.stageSize.y).z;

		// On source Z, where is the target screen pos?
		final finalPos = _sourceCamera.unproject(sx, sy, sz);

		// Add final offset (source is now in worldspace for source)
		finalPos.x += _config.sourceOffset.x;
		finalPos.y += _config.sourceOffset.y;
		finalPos.z += _config.sourceOffset.z;

		_source.setPosition(finalPos.x, finalPos.y, finalPos.z);
	}

	override public function dispose() {
		_source.ignoreParentTransform = false;
		super.remove();
	}
}

@:structInit
class HeapsScreenPosFollowComponentConfig {
	/**
		Follow the Heaps3DComponent in source entity
	**/
	public var target:Entity;

	/**
		Offset position from target worldspace
	**/
	public var targetOffset = new h3d.Vector(0.0, 0.0, 0.0);

	/**
		Offset position from source worldspace
	**/
	public var sourceOffset = new h3d.Vector(0.0, 0.0, 0.0);
}
