import pony.Config;
import pony.geom.Point;
import pony.geom.Rect;
import pony.heaps.SmartCanvas;

/**
 * What a window of a given shape leaves the game to draw in.
 *
 * Two halves that only meet at runtime: pony fits the scene and reports what is on screen around
 * it, and `AppService` cuts that down to the box the game may fill. Both run here, using the
 * library's own `setStageSize` rather than a copy of its arithmetic.
 *
 * It does NOT cover `pony.js.SmartCanvas`, which needs a DOM and cannot be driven from node.
 */
@:access(AppService)
@:access(pony.heaps.SmartCanvas)
@:nullSafety(Strict) final class FrameTest {

	/** How far off centre the box may land before it counts: float noise, nothing. */
	private static inline final EPSILON: Float = 1e-9;

	/** Window shapes, from the widest the column is asked to survive to the tallest. */
	private static final WINDOWS: Array<Point<Int>> = [
		new Point<Int>(3200, 900),
		new Point<Int>(1900, 420),
		new Point<Int>(2560, 1097),
		new Point<Int>(1280, 720),
		new Point<Int>(1280, 900),
		new Point<Int>(900, 900),
		new Point<Int>(800, 1000),
		new Point<Int>(400, 900)
	];

	public static inline function run(): Void Check.run('frame', box);

	private static function box(): Void {
		for (window in WINDOWS) {
			final stage: Rect<Float> = fit(window);
			final view: Rect<Float> = AppService.frame(stage);
			final at: String = '${window.x}x${window.y}';
			// The one thing a run may not vary: the visible track never depends on the monitor.
			Check.isTrue(view.width == Config.width, '$at: column is ${view.width}, not ${Config.width}');
			Check.isTrue(view.x == 0, '$at: column starts at ${view.x}');
			Check.isTrue(stage.x <= 0, '$at: the window cuts the column at ${stage.x}');
			Check.isTrue(stage.x + stage.width >= Config.width, '$at: the window ends inside the column');
			Check.isTrue(view.height >= Config.minHeight, '$at: box is ${view.height} tall, under the floor');
			Check.isTrue(view.height <= Config.maxHeight, '$at: box is ${view.height} tall, over the ceiling');
			Check.isTrue(view.height == Math.min(stage.height, Config.maxHeight), '$at: box height is not the clamp');
			// What is left over is border, and there is as much of it above as below.
			Check.isTrue(Math.abs((view.y + view.height / 2) - (stage.y + stage.height / 2)) < EPSILON, '$at: box is off centre');
		}
	}

	/** What pony's own fit leaves visible, in scene coordinates, for a window of this size. */
	private static function fit(window: Point<Int>): Rect<Float> {
		final canvas: SmartCanvas = new SmartCanvas(new Point<UInt>(Config.width, Config.minHeight));
		canvas.setSize(window.x, window.y);
		return canvas.dynStage;
	}

}
