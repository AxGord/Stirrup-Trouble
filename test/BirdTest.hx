import pony.Config;
import pony.geom.Point;
import view.FlockView;

/**
 * Whether the sky the birds are put in is out of the horse's way.
 *
 * A bird carries no collision, which is safe only while two things hold: the band starts above
 * everything a jump reaches, and the shortest allowed window has not squeezed it shut. Neither
 * number is restated here; the apex comes off a real `HorseModel` and the band out of `FlockView`.
 */
@:access(AppService)
@:access(view.FlockView)
@:nullSafety(Strict) final class BirdTest {

	/** How finely the window heights between the two bounds are walked. */
	private static inline final STEP: Float = 10;

	public static function run(): Void {
		Check.run('a bird is drawn above everything the horse can reach', () -> {
			final band: Point<Float> = FlockView.band(groundY(Config.minHeight));
			final reach: Float = JumpTest.apex() + Config.game_horse_height;
			Check.isTrue(band.x > reach, 'birds start ${band.x} above the ground, the horse reaches $reach');
		});

		Check.run('the band a bird is put in is never shut', () -> {
			var height: Float = Config.minHeight;
			while (height <= Config.maxHeight) {
				final band: Point<Float> = FlockView.band(groundY(height));
				Check.isTrue(band.y > band.x, 'a ${height}px box leaves only ${band.x}..${band.y}');
				height += STEP;
			}
		});
	}

	/** Where the ground line falls in a box of the given height, at the share `AppService` keeps. */
	private static inline function groundY(height: Float): Float return height * AppService.GROUND_RATIO;

}
