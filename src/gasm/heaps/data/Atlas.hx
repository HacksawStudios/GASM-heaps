package gasm.heaps.data;

import h2d.Tile;

@:structInit class Atlas {
	public var tile:Tile;
	public var contents:Map<String, Array<AtlasContents>>;
	public var animation:AtlasAnimation;
	public var scale = 1.0;
}

typedef AtlasContents = {
	width:Int,
	height:Int,
	t:Tile,
	?scale9:Scale9,
}

typedef AtlasAnimation = {
	frames:Array<Tile>,
	width:Int,
	height:Int,
}

typedef Scale9 = {
	tl:Tile,
	tm:Tile,
	tr:Tile,
	ml:Tile,
	mm:Tile,
	mr:Tile,
	bl:Tile,
	bm:Tile,
	br:Tile,
}
