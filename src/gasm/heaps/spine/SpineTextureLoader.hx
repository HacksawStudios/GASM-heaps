package gasm.heaps.spine;

import spine.support.graphics.TextureLoader;
import spine.support.graphics.TextureAtlas;

class SpineTextureLoader implements TextureLoader {
	private var tile:h2d.Tile;

	public function new(t:h2d.Tile) {
		tile = t;
	}

	public function loadPage(page:AtlasPage, path:String):Void {
		page.rendererObject = tile;
		page.width = Std.int(tile.width);
		page.height = Std.int(tile.height);
	}

	public function loadRegion(region:AtlasRegion):Void {}

	public function unloadPage(page:AtlasPage):Void {
		page.rendererObject = null;
	}
}
