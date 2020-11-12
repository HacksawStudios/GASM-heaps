package gasm.heaps.spine;

import gasm.heaps.data.Spine;
import spine.AnimationState;
import spine.AnimationStateData;
import spine.Skeleton;
import spine.SkeletonData;
import spine.SkeletonJson;
import spine.attachments.AtlasAttachmentLoader;
import spine.support.graphics.TextureAtlas;

// TODO: Naming?
class SpineMaster {
	public final skeleton:Skeleton;
	public final animationState:AnimationState;

	private final textureAtlas:TextureAtlas;

	public function new(spine:Spine) {
		final loader = new SpineTextureLoader(spine.tile);
		textureAtlas = new TextureAtlas(spine.atlas, loader);
		final atlasAttachmentLoader = new AtlasAttachmentLoader(textureAtlas);
		final skeletonJson = new SkeletonJson(atlasAttachmentLoader);
		final spineConfigHandle = new SpineConfigHandle(spine.config);
		final skeletonData = skeletonJson.readSkeletonData(spineConfigHandle);
		final animationStateData = new AnimationStateData(skeletonData);
		animationState = new AnimationState(animationStateData);
		skeleton = new Skeleton(skeletonData);
		skeleton.updateWorldTransform();
	}

	public function dispose() {
		if (textureAtlas != null) {
			textureAtlas.dispose();
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
