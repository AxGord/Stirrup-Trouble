import sys.FileSystem;
import sys.io.File;

using StringTools;

/**
 * Whether the atlas the build produced holds every region the game asks for.
 *
 * `hxd.res.Atlas.get` answers a missing name with `null` and heaps draws a magenta placeholder, so
 * a moved or mistyped region costs a debugging session instead of failing the build. This case is
 * that missing failure. It reads the built atlas, so `pony prepare` has to have run.
 *
 * Names come from `Assets` through the accessors `HasAssetBuilder` generates, which is the list
 * the game addresses at runtime.
 *
 * The `ui/` regions are NOT covered: they are `name` attributes in the UI markup, and one of them
 * carries GUI parameters whose parser is private to the GUI layer. `coin/gold` itself is checked
 * through `Assets`.
 */
@:nullSafety(Strict) final class AtlasTest {

	private static inline final DIR: String = 'bin/assets/';

	public static inline function run(): Void Check.run('atlas', regions);

	private static inline function isName(line: String): Bool {
		return line != '' && !line.startsWith(' ') && line.indexOf(':') == -1;
	}

	@:access(Assets) private static function regions(): Void {
		final atlases: Map<String, Array<String>> = [];
		for (asset in 0...Assets.ASSETS_LIST.length) {
			final name: Null<String> = Assets.assetName(asset);
			// A null name is an asset addressed as a whole file rather than as a region.
			if (name == null) continue;
			final file: String = Assets.assetValue(asset);
			var names: Null<Array<String>> = atlases[file];
			if (names == null) {
				names = read(DIR + file);
				atlases[file] = names;
			}
			Check.isTrue(names.contains(name), '$file has no region "$name"');
		}
	}

	/**
	 * Region names of a libgdx atlas: an unindented line followed by indented properties, which is
	 * what separates it from the `key: value` header lines.
	 */
	private static function read(path: String): Array<String> {
		if (!FileSystem.exists(path)) {
			Check.isTrue(false, 'no $path, run `pony prepare` first');
			return [];
		}
		final lines: Array<String> = [for (line in File.getContent(path).split('\n')) line.rtrim()];
		return [
			for (i in 0...lines.length - 1) if (isName(lines[i]) && lines[i + 1].startsWith(' ')) lines[i]
		];
	}

}
