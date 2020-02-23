package gasm.heaps.data;

import h2d.Tile;

typedef Atlas = {
	tile:Tile,
	contents:Map<String, Array<AtlasContents>>,
	animation:AtlasAnimation,
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
