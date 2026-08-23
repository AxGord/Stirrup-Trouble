import model.Entity;
import model.Entity.EntityKind;
import model.HorseModel;
import pony.Config;
import pony.geom.Point;
import pony.time.DeltaTime;

/**
 * Whether the track the spawner can produce is actually playable.
 *
 * Nothing here restates the physics or the collision rule: the jump curve is sampled off a real
 * `HorseModel` and the danger window is measured by asking the real `Entity.hits`. Only the search
 * over takeoff positions is the test's own: a jump clears a fence exactly when the stretch of it
 * that is high enough covers the stretch where the boxes overlap.
 */
@:nullSafety(Strict) final class JumpTest {

	/** Fine enough that the sampled apex is within a pixel of the real one. */
	private static inline final STEP: Float = 1 / 240;

	/** How far into a run the invariants have to hold; the speed keeps growing past it. */
	private static inline final RUN: Float = 180;

	private static inline final SPEED_STEP: Float = 10;

	/** How finely `dangerWindow` walks the collision predicate. */
	private static inline final STAND: Float = 1;

	private static final FENCE: Point<Float> = new Point<Float>(Config.game_tile, Config.game_tile);

	public static function run(): Void {
		final full: Array<Float> = profile(false);
		final overlap: Float = dangerWindow();
		final air: Float = (full.length - 1) * STEP;
		final high: Point<Int> = highRange(full);

		Check.run('a full jump clears a lone fence at every speed of the run', () -> {
			var speed: Float = Config.game_speed;
			while (speed <= Config.game_speed + Config.game_speedGrow * RUN) {
				final covered: Float = (high.y - high.x) * STEP * speed;
				Check.isTrue(covered >= overlap, 'at $speed px/s the jump is high for $covered px, needs $overlap');
				speed += SPEED_STEP;
			}
		});

		Check.run('every pair of fences the spawner can put down is passable', () -> {
			var speed: Float = Config.game_speed;
			while (speed <= Config.game_speed + Config.game_speedGrow * RUN) {
				for (gap in Config.game_spawn_minGap ... Config.game_spawn_maxGap) {
					// Land between them and jump again, or clear both in one; either will do.
					final apart: Bool = gap >= overlap + speed * (air - (high.y - high.x) * STEP);
					final together: Bool = (high.y - high.x) * STEP * speed >= gap + overlap;
					Check.isTrue(apart || together, 'gap $gap at $speed px/s is passable neither way');
				}
				speed += SPEED_STEP;
			}
		});

		Check.run('a jump let go of at once cannot clear a fence', () -> {
			final top: Float = highest(profile(true));
			Check.isTrue(top < Config.game_tile, 'a cut jump reaches $top, over the ${Config.game_tile} fence');
		});

		Check.run('the top coin row is still reachable', () -> {
			final top: Float = highest(full);
			final coin: Entity = new Entity(
				EntityKind.Gold, Config.game_horse_x, Config.game_coin_goldY,
				new Point<Float>(Config.game_coin_size, Config.game_coin_size)
			);
			Check.isTrue(
				coin.hits(Config.game_horse_x, top, Config.game_horse_width, Config.game_horse_height),
				'the apex of $top misses a gold coin at ${Config.game_coin_goldY}'
			);
		});
	}

	/** The highest a full jump gets, sampled off a real horse. Public because BirdTest needs it. */
	public static function apex(): Float return highest(profile(false));

	/** Heights one real jump passes through, sampled every STEP until the horse is back down. */
	private static function profile(cut: Bool): Array<Float> {
		final horse: HorseModel = new HorseModel();
		horse.start();
		horse.press();
		if (cut) horse.release();
		final out: Array<Float> = [horse.height];
		while (true) {
			DeltaTime.fixedValue = STEP;
			DeltaTime.fixedDispatch();
			out.push(horse.height);
			if (horse.height <= 0) return out;
		}
	}

	private static function highest(heights: Array<Float>): Float {
		var out: Float = 0;
		for (height in heights) if (height > out) out = height;
		return out;
	}

	/** First and last sample of the jump that clear the fence, asked of `Entity.hits` itself. */
	private static function highRange(heights: Array<Float>): Point<Int> {
		final fence: Entity = new Entity(EntityKind.Fence, 0, 0, FENCE);
		var first: Int = -1;
		var last: Int = -1;
		for (i => height in heights) if (!fence.hits(0, height, Config.game_horse_width, Config.game_horse_height)) {
			if (first == -1) first = i;
			last = i;
		}
		return new Point<Int>(first, last);
	}

	/**
	 * How far the horse travels while its box still overlaps a fence, by walking the real
	 * predicate. The bounds are open, so the last miss on each side belongs to the window too,
	 * hence the extra step at both ends.
	 */
	private static function dangerWindow(): Float {
		final fence: Entity = new Entity(EntityKind.Fence, 0, 0, FENCE);
		var from: Float = 0;
		var to: Float = 0;
		var found: Bool = false;
		var distance: Float = -Config.width;
		while (distance < Config.width) {
			if (fence.hits(distance, 0, Config.game_horse_width, Config.game_horse_height)) {
				if (!found) from = distance;
				found = true;
				to = distance;
			}
			distance += STAND;
		}
		return to - from + 2 * STAND;
	}

}
