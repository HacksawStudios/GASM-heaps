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
import h3d.scene.Mesh;
import h3d.scene.Object;
import haxe.ds.ObjectMap;
import hxd.Event;
import tink.CoreApi.Future;
import tink.core.Future.FutureTrigger;

/**
 * ...
 * @author Leo Bergman
 */
class Heaps3DComponent extends Component {
	public var instanceGroupId:String;
	public var object(default, default):Object;
	public var root(default, default):Bool;
	public var dirty(default, default):Bool;
	public var alpha(default, set):Float;

	var _model:ThreeDModelComponent;
	var _interactive:Interactive;
	var _movePos = new Vector();
	var _alpha = 1.;
	var _stageUpFuture:Future<InteractionEvent> = null;

	final _meshShaders:ObjectMap<hxsl.Shader, Array<Mesh>>;

	/**
		build the instance group id used to determine what instancing group this object is part of
	**/
	public function buildInstanceGroupId() {
		final mesh = getFirstMesh();
		final material = mesh.material;
		final pass = mesh.material.mainPass;

		// Class name
		instanceGroupId = name;

		// Texture  ID
		instanceGroupId += "t" + material.texture.id;

		for (s in pass.getShaders()) {
			instanceGroupId += "s" + @:privateAccess s.shader.getInstance(0).id + ",";
		}
	}

	public function new(object:Null<Object> = null) {
		this.object = object != null ? object : new Object();
		componentType = ComponentType.Graphics3D;
		_meshShaders = new ObjectMap<hxsl.Shader, Array<Mesh>>();
	}

	/**
		Returns the first mesh child of the object
		Not travesting trough tree
	**/
	public function getFirstMesh():Mesh {
		for (child in object) {
			if (child.isMesh()) {
				return child.toMesh();
			}
		}
		return null;
	}

	override public function setup() {
		object.name = owner.id;
	}

	// Assign shader to all meshes sub to this object
	public function assignShaderToMeshes(shader:hxsl.Shader):Bool {
		if (_meshShaders.exists(shader)) {
			return true;
		}
		final meshes = object.getMeshes();
		if (meshes.length == 0) {
			return false;
		}
		var array = new Array<Mesh>();
		for (mesh in meshes) {
			mesh.material.mainPass.addShader(shader);
			array.push(mesh);
		}
		_meshShaders.set(shader, array);
		return true;
	}

	public function removeShaderFromMeshes(shader:hxsl.Shader) {
		if (!_meshShaders.exists(shader)) {
			return;
		}
		for (mesh in _meshShaders.get(shader)) {
			mesh.material.mainPass.removeShader(shader);
		}
		_meshShaders.remove(shader);
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
