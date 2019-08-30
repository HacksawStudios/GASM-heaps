package gasm.heaps.components;

import gasm.heaps.text.ScalingTextField;
import h2d.Tile;
import h2d.Bitmap;
import h2d.Object;
import h3d.mat.Texture;
import h3d.mat.Data.TextureFlags;
import gasm.core.data.TextConfig;
import h2d.Font;
import h2d.Text;
import hxd.Res;
import gasm.core.components.TextModelComponent;
import gasm.core.enums.ComponentType;

/**
 * ...
 * @author Leo Bergman
 */
class HeapsTextComponent extends HeapsSpriteComponent {
	public var textField(default, null):ScalingTextField;

	var _config:TextConfig;
	var _font:h2d.Font;
	var _text:String;
	var _showOutline:Bool;
	var _textModel:TextModelComponent;
	var _lastW:Float;
	var _lastH:Float;
	var _holder:Object;
	var _bitmap:Bitmap;

	public function new(config:TextConfig) {
		super(new Object());
		_holder = new Object(sprite);
		componentType = ComponentType.Text;
		_text = config.text != null ? config.text : '';
		config.scaleToFit = config.scaleToFit == null ? true : config.scaleToFit;
		config.letterSpacing = config.letterSpacing == null ? 0 : config.letterSpacing;
		_config = config;
	}

	override public function setup() {
		super.setup();
		_font = cast(_config.font, h2d.Font);
		textField = new ScalingTextField(_font, _holder);
		textField.smooth = true;
		textField.letterSpacing = _config.letterSpacing != null ? _config.letterSpacing : 0;
		textField.lineSpacing = _config.lineSpacing != null ? _config.lineSpacing : 0;
		textField.rotation = _config.rotation != null ? _config.rotation : 0.0;
		textField.textAlign = switch (_config.align) {
			case 'left': Align.Left;
			case 'right': Align.Right;
			default: Align.Center;
		};

		if (_config.filters != null && _config.filters.length > 0) {
			sprite.filter = new h2d.filter.Group(cast _config.filters);
		}
	}

	override public function init() {
		super.init();
		_textModel = owner.get(TextModelComponent);
		_textModel.font = _font.name;
		_textModel.size = _font.size;
		_textModel.color = textField.textColor = _config.color;
		textField.text = _textModel.text = _text;
		if (_config.scaleToFit) {
			textField.scaleToFit(_config.width);
		}

		var w = textField.getBounds().width;
		var h = textField.getBounds().height;
		if (w > 0) {
			_textModel.width = w;
			_textModel.height = h;
		}
		if (_config.cacheFiltersAsBitmap) {
			toBitmap();
		}
	}

	function toBitmap() {
		if (_bitmap != null) {
			_bitmap.remove();
		}
		_holder.visible = true;
		var bounds = textField.getBounds();
		var xOff = switch (_config.align) {
			case 'left': 0;
			case 'right': bounds.width;
			default: bounds.width / 2;
		}
		textField.x = xOff;
		var tex = new Texture(Std.int(_holder.getBounds().width), Std.int(_holder.getSize().height), [TextureFlags.Target]);
		var s2d = owner.getFromParents(HeapsScene2DComponent).scene2d;
		s2d.addChild(_holder);
		_holder.drawTo(tex);
		_holder.visible = false;
		s2d.removeChild(_holder);
		var tile = Tile.fromTexture(tex);
		_bitmap = new Bitmap(tile);
		sprite.addChild(_bitmap);
	}

	override public function update(delta:Float) {
		var textChanged = false;
		if (textField.text != _textModel.text) {
			textField.text = _textModel.text;
			textChanged = true;
		}
		var formatChanged = false;
		if (_font.name != _textModel.font || _font.size != _textModel.size) {
			_config.font = _textModel.font;
			_font.resizeTo(_textModel.size);
			formatChanged = true;
		}
		if (_config.color != _textModel.color) {
			textField.textColor = _config.color = _textModel.color;
		}
		sprite.x = _textModel.x + _textModel.offsetX;
		sprite.y = _textModel.y + _textModel.offsetY;
		var w = textField.getBounds().width;
		var h = textField.getBounds().height;
		if (w != _lastW) {
			_textModel.width = w;
		}
		if (h != _lastH) {
			_textModel.height = h;
		}
		_lastW = _textModel.width;
		_lastH = _textModel.height;
		textField.visible = _textModel.visible;
		if (textChanged || formatChanged) {
			if (_config.scaleToFit) {
				textField.scaleToFit(_textModel.width);
			}
			if (_config.cacheFiltersAsBitmap) {
				toBitmap();
			}
		}
	}
}
