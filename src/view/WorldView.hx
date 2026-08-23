package view;

import h2d.Interactive;
import model.Entity;

/**
 * One backdrop layer: its art, its share of the travelled distance, how far below our ground line
 * its own one sits, and whether it hangs from the top of the visible box instead. Only the
 * backdrop hangs; the rest stand on the ground line, `sink` under it.
 */
typedef SkyLayer = {
	asset: Int,
	drift: Float,
	sink: Float,
	hang: Bool,
	scale: Float
}

/**
 * The picture a run is drawn as, and the one thing deciding what is in front of what: backdrop,
 * ground, the track's layer, the horse. It knows how far the world has scrolled and how high the
 * horse is, but not what that means; the controller feeds it and takes its input signals back.
 *
 * Everything with behaviour draws itself. What is left here is the box: the ground line every layer
 * hangs from, the wrapping ground strip, the parallax backdrop and the click sheet.
 */
@:nullSafety(Strict) final class WorldView extends Object implements DI implements HasSignal implements HasListener {

	private static final SKY: Array<SkyLayer> = [
		{
			asset: Assets.SKY_BG,
			drift: Config.game_parallax_bg_drift,
			sink: Config.game_parallax_bg_sink,
			hang: true,
			// The only layer with its own scale: the moon needs a wider period than the rest.
			scale: Config.game_parallax_bg_scale
		},
		{
			asset: Assets.SKY_FAR,
			drift: Config.game_parallax_far_drift,
			sink: Config.game_parallax_far_sink,
			hang: false,
			scale: Config.game_parallax_scale
		},
		{
			asset: Assets.SKY_MOUNTAINS,
			drift: Config.game_parallax_mountains_drift,
			sink: Config.game_parallax_mountains_sink,
			hang: false,
			scale: Config.game_parallax_scale
		},
		{
			asset: Assets.SKY_TREES,
			drift: Config.game_parallax_trees_drift,
			sink: Config.game_parallax_trees_sink,
			hang: false,
			scale: Config.game_parallax_scale
		},
		{
			asset: Assets.SKY_NEAR,
			drift: Config.game_parallax_near_drift,
			sink: Config.game_parallax_near_sink,
			hang: false,
			scale: Config.game_parallax_scale
		}
	];

	@:auto public var onPress: Signal0;
	@:auto public var onRelease: Signal0;

	@:use private var appService: AppService;

	/**
	 * Everything the world is drawn into. Its origin is the visible box's top left corner and
	 * everything below measures from there. Layers deliberately spill past the column edges; the
	 * scene's own mask clips that off, so nothing here has to.
	 */
	private final content: Object = new Object();

	private final horse: HorseView = new HorseView();

	/** Handed the horse, which is what a collected coin flies into. */
	private final track: TrackView;

	private final parallax: Array<ParallaxLayer> = [];

	/**
	 * The birds, in front of the whole backdrop: the mountains reach 450px above the ground line
	 * and the shortest window has 442 of sky, so anything behind them would be invisible there.
	 */
	private final flock: FlockView = new FlockView();

	private final ground: ParallaxLayer;

	/** Click to jump, over the whole visible box. */
	private final touch: Interactive = new Interactive(Config.width, 0);

	public function new() {
		super(appService.scene);
		track = new TrackView(horse);
		// The ground travels the whole distance, so its share is 1.
		ground = new ParallaxLayer(Config.game_tile, 1, Config.game_pixel, groundColumn.bind(appService));
		// After the fields above: null safety forbids reaching for `this` before they are set.
		addChild(content);
		// Before the ground, so the backdrop hanging past the horizon ends up behind it.
		for (layer in SKY) {
			final strip: ParallaxLayer = ParallaxLayer.image(Assets.getTexture(layer.asset), layer.drift, layer.scale);
			content.addChild(strip.root);
			parallax.push(strip);
		}
		content.addChild(flock);
		content.addChild(ground.root);
		// The coins go under the horse, so a collected one disappears behind it.
		content.addChild(track);
		content.addChild(horse);
		addChild(touch);
		touch.onPush = pushHandler;
		touch.onRelease = releaseHandler;
		// Places everything the ground line decides, the horse included.
		resizeHandler(appService.view);
		moveTo(0);
	}

	/**
	 * The window said how tall the world is. Every backdrop layer is hung again from the moved
	 * ground line, and the ground strip is rebuilt because its dirt reaches the bottom edge.
	 */
	@:listen(appService.onResize) private function resizeHandler(view: Rect<Float>): Void {
		content.y = touch.y = view.y;
		touch.height = view.height;
		final groundY: Float = appService.groundY;
		for (index => layer in parallax) layer.setY(layerTop(SKY[index], groundY));
		flock.setSky(groundY);
		ground.setY(groundY);
		ground.rebuild();
		track.setY(groundY);
		horse.setGround(groundY);
	}

	/** A new run. Only the birds need telling; everything else is put on screen by the track. */
	public inline function start(): Void flock.start();

	public inline function spawn(entity: Entity): Void track.spawn(entity);

	public inline function despawn(entity: Entity): Void track.despawn(entity);

	/** A coin has been collected; the track layer takes it out of the run and flies it in. */
	public inline function pick(entity: Entity): Void track.pick(entity);

	/** Scrolls the world to the given travelled distance. */
	public function moveTo(value: Float): Void {
		track.moveTo(value);
		flock.moveTo(value);
		ground.moveTo(value);
		for (layer in parallax) layer.moveTo(value);
	}

	/**
	 * Holds every drawn frame still, or puts them all back. A tumble and a flight are transforms,
	 * so they keep going.
	 */
	public function freeze(value: Bool): Void {
		horse.freeze(value);
		track.freeze(value);
		flock.freeze(value);
	}

	/** Blinks the horse to say the run is over, or brings it back solid. */
	public inline function blink(value: Bool): Void horse.blink(value);

	/** Puts the horse the given height above the ground. */
	public inline function liftTo(value: Float): Void horse.liftTo(value);

	/** Tilts the horse: nose up as it climbs, over onto its back once it trips. */
	public inline function tiltTo(value: Float): Void horse.tiltTo(value);

	/** Carries the horse the given distance past the spot it runs on; a trip throws it forward. */
	public inline function advanceTo(value: Float): Void horse.advanceTo(value);

	/**
	 * One column of the ground strip: the surface tile plus enough dirt to reach the bottom of the
	 * visible box. That count is what a resize changes, and so what a rebuild is for.
	 */
	private static function groundColumn(service: AppService, column: Object): Void {
		final tile: Int = Config.game_tile;
		new Bitmap(Assets.getTexture(Assets.GROUND), column).setScale(Config.game_pixel);
		final fill: Tile = Assets.getTexture(Assets.FILL);
		// The surface tile already covers the first row, hence the -1.
		final rows: Int = Math.ceil((service.view.height - service.groundY) / tile) - 1;
		for (row in 1...rows + 1) {
			final under: Bitmap = new Bitmap(fill, column);
			under.setScale(Config.game_pixel);
			under.y = row * tile;
		}
	}

	/** Where a layer hangs from: the top of the box, or its own height above its sunk ground line. */
	private static function layerTop(layer: SkyLayer, groundY: Float): Float {
		return layer.hang ? 0 : groundY + layer.sink - Assets.getTexture(layer.asset).height * layer.scale;
	}

	private function pushHandler(event: hxd.Event): Void ePress.dispatch();

	private function releaseHandler(event: hxd.Event): Void eRelease.dispatch();

}
