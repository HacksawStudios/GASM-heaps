package gasm.heaps.text;

import h2d.Tile;
import h2d.Bitmap;
import h3d.mat.Data.TextureFlags;
import h3d.mat.Texture;

class ScalingTextField extends h2d.Text {
	public var currSize(default, null):{w:Float, h:Float};
	// Fonts extending below descender limit will be cut off in heaps text field for some reason
	// This margin fixes issues with bottom part of fonts being cutt of in most cases, but you can incrase it if you still experience issues
	public var yMarg(default, default) = 10;

	var _origSize:Int;
	var _size:Int;

	public function new(font:h2d.Font, ?parent) {
		_origSize = _size = font.size;
		var f = font.clone();
		@:privateAccess f.tile.innerTex.preventAutoDispose();
		super(f, parent);
	}

	public inline function scaleToFit(w:Float) {
		var actualW = calcTextWidth(text);
		var scale = w / actualW;
		var size = Std.int(Math.min(_origSize, Std.int(_origSize * scale)));
		if (size != _size) {
			font.resizeTo(size);
			_size = size;
		}
		currSize = {w: getBounds().width, h: getBounds().height};
	}

	public inline function toBitmap(?marginX:Int = 0, ?marginY:Int = 0):Bitmap {
		var tex = new Texture(Std.int(this.getSize().xMax) + marginX, Std.int(this.getSize().yMax) + marginY, [TextureFlags.Target]);
		this.drawTo(tex);
		var tile = Tile.fromTexture(tex);
		var bm = new Bitmap(tile);
		return bm;
	}

	override function initGlyphs(text:hxd.UString, rebuild = true, handleAlign = true, lines:Array<Int> = null):Void {
		super.initGlyphs(text, rebuild, handleAlign, lines);
		calcHeight += yMarg;
	}
}
