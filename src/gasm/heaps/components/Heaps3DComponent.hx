package gasm.heaps.components;

import gasm.core.Component;
import gasm.core.components.ThreeDModelComponent;
import gasm.core.enums.ComponentType;
import gasm.core.enums.EventType;
import gasm.core.events.InteractionEvent;
import gasm.core.events.api.IEvent;
import gasm.core.math.geom.Point;
import gasm.core.math.geom.Vector;
import gasm.heaps.shaders.Alpha;
import h3d.col.ObjectCollider;
import h3d.scene.Interactive;
import h3d.scene.Object;
import hxd.Event;
import tink.CoreApi.Future;
import tink.core.Future.FutureTrigger;

/**
 * ...
 * @author Leo Bergman
 */
class Heaps3DComponent extends Component {
	public var object(default, default):Object;
	public var root(default, default):Bool;
	public var dirty(default, default):Bool;
	public var alpha(default, set):Float;

	var _model:ThreeDModelComponent;
	var _interactive:Interactive;
	var _movePos = new Vector();
	var _alpha = 1.;
	var _stageUpFuture:Future<InteractionEvent> = null;

	public function new(object:Null<Object> = null) {
		this.object = object != null ? object : new Object();
		componentType = ComponentType.Graphics3D;
	}

	override public function setup() {
		object.name = owner.id;
	}

	override public function init() {
		_model = owner.get(ThreeDModelComponent);
		final bounds = object.getBounds();
		final w = bounds.xSize;
		final h = bounds.ySize;
		final d = bounds.zSize;
		if (w > 0) {
			_model.dimensions = new Vector(w, h, d);
		}
		_model.scale = new Vector(object.scaleX, object.scaleY, object.scaleZ);
		_model.pos = new Vector(0, 0, 0);
		_model.dirty = false;
		super.init();
	}

	override public function update(dt:Float) {
		if (_model != null) {
			if (_model.dirty) {
				object.x = _model.pos.x + _model.offset.x;
				object.y = _model.pos.y + _model.offset.y;
				object.z = _model.pos.z + _model.offset.z;
				if (_model.alpha != _alpha) {
					final mats = object.getMaterials();
					for (mat in mats) {
						final shader = mat.mainPass.getShader(Alpha);
						if (shader != null) {
							shader.alpha = _model.alpha;
						} else {
							mat.mainPass.addShader(new Alpha(_model.alpha));
						}
					}
					_alpha = _model.alpha;
				}
				object.scaleX = _model.scale.x;
				object.scaleY = _model.scale.y;
				object.scaleZ = _model.scale.z;
				object.visible = _model.visible;
			} else {
				_model.pos.x = object.x;
				_model.pos.y = object.y;
				_model.pos.z = object.z;
				_model.scale.x = object.scaleX;
				_model.scale.y = object.scaleY;
				_model.scale.z = object.scaleZ;
			}
			_model.dirty = false;
		}
	}

	override public function dispose() {
		if (_model != null) {
			owner.remove(_model);
			_model = null;
		}
		object.remove();
	}

	function set_alpha(val:Float):Float {
		if (val != null && _model != null) {
			_model.alpha = val;
		}
		return val;
	}
}
