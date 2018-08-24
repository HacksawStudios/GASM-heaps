package gasm.heaps.components;

import gasm.core.Component;
import gasm.heaps.text.ScalingTextField;
import h2d.Tile;
import h2d.Bitmap;
import h2d.Sprite;
import h2d.filter.Glow;
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
    var _outlineMargin = 0.0;
    var _holder:Sprite;
    var _bitmap:Bitmap;

    public function new(config:TextConfig) {
        super(new Sprite());
        _font = cast(config.font, h2d.Font);
        _holder = new Sprite(sprite);
        textField = new ScalingTextField(_font, _holder);
        var scale = config.size / _font.size;
        textField.scale(scale);
        textField.smooth = true;
        componentType = ComponentType.Text;
        _text = config.text != null ? config.text : '';
        config.scaleToFit = config.scaleToFit == null ? true : config.scaleToFit;
        config.letterSpacing = config.letterSpacing == null ? 0 : config.letterSpacing;
        _config = config;
    }

    override public function init() {
        super.init();
        _textModel = owner.get(TextModelComponent);
        _textModel.font = _config.font;
        _textModel.size = _config.size;
        _textModel.color = textField.textColor = _config.color;
        textField.textAlign = switch(_config.align) {
            case 'left': Align.Left;
            case 'right': Align.Right;
            default: Align.Center;
        };
        textField.text = _textModel.text = _text;
        if(_config.filters != null) {
           _holder.filter = new h2d.filter.Group(cast _config.filters);
        }
        
        textField.letterSpacing = _config.letterSpacing != null ? _config.letterSpacing : 0;
        var w = textField.getSize().width;
        var h = textField.getSize().height;
        if (w > 0) {
            _textModel.width = w;
            _textModel.height = h;
        }
        if(_config.scaleToFit){
            textField.scaleToFit(_config.width);
        }
        if(_config.outlines != null && _config.outlines.length > 0) {
            outline(cast _config.outlines);
        }
        if(_config.bitmap) {
            toBitmap();
        }
    }

    function outline(outlines:Array<TextOutlineConfig>) {
        var filters:Array<h2d.filter.Filter> = [];
        for (outline in outlines) {
            _outlineMargin += outline.radius;
            filters.push(new Glow(outline.color, outline.alpha, outline.radius, outline.gain, outline.quality, true));
        }
        if(_config.align == 'left') {
            textField.x = textField.y = _outlineMargin;
        } else if(_config.align == 'right') {
            textField.x = textField.y = textField.textWidth - _outlineMargin;
        }
        textField.filter = new h2d.filter.Group(filters);
    }

    function toBitmap() {
        if(_bitmap != null) {
            _bitmap.remove();
        }
        _holder.visible = true;
        var tex = new Texture(Std.int(sprite.getSize().width + _outlineMargin) , Std.int(sprite.getSize().height + _outlineMargin), [TextureFlags.Target]);
        cast(_appModel.stage, h2d.Scene).addChild(_holder);
        _holder.drawTo(tex);
        cast(_appModel.stage, h2d.Scene).removeChild(_holder);
        var tile = Tile.fromTexture(tex);
        _bitmap = new Bitmap(tile);
        _holder.visible = false;
        sprite.addChild(_bitmap);
    }

    override public function update(delta:Float) {
        var textChanged = false;
        if (textField.text != _textModel.text) {
            textField.text = _textModel.text;
            textChanged = true;
        }
        var formatChanged = false;
        if (_config.font != _textModel.font || _config.size != _textModel.size) {
            _config.font = _textModel.font;
            _config.size = _textModel.size;
            #if (heaps > "1.1.0")
            textField.font = Res.load(_config.font).to(hxd.res.Font).build(_config.size);
            #else
            textField.font = Res.load(_config.font).toFont().build(_config.size);
            #end
            formatChanged = true;
        }
        if (_config.color != _textModel.color) {
            textField.textColor = _config.color = _textModel.color;
        }
        textField.x = _textModel.x + _textModel.offsetX;
        textField.y = _textModel.y + _textModel.offsetY;
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
        if(textChanged || formatChanged) {
            if(_config.scaleToFit){
                textField.scaleToFit(_textModel.width);
            }
            if(_config.bitmap) {
                toBitmap();
            }
        }
    }
}

class TextOutlineConfig implements DataClass {
    public var color:Int = 0x00000000;
    public var alpha:Float = 1.0;
    public var radius:Float = 1.0;
    public var gain:Float = 1.0;
    public var quality:Float = 1.0;
}