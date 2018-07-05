package gasm.heaps.data;

typedef Atlas = {
    tile:h2d.Tile, 
    contents:Map<String, Array<{width:Int, height:Int, t:h2d.Tile}>>, 
    tiles:Array<h2d.Tile>
};