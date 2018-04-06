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
}
