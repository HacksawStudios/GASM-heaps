package gasm.heaps.components;

import h3d.Vector;
import h3d.scene.Interactive;
import h3d.col.ObjectCollider;
import gasm.core.math.geom.Point;
import gasm.core.Component;
import gasm.core.components.ThreeDModelComponent;
import gasm.core.enums.ComponentType;
import gasm.core.enums.EventType;
import gasm.core.events.api.IEvent;
import gasm.heaps.shaders.Alpha;
import h3d.scene.Object;
import hxd.Event;

/**
 * ...
 * @author Leo Bergman
 */
class Heaps3DComponent extends Component {
	public var object(default, default):Object;
	public var mouseEnabled(default, set):Bool;
	public var root(default, default):Bool;
	public var dirty(default, default):Bool;
	public var mousePos(default, null):Point;

	var _model:ThreeDModelComponent;
	var _interactive:Interactive;
	var _inited:Bool;
	var _movePos = new Vector();
	var _alpha = 1.;

	public function new(object:Null<Object> = null, mouseEnabled:Bool = false) {
		this.object = object != null ? object : new Object();
		this.mouseEnabled = mouseEnabled;
		componentType = ComponentType.Graphics3D;
	}

	override public function setup() {
		object.name = owner.id;
	}

	override public function init() {
		_model = owner.get(ThreeDModelComponent);
		var bounds = object.getBounds();
		var w = bounds.xSize;
		var h = bounds.ySize;
		var d = bounds.zSize;
		if (w > 0) {
			_model.dimensions = new Vector(w, h, d);
		}
		_model.scale = new Vector(object.scaleX, object.scaleY, object.scaleZ);
		_model.pos = new Vector(0, 0, 0);
		_model.dirty = false;
		if (mouseEnabled) {
			_interactive = new Interactive(object.getCollider(), object);
			addEventListeners();
		}
	}

	override public function update(dt:Float) {
		if (_model != null) {
			if (_model.dirty) {
				object.x = _model.pos.x + _model.offset.x;
				object.y = _model.pos.y + _model.offset.y;
				object.z = _model.pos.z + _model.offset.z;
				if (_model.alpha != _alpha) {
					var mats = object.getMaterials();
					for (mat in mats) {
						var shader = mat.mainPass.getShader(Alpha);
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
				_model.pos = new Vector(object.x, object.y, object.z);
			}
			_model.dirty = false;
		}
	}

	override public function dispose() {
		removeEventListeners();
		if (_model != null) {
			owner.remove(_model);
			_model = null;
		}
		stopDrag();
		object.remove();
	}

	function onClick(e:Event) {
		_model.triggerEvent(EventType.PRESS, {x: e.relX, y: e.relY, z: e.relZ}, owner);
	}

	function onDown(e:Event) {
		_model.triggerEvent(EventType.DOWN, {x: e.relX, y: e.relY, z: e.relZ}, owner);
		startDrag();
	}

	function onUp(e:Event) {
		_model.triggerEvent(EventType.UP, {x: e.relX, y: e.relY, z: e.relZ}, owner);
		stopDrag();
	}

	function onStageUp(event:IEvent) {
		stopDrag();
	}

	function onOver(e:Event) {
		_model.triggerEvent(EventType.OVER, {x: e.relX, y: e.relY, z: e.relZ}, owner);
	}

	function onOut(e:Event) {
		_model.triggerEvent(EventType.OUT, {x: e.relX, y: e.relY, z: e.relZ}, owner);
	}

	function onMove(e:Event) {
		_movePos.set(e.relX, e.relY, e.relZ);
		_model.triggerEvent(EventType.MOVE, {x: _movePos.x, y: _movePos.y, z: _movePos.z}, owner);
	}

	function onDrag(event:IEvent) {
		var stage = hxd.Window.getInstance();
		_model.triggerEvent(EventType.DRAG, {x: _movePos.x, y: _movePos.y, z: _movePos.z}, owner);
	}

	function stopDrag() {
		if (_model != null) {
			_model.removeHandler(EventType.MOVE, onDrag);
		}
	}

	function startDrag() {
		_model.addHandler(EventType.MOVE, onDrag);
	}

	inline function addEventListeners() {
		if (_interactive != null) {
			_interactive.onClick = onClick;
			_interactive.onPush = onDown;
			_interactive.onRelease = onUp;
			_interactive.onOver = onOver;
			_interactive.onOut = onOut;
			_interactive.onMove = onMove;
			var rootModel = owner.getFromRoot(ThreeDModelComponent);
			rootModel.addHandler(EventType.UP, onStageUp);
			var model = owner.get(ThreeDModelComponent);
			model.addHandler(EventType.UP, onStageUp);
		}
	}

	inline function removeEventListeners() {
		if (_interactive != null) {
			_interactive.onClick = null;
			_interactive.onPush = null;
			_interactive.onRelease = null;
			_interactive.onOver = null;
			_interactive.onOut = null;
			_interactive.onMove = null;
			var rootModel = owner.getFromRoot(ThreeDModelComponent);
			rootModel.removeHandler(EventType.UP, onStageUp);
			if (_model != null) {
				_model.removeHandler(EventType.MOVE, onDrag);
			}
		}
	}

	function set_mouseEnabled(val:Bool):Bool {
		if (val) {
			addEventListeners();
		} else {
			removeEventListeners();
		}
		return val;
	}
}
