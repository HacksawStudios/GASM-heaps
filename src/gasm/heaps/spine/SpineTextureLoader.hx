package gasm.heaps.spine;

import spine.support.graphics.TextureAtlas;
import spine.support.graphics.TextureLoader;

/**
	Implementation of spine.support.graphics.TextureLoader for handling of Spine tile data used for creating TextureAtlas
**/
class SpineTextureLoader implements TextureLoader {
	/**
		Spine tile atlas containing the elements/attachments
	**/
	var tile:h2d.Tile;

	public function new(t:h2d.Tile) {
		tile = t;
	}

	/**
		Load Spine AtlasPage
	**/
	public function loadPage(page:AtlasPage, path:String):Void {
		page.rendererObject = tile;
		page.width = Std.int(tile.width);
		page.height = Std.int(tile.height);
	}

	/**
		Load Spine AtlasRegion
	**/
	public function loadRegion(region:AtlasRegion):Void {}

	/**
		Unload Spine AtlasPage
	**/
	public function unloadPage(page:AtlasPage):Void {
		page.rendererObject = null;
	}
}
