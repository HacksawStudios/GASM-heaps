package gasm.heaps.spine;

import spine.support.files.FileHandle;

/**
	Implementation of spine.support.files.FileHandle for handling of Spine json data used for creating skeleton
**/
class SpineConfigHandle implements FileHandle {
	/**
		Path declaration needed by interface, not used
	**/
	public var path:String;

	/**
		Spine config data, containing animations and mapping
	**/
	private final configData:String;

	public function new(configData:String) {
		path = '';
		this.configData = configData;
	}

	public function getContent():String {
		return configData;
	}
}
