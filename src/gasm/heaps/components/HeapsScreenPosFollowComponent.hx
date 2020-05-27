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

	var _this:h3d.scene.Object;
	var _target:h3d.scene.Object;
	var _thisCamera:h3d.Camera;
	var _targetCamera:h3d.Camera;
	var _appModel:AppModelComponent;

	// World space coordinates
	var _targetWorld = new h3d.Vector(0.0, 0.0, 0.0);
	var _thisWorld = new h3d.Vector(0.0, 0.0, 0.0);

	public function new(config:HeapsScreenPosFollowComponentConfig) {
		_config = config;
		componentType = ComponentType.Actor;
	}

	override public function init() {
		final target = _config.target.get(Heaps3DComponent);
		Assert.that(target != null, 'HeapsScreenPosFollowComponent requires target with Heaps3DComponent');

		final me = owner.get(Heaps3DComponent);
		Assert.that(me != null, 'HeapsScreenPosFollowComponent requires Heaps3DComponent in its entity');

		final thisScene = owner.getFromParents(HeapsScene3DComponent);
		Assert.that(thisScene != null, 'HeapsScreenPosFollowComponent must have a 3d scene in its graph');

		final targetScene = _config.target.getFromParents(HeapsScene3DComponent);
		Assert.that(targetScene != null, 'HeapsScreenPosFollowComponent target must have a 3d scene in its graph');

		_appModel = owner.getFromParents(AppModelComponent);
		Assert.that(_appModel != null, 'HeapsScreenPosFollowComponent requires AppModelComponent in its graph');

		_this = me.object;
		_target = target.object;
		_thisCamera = thisScene.scene3d.camera;
		_targetCamera = targetScene.scene3d.camera;

		// Because of absolute coordinate, we no longer respect our parents
		_this.ignoreParentTransform = true;
	}

	override public function update(dt:Float) {
		// Parents transformations needs to be considered
		_target.getAbsPos().getPosition(_targetWorld);
		_this.getAbsPos().getPosition(_thisWorld);

		// Offset is added before target projection to minimize calculation
		_targetWorld.x += _config.targetOffset.x;
		_targetWorld.y += _config.targetOffset.y;
		_targetWorld.z += _config.targetOffset.z;

		// Determine screen pos for target with offset
		final targetScreenPos = _targetCamera.project(_targetWorld.x, _targetWorld.y, _targetWorld.z, _appModel.stageSize.x, _appModel.stageSize.y);

		// Convert from target screen coordinates to -1 -> 1, inverted for Y
		final sx = (2.0 * (targetScreenPos.x / _appModel.stageSize.x) - 1.0);
		final sy = (2.0 * (targetScreenPos.y / _appModel.stageSize.y) - 1.0) * -1;

		// Determine z in frustum 0->1 for this
		final sz = _thisCamera.project(_thisWorld.x, _thisWorld.y, _thisWorld.z, _appModel.stageSize.x, _appModel.stageSize.y).z;

		// On this Z, where is the target screen pos?
		final finalPos = _thisCamera.unproject(sx, sy, sz);

		// Add final offset (this is now in worldspace for this)
		finalPos.x += _config.thisOffset.x;
		finalPos.y += _config.thisOffset.y;
		finalPos.z += _config.thisOffset.z;

		_this.setPosition(finalPos.x, finalPos.y, finalPos.z);
	}

	override public function dispose() {
		_this.ignoreParentTransform = false;
		super.remove();
	}
}

@:structInit
class HeapsScreenPosFollowComponentConfig {
	/**
		Follow the Heaps3DComponent in this entity
	**/
	public var target:Entity;

	/**
		Offset position from target worldspace
	**/
	public var targetOffset = new h3d.Vector(0.0, 0.0, 0.0);

	/**
		Offset position from this worldspace
	**/
	public var thisOffset = new h3d.Vector(0.0, 0.0, 0.0);
}
