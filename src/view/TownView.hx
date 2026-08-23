package view;

/**
 * The title screen's backdrop: the GothicVania town as a still frame with the wagon and the house
 * in it. Only the sky drifts. It stands on the world's own ground line.
 *
 * The pack composes its layers 288 rows tall with the ground surface on 249, and `<town>`'s `sink`
 * is that last 39: hang a layer's bottom row there and its buildings meet the ground as the pack
 * intends. The props stand on the line itself.
 */
@:nullSafety(Strict) final class TownView extends Object implements DI implements HasSignal implements HasListener {

	/** The pack's ground tile keeps its surface nine rows down, so the tile hangs that far up. */
	private static inline final GROUND_SURFACE: Int = 9;

	/**
	 * What stands on the ground line, back to front, and where across the column. Composed rather
	 * than tiled, so the props clear each other and the menu's column down the middle.
	 */
	private static final PROPS: Array<{ asset: Int, x: Float }> = [
		{ asset: Assets.TOWN_HOUSE, x: 500 },
		{ asset: Assets.TOWN_WELL, x: 1150 },
		{ asset: Assets.TOWN_LAMP, x: 420 },
		{ asset: Assets.TOWN_WAGON, x: 100 }
	];

	@:use private var appService: AppService;

	/** Behind everything, in the sky art's own top row tone, so a taller box continues it. */
	private final above: Bitmap = new Bitmap(Tile.fromColor(Config.game_town_sky));

	/** Below the ground tile the art is one flat tone, so a colour fills the rest of the box. */
	private final dirt: Bitmap = new Bitmap(Tile.fromColor(Config.game_town_dirt));

	/** Over everything, so the menu reads on top of it. */
	private final dim: Bitmap = new Bitmap(Tile.fromColor(0));

	private final sky: ParallaxLayer;
	private final city: ParallaxLayer;
	private final ground: ParallaxLayer;

	/** Everything standing on the ground line at its own offset; a resize moves only this. */
	private final town: Object = new Object();

	/** True only while the title screen is up; otherwise the pan is a wasted frame. */
	@:bindable('private') private var panning: Bool = false;

	private var distance: Float = 0;

	public function new() {
		super(appService.scene);
		final scale: Int = Config.game_town_scale;
		// Only the sky drifts, so only it takes a share of the distance; the rest just tiles.
		sky = ParallaxLayer.image(Assets.getTexture(Assets.TOWN_SKY), 1, scale);
		city = ParallaxLayer.image(Assets.getTexture(Assets.TOWN_CITY), 0, scale);
		ground = ParallaxLayer.image(Assets.getTexture(Assets.TOWN_GROUND), 0, scale);
		// After the fields above: null safety forbids reaching for `this` before they are set.
		addChild(above);
		addChild(town);
		addChild(dim);
		above.width = dirt.width = dim.width = Config.width;
		dim.alpha = Config.game_town_dim;
		// Back to front, props last. Every y below is an offset from the ground line `town` carries.
		final sink: Float = Config.game_town_sink * scale;
		final tile: Tile = Assets.getTexture(Assets.TOWN_GROUND);
		town.addChild(sky.root);
		town.addChild(city.root);
		town.addChild(ground.root);
		town.addChild(dirt);
		sky.setY(sink - Assets.getTexture(Assets.TOWN_SKY).height * scale);
		city.setY(sink - Assets.getTexture(Assets.TOWN_CITY).height * scale);
		ground.setY(-GROUND_SURFACE * scale);
		dirt.y = (tile.height - GROUND_SURFACE) * scale;
		for (prop in PROPS) {
			final art: Tile = Assets.getTexture(prop.asset);
			final bitmap: Bitmap = new Bitmap(art, town);
			bitmap.setScale(scale);
			bitmap.x = prop.x;
			bitmap.y = -art.height * scale;
		}
		resizeHandler(appService.view);
	}

	/** Opens with the menu; the drift and the frame it costs belong to the screen being up. */
	public function show(): Void visible = panning = true;

	public function hide(): Void visible = panning = false;

	/**
	 * The window decides the box and so where the ground line falls. Every layer sits at its own
	 * offset from that line, so moving `town` places all of them; only the flat tones are measured.
	 */
	@:listen(appService.onResize) private function resizeHandler(view: Rect<Float>): Void {
		y = view.y;
		above.height = dim.height = view.height;
		town.y = appService.groundY;
		final rest: Float = view.height - town.y - dirt.y;
		dirt.height = rest;
		// A short box can end inside the ground tile, and a negative height draws upside down.
		dirt.visible = rest > 0;
	}

	@:listen(DeltaTime.update, panning) private function driftHandler(dt: DT): Void {
		distance += dt * Config.game_town_speed;
		sky.moveTo(distance);
	}

}
