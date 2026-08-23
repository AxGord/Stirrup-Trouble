/**
 * The whole harness. Failures are collected rather than thrown, so one broken invariant does not
 * hide the others, and the process exits non-zero if anything failed. Not munit: one assert is all
 * these cases need.
 *
 * A case that sweeps a range fails once per step, so only the first few of each are printed and
 * the rest are counted.
 */
@:nullSafety(Strict) final class Check {

	private static inline final SHOWN: Int = 5;

	private static final lines: Array<String> = [];
	private static final counts: Map<String, Int> = [];
	private static final order: Array<String> = [];

	private static var current: String = '';

	public static function run(name: String, body: Void -> Void): Void {
		current = name;
		order.push(name);
		counts[name] = 0;
		body();
	}

	public static function isTrue(value: Bool, why: String, ?pos: haxe.PosInfos): Void {
		if (value) return;
		final seen: Null<Int> = counts[current];
		final count: Int = (seen == null ? 0 : seen) + 1;
		counts[current] = count;
		if (count > SHOWN) return;
		// The compiler always fills `pos` in at the call site; strict null safety cannot see that.
		final where: String = pos == null ? '?' : '${pos.fileName}:${pos.lineNumber}';
		lines.push('  $current: $why ($where)');
	}

	/** Prints what failed and returns the exit code the process should leave with. */
	public static function report(): Int {
		var total: Int = 0;
		for (name in order) total += count(name);
		if (total == 0) {
			Sys.println('OK');
			return 0;
		}
		Sys.println('$total failure(s):');
		for (line in lines) Sys.println(line);
		for (name in order) {
			final hidden: Int = count(name) - SHOWN;
			if (hidden > 0) Sys.println('  $name: and $hidden more');
		}
		return 1;
	}

	private static inline function count(name: String): Int {
		final value: Null<Int> = counts[name];
		return value == null ? 0 : value;
	}

}
