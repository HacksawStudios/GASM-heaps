package gasm.heaps.data;

import h2d.Tile;

typedef Atlas = {
	tile:Tile,
	contents:Map<String, Array<AtlasContents>>,
	tiles:Array<Tile>
};

typedef AtlasContents = {
	width:Int,
	height:Int,
	t:Tile,
	?scale9:Scale9
};

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
