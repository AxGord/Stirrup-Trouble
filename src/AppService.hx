import h2d.Interactive;
import h2d.Mask;
import hxd.Cursor;

/**
 * The running application, the one rectangle every view measures itself against and the one
 * surface a tap lands on. A DI initializer runs in a static context, so the instance is picked
 * up here, not handed in.
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

	/** Every tap and click the window takes, wherever in it the player put it. */
	@:auto public var onPress: Signal0;

	@:auto public var onRelease: Signal0;

	@:auto public var onResize: Signal1<Rect<Float>>;

	/**
	 * Everything the window shows, in the same coordinates as `view`: that box plus the border
	 * around it. Only `touch` asks for it — a tap in the border is still a tap.
	 */
	public var stage(default, null): Rect<Float>;

	/**
	 * The box the game is drawn in: always `Config.width` wide at x 0, between `<minHeight>` and
	 * `<maxHeight>` tall, centred in what the window shows.
	 */
	public var view(default, null): Rect<Float>;

	/** Measured from the TOP of `view`. */
	public var groundY(get, never): Float;

	/** Where a `<minHeight>`-tall screen belongs inside `view`. */
	public var screenY(get, never): Float;

	/**
	 * The one thing a tap lands on, covering the whole window and not only `view`: a finger covers
	 * the picture it is meant to be watching, so the border has to take the tap too. It hangs
	 * beside `scene` rather than in it — `Mask` clips an `Interactive` to the drawn area — and
	 * under it, so a button is still asked first.
	 */
	private final touch: Interactive = new Interactive(0, 0);

	public function new() {
		final app: Null<HeapsApp> = HeapsApp.instance;
		if (app == null) throw 'Application not created';
		this.app = app;
		// First in, so everything put on top of it is asked before it is.
		app.s2d.addChild(touch);
		scene = new Mask(Config.width, 0, app.s2d);
		// Read, not waited for: the canvas sized itself at scene set, the signal only carries changes.
		stage = app.canvas.dynStage;
		view = frame(stage);
		place();
		// After the fields above: null safety forbids reaching for `this` before they are set. The
		// cursor stays an arrow because the sheet is the whole window, which is not a button.
		touch.cursor = Cursor.Default;
		touch.onPush = pushHandler;
		touch.onRelease = releaseHandler;
		app.canvas.onDynStageResize << resizeHandler;
	}

	private inline function get_groundY(): Float return view.height * GROUND_RATIO;

	private inline function get_screenY(): Float return view.y + (view.height - Config.minHeight) / 2;

	private function resizeHandler(value: Rect<Float>): Void {
		stage = value;
		view = frame(stage);
		place();
		eResize.dispatch(view);
	}

	private inline function place(): Void {
		scene.y = scene.scrollY = view.y;
		scene.height = Std.int(view.height);
		touch.setPosition(stage.x, stage.y);
		touch.width = stage.width;
		touch.height = stage.height;
	}

	private function pushHandler(event: hxd.Event): Void ePress.dispatch();

	private function releaseHandler(event: hxd.Event): Void eRelease.dispatch();

	/** Width is the invariant, so the visible track never varies; height is free between the bounds. */
	private static function frame(stage: Rect<Float>): Rect<Float> {
		final height: Float = Math.min(stage.height, Config.maxHeight);
		return new Rect<Float>(0, stage.y + (stage.height - height) / 2, Config.width, height);
	}

}
