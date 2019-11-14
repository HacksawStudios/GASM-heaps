package gasm.heaps;

import gasm.assets.Loader;
import gasm.assets.Loader.AssetType;
import gasm.core.components.AppModelComponent;
import gasm.core.components.SceneModelComponent;
import gasm.core.Context;
import gasm.core.Engine;
import gasm.core.Entity;
import gasm.core.enums.Orientation;
import gasm.core.IEngine;
import gasm.core.ISystem;
import gasm.heaps.components.Heaps3DComponent;
import gasm.heaps.components.HeapsScene2DComponent;
import gasm.heaps.components.HeapsScene3DComponent;
import gasm.heaps.components.HeapsSceneBase;
import gasm.heaps.components.HeapsSceneModelComponent;
import gasm.heaps.components.HeapsSpriteComponent;
import gasm.heaps.data.Atlas;
import gasm.heaps.systems.HeapsCoreSystem;
import gasm.heaps.systems.HeapsRenderingSystem;
import gasm.heaps.systems.HeapsSoundSystem;
import h2d.Tile;
import h3d.impl.GlDriver;
import h3d.mat.Data.TextureFlags;
import h3d.mat.Texture;
import hacksaw.common.enums.Orientation;
import hacksaw.core.utils.GuardAction;
import haxe.ds.StringMap;
import haxe.io.BytesData;
import haxe.io.Path;
import hex.di.Injector;
import hxd.App;
import hxd.Charset;
import hxd.impl.TypedArray.ArrayBuffer;
import hxd.SceneEvents;
import js.lib.DataView;
import tweenx909.TweenX;

using StringTools;
using Lambda;

/**
 * ...
 * @author Leo Bergman
 */
class HeapsContext extends App implements Context {
	public var baseEntity(get, null):Entity;
	public var systems(default, null):Array<ISystem>;
	public var appModel(default, null):AppModelComponent;
	public var sceneModel(default, null):SceneModelComponent;

	var _engine:IEngine;
	var _core:ISystem;
	var _renderer:ISystem;
	var _sound:ISystem;
	// Populate in subclass with bindings to asset containers
	var _assetContainers:AssetContainers;
	var _assetConfig:AssetConfig;
	var _soundSupport:Bool;
	var _basisSupport:Bool;
	var _injector:Injector;
	final _fileSystem = new gasm.heaps.fs.VirtualFileSystem();

	public function new(?core:ISystem, ?renderer:ISystem, ?sound:ISystem, ?engine:IEngine) {
		_core = core;
		_renderer = renderer;
		_sound = sound;
		_engine = engine;
		super();

		appModel = new AppModelComponent();
		_assetConfig = {};
	}

