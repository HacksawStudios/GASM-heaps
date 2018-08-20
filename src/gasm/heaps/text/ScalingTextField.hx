package gasm.heaps.text;

class ScalingTextField extends h2d.Text {
    public function new(font:h2d.Font, ?parent) {
        super(font, parent);
    }
    public inline function scaleToFit(w:Float) {
        var actualW = calcTextWidth(text);
        var i = 0;
        var size = font.size;
        while(actualW > w && i < 150) {
            size--;
            font.resizeTo(size);
            i++;
            actualW = calcTextWidth(text);
        }
    }
    public inline function toBitmap(?marginX:Int = 0, ?marginY:Int = 0) {
        var tex = new Texture(Std.int(this.getSize().xMax) + marginX, Std.int(this.getSize().yMax) + marginY, [TextureFlags.Target]);
        this.drawTo(tex);
        var tile = Tile.fromTexture(tex);
        var bm = new Bitmap(tile);
    }
}
