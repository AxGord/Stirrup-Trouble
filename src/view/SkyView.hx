package view;

/**
 * The sky, drawn as a rectangle over the game column rather than left to the engine's clear colour:
 * that colour also fills the border, and a sky coloured border reads as world instead of edge.
 */
@:nullSafety(Strict) final class SkyView extends Object implements DI implements HasListener {

	@:use private var appService: AppService;

	private final fill: Bitmap = new Bitmap(Tile.fromColor(Config.game_sky));

	public function new() {
		super(appService.scene);
		addChild(fill);
		fill.width = Config.width;
		resizeHandler(appService.view);
	}

	@:listen(appService.onResize) private function resizeHandler(view: Rect<Float>): Void {
		y = view.y;
		fill.height = view.height;
	}

}
