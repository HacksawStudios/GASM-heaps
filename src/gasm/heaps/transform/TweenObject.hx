package gasm.heaps.transform;

import gasm.heaps.transform.TweenVector.TweenTarget;
import gasm.heaps.transform.TweenVector.VectorTween;
import h3d.Vector;
import h3d.anim.Animation;
import h3d.scene.Object;

using Lambda;
using Safety;
using tink.CoreApi;

enum ObjectTween {
	Position(v:VectorTween);
	Rotate(v:VectorTween);
	Scale(v:VectorTween);
	Color(v:VectorTween);
}

class TweenObjectBacking {
	/**
		3d object to wrap
	**/
	public var object:Object;

	/**
		Initial transform
	**/
	public var home:Transform;

	public var parent(get, null):Object;
	public var name(get, set):String;
	public var visible(get, set):Bool;
	public var x(get, set):Float;
	public var y(get, set):Float;
	public var z(get, set):Float;
	public var scaleX(get, set):Float;
	public var scaleY(get, set):Float;
	public var scaleZ(get, set):Float;

	@:allow(gasm.heaps.transform.TweenObject)
	final position:TweenVector;
	@:allow(gasm.heaps.transform.TweenObject)
	final rotation:TweenVector;
	@:allow(gasm.heaps.transform.TweenObject)
	final scaling:TweenVector;
	@:allow(gasm.heaps.transform.TweenObject)
	final color:TweenVector;

	/**
		Private, only to be used by TweenObject.
		To construct use implicit cast of TweenObject.
		`final o:TweenObject = myObject;`
	**/
	@:allow(gasm.heaps.transform.TweenObject)
	function new(object:Object) {
		this.object = object;
		final rot = object.getRotationQuat().toEuler();
		position = new TweenVector(object.x, object.y, object.z);
		rotation = new TweenVector(rot.x, rot.y, rot.z);
		scaling = new TweenVector(object.scaleX, object.scaleY, object.scaleZ);
		color = new TweenVector(1.0, 1.0, 1.0, 1.0);
		home = {
			pos: {x: position.x, y: position.y, z: position.z},
			rotation: {x: rot.x, y: rot.y, z: rot.z},
			scale: {x: object.scaleX, y: object.scaleY, z: object.scaleZ},
			color: {
				x: 1.0,
				y: 1.0,
				z: 1.0,
				w: 1.0,
			},
		}
	}

	/**
		Cancel all running tweens
	**/
	public function cancel() {
		position.cancel();
		rotation.cancel();
		scaling.cancel();
		color.cancel();
	}

	/**
		Fast forward all running tweens
	**/
	public function fastForward() {
		position.fastForward();
		rotation.fastForward();
		scaling.fastForward();
		color.fastForward();
	}

	public function dispose() {
		position.dispose();
		rotation.dispose();
		scaling.dispose();
		color.dispose();
	}

	public function clone() {
		final backing = new TweenObjectBacking(object.clone());
		return backing;
	}

	/**
		Return all materials in the underlying object.
	**/
	public function getMaterials() {
		return object.getMaterials();
	}

	/**
		Return all meshes in the underlying object.
	**/
	public function getMeshes() {
		return object.getMeshes();
	}

	/**
		Return child at index

		@param index Index of child to get
	**/
	public function getChildAt(index:Int) {
		return object.getChildAt(index);
	}

	/**
		Return mesh by name in the underlying object.

		@param name Name of mesh to get
	**/
	public function getMeshByName(name:String) {
		return object.getMeshByName(name);
	}

	/**
		Create an animation instance bound to the underlying object, set it as currentAnimation and play it.
	**/
	public function playAnimation(anim:Animation) {
		object.playAnimation(anim);
	}

	/**
		Return the quaternion representing the underlying object rotation.
		Dot not modify as it's not a copy.
	**/
	public function getRotationQuat() {
		return object.getRotationQuat();
	}

	public function setRotationQuat(q) {
		object.setRotationQuat(q);
	}

	public function getCollider() {
		return object.getCollider();
	}

	/**
		Set the rotation of underlying object using the specified angles (in radian).
	**/
	public function setRotation(rx:Float, ry:Float, rz:Float) {
		return object.setRotation(rx, ry, rz);
	}

	/**
		Set the uniform scale for the underlying object.
	**/
	public function setScale(val:Float) {
		return object.setScale(val);
	}

	/**
		Add child
	**/
	public function addChild(obj:Object) {
		return object.addChild(obj);
	}

	/**
		Remove child
	**/
	public function removeChild(obj:Object) {
		return object.removeChild(obj);
	}

	/**
		Add child
	**/
	public function getBounds() {
		return object.getBounds();
	}

	public function getScene() {
		return object.getScene();
	}

	/**
		Return an iterator over this object immediate children
	**/
	public inline function iterator():hxd.impl.ArrayIterator<Object> {
		return new hxd.impl.ArrayIterator(@:privateAccess object.children);
	}

	/**
		Set the position of the underlying object.
	**/
	public function setPosition(x:Float, y:Float, z:Float) {
		position.set(x, y, z);
		return object.setPosition(x, y, z);
	}

	/**
		Reset and remove object.
	**/
	public function remove() {
		cancel();
		home = null;
		object.remove();
	}

	function get_parent() {
		return object.parent;
	}

	function get_name() {
		return object.name;
	}

	function set_name(name:String) {
		return object.name = name;
	}

	function get_visible() {
		return object.visible;
	}

	function set_visible(val:Bool) {
		return object.visible = val;
	}

	function get_x() {
		return object.x;
	}

	function get_y() {
		return object.y;
	}

	function get_z() {
		return object.z;
	}