	public function preload(progress:Int->Void, done:Void->Void) {
		#if js
		_soundSupport = (Reflect.field(js.Browser.window, "AudioContext") != null
			|| Reflect.field(js.Browser.window, "webkitAudioContext") != null);
		_assetConfig.formats = [];
		if (_soundSupport) {
			var myAudio:js.html.AudioElement = cast js.Browser.document.createElement('audio');
			if (myAudio.canPlayType != null) {
				var canPlayMp4 = myAudio.canPlayType('video/mp4');
				var canPlayWebm = myAudio.canPlayType('audio/webm; codecs="vorbis"');
				var supported = {webm: canPlayWebm, mp4: canPlayMp4};
				var ext:String = switch (supported) {
					case {webm: 'probably'}: '.webm';
					case {webm: 'maybe', mp4: 'probably'}: '.mp4';
					case {webm: 'maybe', mp4: 'maybe'}: '.webm';
					case {webm: 'maybe', mp4: ''}: '.webm';
					case {webm: '', mp4: 'maybe'}: '.mp4';
					case {webm: '', mp4: 'probably'}: '.mp4';
					default: null;
				}
				if (ext == null) {
					_soundSupport = false;
					trace('Neither webm or m4a supported, no audio will play');
				} else {
					_soundSupport = true;
					_assetConfig.formats.push({type: AssetType.Sound, extension: ext});
				}
			}
		}
		final glDriver:GlDriver = cast h3d.Engine.getCurrent().driver;
		_basisSupport = switch (glDriver.textureSupport) {
			case hxd.PixelFormat.ETC(_), null: false;
			default: true;
		}
		#if debug
		_assetConfig.formats.push({type: AssetType.AtlasImage, extension: '.png'});
		#else
		if (_basisSupport) {
			_assetConfig.formats.push({type: AssetType.Image, extension: '.basis'});
			_assetConfig.formats.push({type: AssetType.AtlasImage, extension: '.basis'});
		} else {
			_assetConfig.formats.push({type: AssetType.AtlasImage, extension: '.png'});
		}
		#end
		appModel.pixelRatio = js.Browser.window.devicePixelRatio;
		#end
		engine.render(this);
		var asyncItems = 0;
		var atlases = new haxe.ds.StringMap<haxe.io.Bytes>();
		var loader = new Loader('assets/desc.json', _assetConfig);

		loader.onReady = function() {
			hxd.res.Loader.currentInstance = new hxd.res.Loader(_fileSystem);
			for (img in Type.getClassFields(_assetContainers.images)) {
				asyncItems++;
				loader.queueItem(img, AssetType.Image);
			}
			if (_soundSupport) {
				for (snd in Type.getClassFields(_assetContainers.sounds)) {
					loader.queueItem(snd, AssetType.Sound);
				}
			}
			for (fnt in Type.getClassFields(hacksaw.core.data.FontList)) {
				loader.queueItem(fnt, AssetType.Font);
			}
			for (fnt in Type.getClassFields(hacksaw.core.data.BitmapFontList)) {
				loader.queueItem(fnt, AssetType.BitmapFont);
			}
			for (atlas in Type.getClassFields(_assetContainers.atlases)) {
				asyncItems++;
				loader.queueItem(atlas, AssetType.Atlas);
			}
			for (gradient in Type.getClassFields(_assetContainers.gradients)) {
				loader.queueItem(gradient, AssetType.Gradient);
			}
			for (config in Reflect.fields(_assetContainers.brandingConfigs)) {
				loader.queueItem(config, AssetType.Config);
			}
			for (config in Reflect.fields(_assetContainers.models)) {
				loader.queueItem(config, AssetType.Model);
			}
			loader.load();
		}
		loader.onComplete = function() {
			new GuardAction(() -> asyncItems == 0, done);
		}
		loader.onProgress = function(percent:Int) {
			progress(percent);
			engine.render(this);
		}
		loader.onError = function(error:String) {
			throw error;
		}

		loader.addHandler(AssetType.Image, function(item:HandlerItem) {
			final name = 'image/${item.id}';
			final ext = Path.extension(item.path);
			_fileSystem.add(item.path, item.data);
			getImageTexture(item.path, ext, name).then((texture) -> {
				asyncItems--;
				Reflect.setField(_assetContainers.images, item.id, Tile.fromTexture(texture));
			});
		});

		loader.addHandler(AssetType.Sound, function(item:HandlerItem) {
			#if byteSounds
			Reflect.setField(_assetContainers.sounds, item.id, item.data);
			#else
			Reflect.setField(_assetContainers.sounds, item.id, hxd.res.Any.fromBytes('sound/${item.id}', item.data).toSound());
			#end
		});

		loader.addHandler(AssetType.Font, function(item:HandlerItem) {
			var fnt = hxd.res.Any.fromBytes('font/${item.id}', item.data).to(hxd.res.Font);
			if (fnt != null) {
				_assetContainers.fonts.set(item.id, fnt);
			} else {
				throw 'Unable to parse font ' + item.id;
			}
		});

		loader.addHandler(AssetType.BitmapFont, function(item:HandlerItem) {
			final name = item.id.split('.')[0];
			final fontPath = 'fonts/$name.fnt';
			final imagePath = 'fonts/$name.png';
			final fontData = item.data;
			_fileSystem.add(fontPath, fontData);
			if (_fileSystem.exists(imagePath)) {
				final font = new hxd.res.BitmapFont(_fileSystem.get(fontPath));
				_assetContainers.bitmapFonts.set(item.id, font);
			}
		});

		loader.addHandler(AssetType.BitmapFontImage, function(item:HandlerItem) {
			final name = item.id.split('.')[0];
			final fontPath = 'fonts/$name.fnt';
			final imagePath = 'fonts/$name.png';
			final imageData = item.data;
			_fileSystem.add(imagePath, imageData);
			if (_fileSystem.exists(fontPath)) {
				final font = new hxd.res.BitmapFont(_fileSystem.get(fontPath));
				_assetContainers.bitmapFonts.set(item.id, font);
			}
		});

		loader.addHandler(AssetType.Atlas, function(item:HandlerItem) {
			final name = item.id;
			_fileSystem.add('atlas/$name.atlas', item.data);
			final imageFormat = _assetConfig.formats.find(val -> val.type == AssetType.AtlasImage);
			final preferredExt = imageFormat != null ? imageFormat.extension : null;
			final getAtlas = (path, ext) -> {
				getImageTexture(path, ext, 'atlas/$name').then((texture) -> {
					final atlas = parseAtlas('$name$ext', item.data, Tile.fromTexture(texture));
					asyncItems--;
					Reflect.setField(_assetContainers.atlases, item.id, atlas);
				});
			}
			final validExt = ['.basis', '.png', '.jpg', '.jpeg'].find(ext -> _fileSystem.exists('atlas/$name$ext'));
			if (validExt != null) {
				final imagePath = 'atlas/$name$validExt';
				getAtlas(imagePath, preferredExt);
			}
		});

		loader.addHandler(AssetType.AtlasImage, function(item:HandlerItem) {
			final name = item.id;
			final ext = Path.extension(item.path);
			final atlasPath = 'atlas/$name.atlas';
			final imagePath = 'atlas/$name.$ext';
			final imageData = item.data;
			_fileSystem.add(imagePath, imageData);
			if (_fileSystem.exists(atlasPath)) {
				getImageTexture(imagePath, ext, 'atlas/$name').then((texture) -> {
					asyncItems--;
					final atlas = parseAtlas('$name.$ext', _fileSystem.get(atlasPath).getBytes(), Tile.fromTexture(texture));
					Reflect.setField(_assetContainers.atlases, item.id, atlas);
				});
			}
		});

		loader.addHandler(AssetType.Gradient, function(item:HandlerItem) {
			var grd = hxd.res.Any.fromBytes('${item.path}', item.data).to(hxd.res.Gradients);
			Reflect.setField(_assetContainers.gradients, item.id, grd);
		});

		loader.addHandler(AssetType.Config, function(item:HandlerItem) {
			switch (item.id) {
				case 'gameconfig':
					var data = haxe.Json.parse(item.data.toString());
					Reflect.setField(_assetContainers.brandingConfigs, item.id, data);
				default:
					null;
			}
		});

		loader.addHandler(AssetType.Model, function(item:HandlerItem) {
			var model = hxd.res.Any.fromBytes('${item.path}', item.data).to(hxd.res.Model);
			Reflect.setField(_assetContainers.models, item.id, model);
		});
	}

