package view;

import h2d.col.Bounds;
import pony.geom.IWH;
import pony.time.Tween;

/** One block on its way in: what moves, where it belongs, and how far off the window it starts. */
typedef Drop = {
	target: Object,
	rest: Float,
	offset: Float
}

/**
 * How a screen arrives: its blocks slide in from off the window to where the layout put them, the
 * top group down from above and the bottom group up from below, and `onLand` says when all are in.
 *
 * The waiting matters as much as the movement. A key that ended one screen is often still being
 * pressed, so nothing on the new screen may listen before `onLand`.
 *
 * Nothing here is laid out: blocks stay wherever the XML left them and are only offset and put
 * back. Anything not in a group stays where it is.
 */
@:nullSafety(Strict) final class DropIn implements HasSignal {

	/** Every block is in place. */
	@:auto public var onLand: Signal0;

	/**
	 * The layout everything on the screen is inside. Waited on rather than measured at once: pony
	 * arranges a layout on the frame AFTER it is built, so every block would still be at zero.
	 */
	private final root: IWH;

	/** Read at every drop rather than remembered: the window may have been resized. */
	private final appService: AppService;

	private final above: Array<Object>;
	private final below: Array<Object>;

	/** Eased so most of the distance is covered off-window and the blocks arrive slowing down. */
	private final tween: Tween = new Tween(TweenType.BackSquare, Config.screen_dropTime);

	/** Rebuilt by every drop: a resize moves where a block rests. */
	private final drops: Array<Drop> = [];

	public function new(appService: AppService, screen: Object, above: Array<Object>, below: Array<Object>) {
		// `createUI` adds the XML root as the first child, and on every screen that root is a layout.
		root = cast(screen.getChildAt(0), IWH);
		this.appService = appService;
		this.above = above;
		this.below = below;
		tween.onUpdate << updateHandler;
		tween.onComplete << landHandler;
	}

	/** Puts every block off the box and starts them all in, together. */
	public function play(): Void root.wait(start);

	/**
	 * What `play` is once the layout has settled. The box is `view` and nothing else: the edge a
	 * block clears has to be the same edge that clips it.
	 */
	private function start(): Void {
		final window: Rect<Float> = appService.view;
		// An unfinished drop goes to its end first: what is measured below is where the blocks REST.
		tween.stopOnEnd();
		drops.resize(0);
		// How far each group must go to clear its own edge, measured on the group as a whole so
		// blocks that belong together travel as one.
		final up: Float = box(above).yMax - window.y;
		final down: Float = window.y + window.height - box(below).yMin;
		// Both then travel the longer distance, which is what makes them share one speed: the near
		// group waits out of sight instead of crossing its short gap while the far one is still out.
		final travel: Float = Math.max(up, down);
		slide(above, -travel);
		slide(below, travel);
		// Placed by the reset, so the screen is never seen at rest for the frame before the drop.
		tween.stopOnBegin();
		tween.playForward();
	}

	/** What is left of the tween is how far off the blocks still are. */
	private function updateHandler(value: Float): Void {
		final left: Float = 1 - value;
		for (drop in drops) drop.target.y = drop.rest + drop.offset * left;
	}

	private function landHandler(): Void eLand.dispatch();

	private function slide(group: Array<Object>, offset: Float): Void
		for (target in group) drops.push({ target: target, rest: target.y, offset: offset });

	/** The box a whole group is inside, in the same scene coordinates as `window`. */
	private static function box(group: Array<Object>): Bounds {
		final bounds: Bounds = new Bounds();
		for (target in group) bounds.addBounds(target.getBounds());
		return bounds;
	}

}
