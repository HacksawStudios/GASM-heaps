package gasm.heaps.components.debug;

import gasm.core.Component;
import gasm.core.components.SceneModelComponent;
import gasm.core.enums.ComponentType;
import gasm.core.utils.Assert;
import gasm.heaps.components.HeapsScene2DComponent;

class TweakComponent extends Component {
	var _s2d:h2d.Scene;
	var _fui:h2d.Flow;
	var _button:h2d.Flow;
	var _visible = true;

	public function new() {
		#if !debug
		throw 'TweakComponent can only be added in debug builds';
		#end
		componentType = ComponentType.Actor;
	}

	public override function init() {
		final sceneModel = owner.getFromRoot(SceneModelComponent);
		final sceneEntity = sceneModel.addScene({name: 'debug', interactive: true, is3D: false});
		final sceneComp = sceneEntity.get(HeapsScene2DComponent);
		_s2d = sceneComp.scene2d;
		_fui = new h2d.Flow(_s2d);
		_fui.layout = Vertical;
		_button = addButton("debug", () -> {
			_visible = !_visible;
			setVisible(_visible);
		});
		setVisible(false);
	}

	public function render(engine:h3d.Engine) {
		if (_s2d != null) {
			_s2d.render(engine);
		}
	}

	public function setVisible(visible:Bool) {
		for (childIndex in 0..._fui.numChildren) {
			_fui.getChildAt(childIndex).visible = visible;
		}
		_visible = visible;
		_button.visible = true;
	}

	function addButton(label:String, onClick:Void->Void) {
		var f = new h2d.Flow(_fui);
		final font = hxd.res.DefaultFont.get();
		font.resizeTo(12);
		f.padding = 15;
		f.paddingBottom = 30;
		f.backgroundTile = h2d.Tile.fromColor(0x404040);
		var tf = new h2d.Text(font, f);
		tf.text = label;
		f.enableInteractive = true;
		f.interactive.cursor = Button;
		f.interactive.onClick = function(_) onClick();
		f.interactive.onOver = function(_) f.backgroundTile = h2d.Tile.fromColor(0x606060);
		f.interactive.onOut = function(_) f.backgroundTile = h2d.Tile.fromColor(0x404040);
		return f;
	}

	public function addSlider(label:String, set:Float->Void, get:Void->Float, min:Float = 0.0, max:Float = 1.0) {
		Assert.that(_fui != null, 'TweakComponent not inited. Cannot add sliders on same frame as adding component');
		var f = new h2d.Flow(_fui);
		final font = hxd.res.DefaultFont.get();
		font.resizeTo(12);
		f.horizontalSpacing = 0;
		f.paddingBottom = 10;

		var tf = new h2d.Text(font, f);
		tf.text = label;
		tf.maxWidth = 300;
		tf.textAlign = Right;

		var sli = new h2d.Slider(255, 20, f);
		sli.minValue = min;
		sli.maxValue = max;
		sli.value = get();

		var tf = new h2d.TextInput(font, f);
		tf.text = "" + hxd.Math.fmt(sli.value);
		sli.onChange = function() {
			set(sli.value);
			tf.text = "" + hxd.Math.fmt(sli.value);
			f.needReflow = true;
		};
		tf.onChange = function() {
			var v = Std.parseFloat(tf.text);
			if (Math.isNaN(v))
				return;
			sli.value = v;
			set(v);
		};
		f.visible = _visible;
		return sli;
	}
}
