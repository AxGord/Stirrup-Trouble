package view;

import pony.heaps.ui.gui.NodeAnim;

/** Collected coins, shown while a run is in progress. */
@:ui('ui/hud.xml')
final class HudView extends HeapsXmlUi implements DI implements HasListener {

	@:use private var appService: AppService;

	/** The XML parks and paces the coin; all this view decides is when it turns. */
	private final coinNode: NodeAnim;

	public function new() {
		super(appService.scene);
		createUI(appService.app);
		coinNode = cast(coin, NodeAnim);
		resizeHandler(appService.view);
	}

	/** The counter hugs the top left corner of the box the game is drawn in, not of the window. */
	@:listen(appService.onResize) private function resizeHandler(view: Rect<Float>): Void y = view.y;

	public inline function setCoins(value: Int): Void coins.text = '$value';

	/** One turn per coin collected; a burst stacks up and the coin works through it faster. */
	public inline function spin(): Void coinNode.spin();

}
