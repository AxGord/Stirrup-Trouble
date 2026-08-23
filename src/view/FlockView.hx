package view;

/**
 * The birds, which is the whole of what the sky does. The band a bird may be put in starts above
 * everything the horse can reach, so there is no collision to test and no model to tell.
 *
 * That ceiling is a constant, not a tuning: only the track speeds up, so a jump reaches the same
 * height throughout. `CEILING` derives it, and BirdTest measures a real jump against it.
 *
 * There are exactly two birds and a flight uses one or both. The clock is the travelled distance,
 * which is what stops a flight with the rest of the picture; `start` exists because a new run
 * rewinds that clock past where the next flight is waiting.
 */
@:nullSafety(Strict) final class FlockView extends Object {

	/** How high the horse ever gets: the apex of a full jump, plus its own box on top of it. */
	private static final CEILING: Float = Config.game_horse_jumpImpulse * Config.game_horse_jumpImpulse / (2 * Config.game_gravity)
		+ Config.game_horse_height;

	/** The drawn bird's own height, which is what has to fit under the top of the visible box. */
	private static final INK: Float = (Config.game_bird_artBottom - Config.game_bird_artTop) * Config.game_bird_scale;

	/** The three species' frames, taken once: `getAnim` builds a fresh tile list on every call. */
	private final species: Array<Array<Tile>> = [
		Assets.animation(Assets.BIRD_BLACK),
		Assets.animation(Assets.BIRD_EAGLE),
		Assets.animation(Assets.BIRD_SPARROW)
	];

	private final birds: Array<BirdView> = [new BirdView(), new BirdView()];

	/** The ground line every bird is placed above; the window is free to move it. */
	private var groundY: Float = 0;

	/** The travelled distance the next flight is due at; out of reach until a run sets it. */
	private var nextFlight: Float = Math.POSITIVE_INFINITY;

	public function new() {
		super();
		for (bird in birds) addChild(bird);
	}

	/**
	 * The window moved the ground line, so the band moved with it. A bird already in the air keeps
	 * its height unless the band has shrunk past it, rather than jogging on every resize.
	 */
	public function setSky(value: Float): Void {
		groundY = value;
		final range: Point<Float> = band(value);
		for (bird in birds) if (bird.flying) bird.place(Math.min(range.y, bird.lift), value);
	}

	/** A new run: nothing left over from the last one, and a first flight drawn afresh. */
	public function start(): Void {
		for (bird in birds) bird.retire();
		nextFlight = gap();
	}

	/** Steps whatever is in the air, retires what has left, and starts a flight when one is due. */
	public function moveTo(distance: Float): Void {
		for (bird in birds) if (bird.flying && !bird.moveTo(distance)) bird.retire();
		if (distance < nextFlight) return;
		nextFlight = distance + gap();
		// Never fires at the configured gaps, but a flight over one in the air would be a lone bird.
		for (bird in birds) if (bird.flying) return;
		launch(distance);
	}

	/** Holds every wingbeat still; a crossing is measured in distance and stops on its own. */
	public function freeze(value: Bool): Void for (bird in birds) bird.freeze(value);

	/**
	 * One flight: a species, a direction, a height and one or two birds at it. Both of a pair
	 * share the species and the drift, so they hold their formation across the column.
	 */
	private function launch(distance: Float): Void {
		final frames: Array<Tile> = species[Std.random(species.length)];
		final meet: Bool = Std.random(Config.game_bird_meet_limit) < Config.game_bird_meet_chance;
		final drift: Float = meet
			? span(Config.game_bird_meet_min, Config.game_bird_meet_max)
			: span(Config.game_bird_pass_min, Config.game_bird_pass_max);
		final range: Point<Float> = band(groundY);
		final lift: Float = span(range.x, range.y);
		final pair: Bool = Std.random(Config.game_bird_pairLimit) < Config.game_bird_pairChance;
		for (index in 0...(pair ? birds.length : 1)) {
			final bird: BirdView = birds[index];
			bird.show(frames, !meet);
			bird.place(Math.min(range.y, lift + index * Config.game_bird_pairRise), groundY);
			bird.launch(distance, drift, index * Config.game_bird_pairStep);
		}
	}

	/**
	 * How high above the ground line a bird's lowest pixel may be put: clear of the horse at one
	 * end, inside the visible box at the other. `Math.max` keeps a squeezed band empty, not inverted.
	 */
	private static function band(groundY: Float): Point<Float> {
		final low: Float = CEILING + Config.game_bird_clearance;
		return new Point<Float>(low, Math.max(low, groundY - INK));
	}

	private static inline function gap(): Float {
		return Config.game_bird_minGap + Std.random(Config.game_bird_maxGap - Config.game_bird_minGap);
	}

	private static inline function span(from: Float, to: Float): Float return from + Math.random() * (to - from);

}
