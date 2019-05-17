package gasm.heaps.fs;

typedef VirtualFileEntry = hxd.fs.BytesFileSystem.BytesFileEntry;

class VirtualFileSystem implements hxd.fs.FileSystem {
	final paths = new haxe.ds.StringMap<VirtualFileEntry>();

	public function new() {}

	public function add(path, bytes) {
		trace('adding $path');
		paths.set(path, new VirtualFileEntry(path, bytes));
	}

	public function getRoot() {
		throw "Not implemented";
		return null;
	}

	public function getBytes(path:String):haxe.io.Bytes {
		return get(path).getBytes();
	}

	public function exists(path:String) {
		return paths.exists(path);
	}

	public function get(path:String) {
		var entry = paths.get(path);
		if (entry == null)
			throw "Resource not found '" + path + "'";
		return entry;
	}

	public function dispose() {
		// paths.empty();
	}

	public function dir(path:String):Array<hxd.fs.FileEntry> {
		throw "Not implemented";
		return null;
	}
}
