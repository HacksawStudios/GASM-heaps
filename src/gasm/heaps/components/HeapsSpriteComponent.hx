package gasm.heaps.components;

import gasm.core.math.geom.Point;
import gasm.core.Component;
import gasm.core.components.AppModelComponent;
import gasm.core.components.SpriteModelComponent;
import gasm.core.enums.ComponentType;
import gasm.core.enums.EventType;
import gasm.core.events.api.IEvent;
import h2d.Object;
import hxd.Event;

/**
 * ...
 * @author Leo Bergman
 */
class HeapsSpriteComponent extends Component {
	public var sprite(default, default):Object;
	public var mouseEnabled(default, set):Bool;
	public var root(default, default):Bool;
	public var roundPixels(default, default):Bool;
	public var dirty(default, default):Bool;
	public var mousePos(default, null):Point;

	var _model:SpriteModelComponent;
	var _interactive:h2d.Interactive;
	var _stage:hxd.Window;
	var _appModel:AppModelComponent;
	var _inited:Bool;

	public function new(sprite:Null<Object> = null, mouseEnabled:Bool = false, roundPixels:Bool = false) {
		if (sprite == null) {
			sprite = mouseEnabled ? cast new h2d.Interactive(0, 0) : new h2d.Object();
		}
		if (mouseEnabled) {
			_interactive = cast sprite;
			_interactive.propagateEvents = true;
		}
		this.sprite = sprite;
		this.roundPixels = roundPixels;
		componentType = ComponentType.Graphics;
	}

	override public function setup() {
		sprite.name = owner.id;
	}

	override public function init() {
		_model = owner.get(SpriteModelComponent);
		_appModel = owner.getFromParents(AppModelComponent);
		var w = sprite.getSize().width;
		var h = sprite.getSize().height;
		if (w > 0) {
			_model.width = w;
			_model.height = h;
		}
		_model.xScale = sprite.scaleX;
		_model.yScale = sprite.scaleY;
		_stage = hxd.Window.getInstance();
		if (_interactive != null) {
			addEventListeners();
		}
	}

	override public function update(dt:Float) {
		if (_model != null) {
			if (_model.dirty) {
				if (roundPixels) {
					_model.x = Math.round(_model.x);
					_model.y = Math.round(_model.y);
					_model.width = Math.round(_model.width);
					_model.height = Math.round(_model.height);
				}
				sprite.x = _model.x + _model.offsetX;
				sprite.y = _model.y + _model.offsetY;
				sprite.alpha = _model.alpha;
				sprite.scaleX = _model.xScale;
				sprite.scaleY = _model.yScale;
				if (_interactive != null) {
					_interactive.width = _model.width;
					_interactive.height = _model.height;
				}
				_model.dirty = false;
			}
			_model.stageMouseX = _stage.mouseX;
			_model.stageMouseY = _stage.mouseY;
			sprite.visible = _model.visible;
		}
	}

	override public function dispose() {
		removeEventListeners();
		if (_model != null) {
			owner.remove(_model);
			_model = null;
		}
		if (sprite.parent != null) {
			sprite.parent.removeChild(sprite);
		}
		stopDrag();
		sprite.removeChildren();
	}

	function onClick(event:Event) {
		_model.triggerEvent(EventType.PRESS, {x: _stage.mouseX, y: _stage.mouseY}, owner);
	}

	function onDown(event:Event) {
		_model.triggerEvent(EventType.DOWN, {x: _stage.mouseX, y: _stage.mouseY}, owner);
		startDrag();
	}

	function onUp(event:Event) {
		_model.triggerEvent(EventType.UP, {x: _stage.mouseX, y: _stage.mouseY}, owner);
		stopDrag();
	}

	function onStageUp(event:IEvent) {
		stopDrag();
	}

	function onOver(event:Event) {
		_model.triggerEvent(EventType.OVER, {x: _stage.mouseX, y: _stage.mouseY}, owner);
	}

	function onOut(event:Event) {
		_model.triggerEvent(EventType.OUT, {x: _stage.mouseX, y: _stage.mouseY}, owner);
	}

	function onMove(event:Event) {
		var p:h2d.col.Point = sprite.globalToLocal(new h2d.col.Point(_stage.mouseX, _stage.mouseY));
		_model.mouseX = p.x;
		_model.mouseY = p.y;
		_model.stageMouseX = _stage.mouseX;
		_model.stageMouseY = _stage.mouseY;
		_model.triggerEvent(EventType.MOVE, {x: _stage.mouseX, y: _stage.mouseY}, owner);
	}

	function onDrag(event:IEvent) {
		var stage = hxd.Window.getInstance();
		_model.triggerEvent(EventType.DRAG, {x: _appModel.stageMouseX, y: _appModel.stageMouseY}, owner);
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
			var rootSmc:SpriteModelComponent = owner.getFromRoot(SpriteModelComponent);
			rootSmc.addHandler(EventType.UP, onStageUp);
			var smc:SpriteModelComponent = owner.get(SpriteModelComponent);
			smc.addHandler(EventType.UP, onStageUp);
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
			var rootSmc:SpriteModelComponent = owner.getFromRoot(SpriteModelComponent);
			rootSmc.removeHandler(EventType.UP, onStageUp);
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

typedef SpriteProps = {
	x:Float,
	y:Float,
	width:Float,
	height:Float,
}