	override function init() {
		_core = _core != null ? _core : new HeapsCoreSystem(s2d);
		_renderer = _renderer != null ? _renderer : new HeapsRenderingSystem(s2d);
		_sound = _sound != null ? _sound : new HeapsSoundSystem();
		systems = [_core, _renderer, _sound];
		_engine = _engine != null ? _engine : new Engine(systems);
		_engine.getDelta = () -> hxd.Timer.dt;
		mapInjections();
		#if js
		var hidden:String = null;
		var visibilityChange:String = null;
		if (js.Browser.document.hidden != null) { // Opera 12.10 and Firefox 18 and later support
			hidden = 'hidden';
			visibilityChange = 'visibilitychange';
		} else if (Reflect.field(js.Browser.document, 'msHidden') != null) {
			hidden = 'msHidden';
			visibilityChange = 'msvisibilitychange';
		} else if (Reflect.field(js.Browser.document, 'webkitHidden') != null) {
			hidden = 'webkitHidden';
			visibilityChange = 'webkitvisibilitychange';
		}
		final handleVisibilityChange = () -> {
			final frozen = Reflect.field(js.Browser.document, hidden);
			if (frozen != appModel.frozen) {
				if (frozen) {
					_engine.pause();
				} else {
					_engine.resume();
				}
				appModel.frozen = frozen;
				appModel.freezeSignal.emit(appModel.frozen);
			}
		}
		js.Browser.document.addEventListener(visibilityChange, handleVisibilityChange, false);
		appModel.frozen = Reflect.field(js.Browser.document, hidden);
		// Show error when WebGL context lost
		js.Syntax.code("var canvas = document.getElementById('webgl');
			canvas.addEventListener('webglcontextlost', function(event) {
				throw new Error('WebGL context lost, please reload game');
			});");
		#end
		appModel.frozen = false;
		baseEntity.add(sceneModel);
		baseEntity.add(appModel);
		onResize();
	}

	override function onResize() {
		var stage = hxd.Window.getInstance();
		appModel.stageSize.x = stage.width;
		appModel.stageSize.y = stage.height;
		appModel.orientation = stage.height > stage.width ? Orientation.PORTRAIT : Orientation.LANDSCAPE;

		for (scene in sceneModel.scenes) {
			if (!scene.is3D) {
				var instance2d:h2d.Scene = cast scene.instance;
				instance2d.checkResize();
			}
		}

		appModel.resizeSignal.emit({width: appModel.stageSize.x, height: appModel.stageSize.y});
	}

	override function update(dt:Float) {
		_engine.tick();
	}

	override public function render(e:h3d.Engine) {
		if (appModel.customRenderCallback != null) {
			appModel.customRenderCallback(e);
		} else {
			var scenes = 0;
			if (sceneModel != null) {
				for (scene in sceneModel.scenes) {
					if (!scene.is3D) {
						final sceneComp = scene.entity.getFromParents(HeapsScene2DComponent);
						sceneComp.render(e);
					} else {
						final sceneComp = scene.entity.getFromParents(HeapsScene3DComponent);
						sceneComp.render(e);
					}
					scenes++;
				}
			}
			// If no scenes added, just render default s3d and s2d
			if (scenes == 0) {
				super.render(e);
			}
		}
	}

	function getImageTexture(path:String, ext:String, name:String):js.lib.Promise<h3d.mat.Texture> {
		return switch ext {
			case 'basis':
				final bytes = _fileSystem.get(path).getBytes().getData();
				hxd.res.BasisTextureLoader.getTexture(bytes);
			default:
				final bytes = _fileSystem.get(path).getBytes();
				js.lib.Promise.resolve(hxd.res.Any.fromBytes(path, bytes).toTexture());
		}
	}

	function mapInjections() {
		_injector = new Injector();
		sceneModel = new HeapsSceneModelComponent(_injector);
		_injector.map(SceneEvents).toValue(sevents);
		_injector.map(SceneModelComponent).toValue(sceneModel);
		_injector.map(Entity).toValue(baseEntity);
		_injector.map(AppModelComponent).toValue(appModel);
		_injector.map(SceneModelComponent).toValue(sceneModel);
	}

	function parseAtlas(id:String, definition:haxe.io.Bytes, tile:Tile):Atlas {
		var contents = new Map();
		var lines = definition.toString().split("\n");
		while (lines.length > 0) {
			var line = StringTools.trim(lines.shift());
			if (line == "")
				continue;
			while (lines.length > 0) {
				var line = StringTools.trim(lines.shift());
				if (line == "")
					break;
				var prop = line.split(": ");
				if (prop.length > 1)
					continue;
				var key = line;
				var tileX = 0, tileY = 0, tileW = 0, tileH = 0, tileDX = 0, tileDY = 0, origW = 0, origH = 0, index = 0;
				var scale9Tiles:Scale9 = null;
				while (lines.length > 0) {
					var line = StringTools.trim(lines.shift());
					var prop = line.split(": ");
					if (prop.length == 1) {
						lines.unshift(line);
						break;
					}
					var v = prop[1];
					switch (prop[0]) {
						case "rotate":
							if (v == "true")
								throw "Rotation not supported in atlas";
						case "xy":
							var vals = v.split(", ");
							tileX = Std.parseInt(vals[0]);
							tileY = Std.parseInt(vals[1]);
						case "size":
							var vals = v.split(", ");
							tileW = Std.parseInt(vals[0]);
							tileH = Std.parseInt(vals[1]);
						case "offset":
							var vals = v.split(", ");
							tileDX = Std.parseInt(vals[0]);
							tileDY = Std.parseInt(vals[1]);
						case "orig":
							var vals = v.split(", ");
							origW = Std.parseInt(vals[0]);
							origH = Std.parseInt(vals[1]);
						case "index":
							index = Std.parseInt(v);
							if (index < 0)
								index = 0;
						case "split":
							var vals = v.split(", ").map(val -> Std.parseInt(val));
							var lw = vals[0];
							var rw = vals[1];
							var mw = tileW - (lw + rw);
							var th = vals[2];
							var bh = vals[3];
							var mh = tileH - (th + bh);
							scale9Tiles = {
								tl: tile.sub(tileX, tileY, lw, th, tileDX, tileDY),
								tm: tile.sub(tileX + lw, tileY, mw, th, tileDX, tileDY),
								tr: tile.sub(tileX + lw + mw, tileY, rw, th, tileDX, tileDY),
								ml: tile.sub(tileX, tileY + th, lw, mh, tileDX, tileDY),
								mm: tile.sub(tileX + lw, tileY + th, mw, mh, tileDX, tileDY),
								mr: tile.sub(tileX + lw + mw, tileY + th, rw, mh, tileDX, tileDY),
								bl: tile.sub(tileX, tileY + th + mh, lw, bh, tileDX, tileDY),
								bm: tile.sub(tileX + lw, tileY + th + mh, mw, bh, tileDX, tileDY),
								br: tile.sub(tileX + lw + mw, tileY + th + mh, rw, bh, tileDX, tileDY),
							};
						case "pad":
						// Represents scale9 with padding instead, already done what's needed in split
						default:
							trace("Unknown prop " + prop[0]);
					}
				}
				// offset is bottom-relative
				tileDY = origH - (tileH + tileDY);

				var t = tile.sub(tileX, tileY, tileW, tileH, tileDX, tileDY);
				var tl = contents.get(key);
				if (tl == null) {
					tl = [];
					contents.set(key, tl);
				}
				tl[index] = {
					t: t,
					width: origW,
					height: origH,
					scale9: scale9Tiles
				};
			}
		}

		var maxW = 0;
		var maxH = 0;
		var frames:Array<h2d.Tile> = [];

		for (key in contents.keys()) {
			var c:Array<AtlasContents> = contents.get(key);
			for (frame in c) {
				if (frame != null) {
					maxW = Std.int(Math.max(maxW, frame.width));
					maxH = Std.int(Math.max(maxW, frame.height));
					frames.push(frame.t);
				} else {
					frames.push(null);
				}
			}
		}
		var animation:AtlasAnimation = {
			width: maxW,
			height: maxH,
			frames: frames,
		};
		var atlas:Atlas = {
			tile: tile,
			contents: contents,
			animation: animation,
		}
		return atlas;
	}

	@:access(h2d.Font)
	function parseFont(id:String, definition:haxe.io.Bytes, image:haxe.io.Bytes):h2d.Font {
		// Taken from https://github.com/HeapsIO/heaps/blob/master/hxd/res/BitmapFont.hx since there seems to be no way to parse bitmap font without using heaps resrouce system directly.
		var xml = new haxe.xml.Access(Xml.parse(definition.toString()).firstElement());
		var tile = hxd.res.Any.fromBytes('font/$id', image).toTile();
		var glyphs = new Map();
		var size = Std.parseInt(xml.att.size);
		var lineHeight = Std.parseInt(xml.att.height);
		var name = xml.att.family;
		for (c in xml.elements) {
			var r = c.att.rect.split(" ");
			var o = c.att.offset.split(" ");
			var t = tile.sub(Std.parseInt(r[0]), Std.parseInt(r[1]), Std.parseInt(r[2]), Std.parseInt(r[3]), Std.parseInt(o[0]), Std.parseInt(o[1]));
			var fc = new h2d.Font.FontChar(t, Std.parseInt(c.att.width) - 1);
			for (k in c.elements)
				fc.addKerning(k.att.id.charCodeAt(0), Std.parseInt(k.att.advance));
			var code = c.att.code;
			if (StringTools.startsWith(code, "&#"))
				glyphs.set(Std.parseInt(code.substr(2, code.length - 3)), fc);
			else
				glyphs.set(c.att.code.charCodeAt(0), fc);
		}
		if (glyphs.get(" ".code) == null)
			glyphs.set(" ".code, new h2d.Font.FontChar(tile.sub(0, 0, 0, 0), size >> 1));

		var font = new h2d.Font(name, size);
		font.glyphs = glyphs;
		font.lineHeight = lineHeight;
		font.tile = tile;

		var padding = 0;
		var space = glyphs.get(" ".code);
		if (space != null)
			padding = (Std.int(space.t.height) >> 1);

		var a = glyphs.get("A".code);
		if (a == null)
			a = glyphs.get("a".code);
		if (a == null)
			a = glyphs.get("0".code); // numerical only
		if (a == null)
			font.baseLine = font.lineHeight - 2 - padding;
		else
			font.baseLine = a.t.dy + a.t.height - padding;

		return font;
	}

	public function get_baseEntity():Entity {
		return _engine.baseEntity;
	}
}

typedef AssetContainers = {
	?images:Dynamic,
	?sounds:Dynamic,
	?fonts:haxe.ds.StringMap<hxd.res.Font>,
	?bitmapFonts:haxe.ds.StringMap<hxd.res.BitmapFont>,
	?atlases:Dynamic,
	?gradients:Dynamic,
	?configs:Dynamic,
	?brandingConfigs:BrandingConfigs,
	?models:Dynamic,
}

typedef BrandingConfigs = {
	gameconfig:Dynamic,
	sounds:Dynamic,
	pools:Dynamic,
	events:Dynamic,
	groups:Dynamic
}
