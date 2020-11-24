package gasm.heaps.data;

import h2d.Tile;

@:structInit class Spine {
	/**
		Spine tile atlas containing the elements/attachments
	**/	
	public var tile:Tile;
	/**
		Spine atlas containing the elements/attachments data
	**/	
	public var atlas:String;
	/**
		Spine config data, containing animations and mapping
	**/	
	public var config:String;
}