	function set_x(x:Float) {
		position.x = x;
		return object.x = x;
	}

	function set_y(y:Float) {
		position.y = y;
		return object.y = y;
	}

	function set_z(z:Float) {
		position.z = z;
		return object.z = z;
	}

	function get_scaleX() {
		return object.scaleX;
	}

	function get_scaleY() {
		return object.scaleY;
	}

	function get_scaleZ() {
		return object.scaleZ;
	}

	function set_scaleX(val:Float) {
		return object.scaleX = val;
	}

	function set_scaleY(val:Float) {
		return object.scaleY = val;
	}

	function set_scaleZ(val:Float) {
		return object.scaleZ = val;
	}
}

@:forward
abstract TweenObject(TweenObjectBacking) from TweenObjectBacking {
	/**
		Construct tween object

		Private since not intended to be used directly, assign your h2d.scene.Object with implicit cast instead:
		`final myObj:TweenObject = obj;`

	**/
	inline function new(obj:TweenObjectBacking, ?initial:Transform) {
		this = obj;
		init(initial);
		if (initial != null) {
			translateTo({to: initial.pos, duration: 0});
			rotateTo({to: initial.rotation, duration: 0});
			scaleTo({to: initial.scale, duration: 0});
			colorTo({to: initial.color, duration: 0});
		}
	}

	function init(?initial:Transform) {
		if (initial == null) {
			final posV = new Vector(this.x, this.y, this.z);
			final rotV = this.getRotationQuat().toEuler();
			final scaleV = new Vector(this.scaleX, this.scaleY, this.scaleZ);
			final colorV = new Vector(1.0, 1.0, 1.0, 1.0);
			initial = {
				pos: posV,
				rotation: rotV,
				scale: scaleV,
				color: colorV,
			}
		}

		this.position.load(initial.pos);
		this.rotation.load(initial.rotation);
		this.scaling.load(initial.scale);
		this.color.load(initial.color);
		this.home = initial;
	}

	/**
		Cancel running tweens and reset home
	**/
	public function resetTween() {
		this.cancel();
		init(this.home);
	}

	/**
		Animate translation
		@param tween Tween config for movement
	**/
	public function translateTo(tween:VectorTween):Future<Bool> {
		return this.position.tween(tween);
	}

	/**
		Animate rotation
		@param tween Tween config for rotation
	**/
	public function rotateTo(tween:VectorTween):Future<Bool> {
		this.rotation.load(this.getRotationQuat().toEuler());
		return this.rotation.tween(tween);
	}

	/**
		Animate scaling
		@param tween Tween config for scaling
	**/
	public function scaleTo(tween:VectorTween):Future<Bool> {
		return this.scaling.tween(tween);
	}

	/**
		Animate color
		@param tween Tween config for color
	**/
	public function colorTo(tween:VectorTween):Future<Bool> {
		return this.color.tween(tween);
	}

	/**
		Tween object
		@param tweens Array of ObjectTweens to apply to object
	**/
	public function tween(tweens:Array<ObjectTween>):Future<Bool> {
		return Future.async(done -> {
			final allTweens = [
				for (tween in tweens) {
					switch tween {
						case Position(v):
							translateTo(v);
						case Rotate(v):
							rotateTo(v);
						case Scale(v):
							scaleTo(v);
						case Color(v):
							colorTo(v);
					}
				}
			];
			// Update to write the current value
			update(0.0);
			Future.ofMany(allTweens).handle(doneArray -> {
				done(!doneArray.has(false));
			});
		});
	}

	/**
		Return to initial position.

		@param duration Transition time in seconds
		@param curve Easing curve to use

		@return Future resolved when transition is complete
	**/
	public function returnHome(duration = 0.0, ?curve:Float->Float):Future<Bool> {
		curve = curve != null ? curve : f -> f;
		return tween([
			Position({to: this.home.pos, duration: duration, curve: curve}),
			Rotate({to: this.home.rotation, duration: duration, curve: curve}),
			Scale({to: this.home.scale, duration: duration, curve: curve}),
			Color({to: this.home.color, duration: duration, curve: curve}),
		]);
	}

	/**
		Update animating values
		@param dt Delta time
	**/
	public function update(dt:Float) {
		if (this.position.update(dt)) {
			this.x = this.position.x;
			this.y = this.position.y;
			this.z = this.position.z;
		} else {
			this.position.set(this.x, this.y, this.z);
		}

		if (this.rotation.update(dt)) {
			this.setRotation(this.rotation.x, this.rotation.y, this.rotation.z);
		}

		if (this.scaling.update(dt)) {
			this.scaleX = this.scaling.x;
			this.scaleY = this.scaling.y;
			this.scaleZ = this.scaling.z;
		} else {
			this.scaling.set(this.scaleX, this.scaleY, this.scaleZ);
		}

		if (this.color.update(dt)) {
			for (material in this.getMaterials()) {
				material.color.x = this.color.x;
				material.color.y = this.color.y;
				material.color.z = this.color.z;
				material.color.w = this.color.w;
			}
		}
	}

	@:from
	inline public static function fromBacking(obj:TweenObjectBacking) {
		return new TweenObject(obj);
	}

	@:from
	inline public static function fromObject(obj:Object) {
		return new TweenObject(new TweenObjectBacking(obj));
	}

	@:to
	inline public function toObject():Object {
		return this.object;
	}
}

@:structInit
class Transform {
	/**
		Position target
	**/
	public var pos:TweenTarget = null;

	/**
		Scale target
	**/
	public var scale:TweenTarget = null;

	/**
		Rotation target
	**/
	public var rotation:TweenTarget = null;

	/**
		Color target
	**/
	public var color:TweenTarget = null;
}
