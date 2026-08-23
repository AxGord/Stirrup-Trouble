import h2d.Mask;

/**
 * The running application and the one rectangle every view measures itself against. A DI
 * initializer runs in a static context, so the instance is picked up here, not handed in.
 */
@:nullSafety(Strict) final class AppService implements HasSignal {

	/** Share of the box height above the ground line, taken from the 16:9 reference. */
	private static final GROUND_RATIO: Float = Config.game_groundY / Config.height;

	public final app: HeapsApp;

	/**
	 * Everything is drawn into this, clipped to `view` so no view has to mask itself. `Mask` clips
	 * by its own `y` and offsets content by minus `scrollY`, so setting both equal leaves children
	 * at plain scene coordinates.
	 */
	public final scene: Mask;

	@:auto public var onResize: Signal1<Rect<Float>>;

	/**
	 * The box the game is drawn in: always `Config.width` wide at x 0, between `<minHeight>` and
	 * `<maxHeight>` tall, centred in what the window shows.
	 */
	public var view(default, null): Rect<Float>;

	/** Measured from the TOP of `view`. */
	public var groundY(get, never): Float;

	/** Where a `<minHeight>`-tall screen belongs inside `view`. */
	public var screenY(get, never): Float;

	public function new() {
		final app: Null<HeapsApp> = HeapsApp.instance;
		if (app == null) throw 'Application not created';
		this.app = app;
		scene = new Mask(Config.width, 0, app.s2d);
		// Read, not waited for: the canvas sized itself at scene set, the signal only carries changes.
		view = frame(app.canvas.dynStage);
		place();
		app.canvas.onDynStageResize << resizeHandler;
	}

	private inline function get_groundY(): Float return view.height * GROUND_RATIO;

	private inline function get_screenY(): Float return view.y + (view.height - Config.minHeight) / 2;

	private function resizeHandler(value: Rect<Float>): Void {
		view = frame(value);
		place();
		eResize.dispatch(view);
	}

	private inline function place(): Void {
		scene.y = scene.scrollY = view.y;
		scene.height = Std.int(view.height);
	}

	/** Width is the invariant, so the visible track never varies; height is free between the bounds. */
	private static function frame(stage: Rect<Float>): Rect<Float> {
		final height: Float = Math.min(stage.height, Config.maxHeight);
		return new Rect<Float>(0, stage.y + (stage.height - height) / 2, Config.width, height);
	}

}
