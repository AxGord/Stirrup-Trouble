import sys.FileSystem;

/**
 * Whether the build wrote every file the game loads whole.
 *
 * `AtlasTest` covers regions inside the atlas; this covers assets with no `@:asset` name, which is
 * what `Assets` says for a file that is not packed. A missing one costs nothing at build time and
 * throws in the browser on the frame that first wants the sound.
 *
 * Names come from `Assets` through the generated accessors, and it reads what the build produced,
 * so `pony prepare` has to have run.
 */
@:nullSafety(Strict) final class AudioTest {

	private static inline final DIR: String = 'bin/assets/';

	public static inline function run(): Void Check.run('audio', files);

	@:access(Assets) private static function files(): Void {
		for (asset in 0...Assets.ASSETS_LIST.length) {
			// A name means a region inside a file, which is AtlasTest's question, not this one's.
			if (Assets.assetName(asset) != null) continue;
			final path: String = DIR + Assets.assetValue(asset);
			Check.isTrue(FileSystem.exists(path), 'no $path, run `pony prepare` first');
		}
	}

}
