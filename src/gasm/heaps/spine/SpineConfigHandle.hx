package gasm.heaps.spine;

import spine.support.files.FileHandle;

class SpineConfigHandle implements FileHandle {
	public var path:String;

	private final data:String;

	public function new(configData:String) {
		path = '';
		data = configData;
	}

	public function getContent():String {
		return data;
	}
}
