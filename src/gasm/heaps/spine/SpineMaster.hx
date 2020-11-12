package gasm.heaps.spine;

import gasm.heaps.data.Spine;
import spine.SkeletonData;
import spine.SkeletonJson;
import spine.Skeleton;
import spine.attachments.AtlasAttachmentLoader;
import spine.support.graphics.TextureAtlas;
import spine.AnimationState;
import spine.AnimationStateData;

class SpineMaster {
    public final skeleton:Skeleton;
    public final animationState:AnimationState;
    
    final _skeletonData:SkeletonData;
    final _loader:SpineTextureLoader;
    final _textureAtlas:TextureAtlas;
    final _atlasAttachmentLoader:AtlasAttachmentLoader;
    final _skeletonJson:SkeletonJson;
    final _spineConfigHandle:SpineConfigHandle;
    final _animationStateData:AnimationStateData;

    public function new(spine:Spine) {
        _loader = new SpineTextureLoader(spine.tile);
		_textureAtlas = new TextureAtlas(spine.atlas, _loader);
        _atlasAttachmentLoader = new AtlasAttachmentLoader(_textureAtlas);
		_skeletonJson = new SkeletonJson(_atlasAttachmentLoader);
		_spineConfigHandle = new SpineConfigHandle(spine.config);
        _skeletonData = _skeletonJson.readSkeletonData(_spineConfigHandle);
        _animationStateData = new AnimationStateData(_skeletonData);
        animationState = new AnimationState(_animationStateData);
        skeleton = new Skeleton(_skeletonData);
        skeleton.updateWorldTransform();
    }

    public function dispose() {
		if (_textureAtlas != null) {
			_textureAtlas.dispose();
		}
	}
    
    /**
		Update spine elements
		@param dt Delta time
	**/
	public function update(dt:Float) {
        animationState.update(dt);
        animationState.apply(skeleton);
		skeleton.updateWorldTransform();
		skeleton.update(dt);
    }
}