package view;

/**
 * The horse, the only thing on screen not placed by the track. Its origin is the middle of the
 * collision box, so mirroring and rotation happen around the horse and the art hangs off it by
 * its own offsets.
 *
 * Where it sits is two numbers that move independently: the ground line, set by the window, and
 * the height above it, set by the model. Both are kept so either can be written alone.
 */
@:nullSafety(Strict) final class HorseView extends Object implements HasSignal implements HasListener {

	private final anim: Anim = new Anim(Assets.animation(Assets.HORSE), Config.game_horse_fps);

	/** Set once the horse has come to rest and only blinks. */
	@:bindable('private') private var blinking: Bool = false;

	private var blinkTime: Float = 0;

	/** The ground line and the height above it; see `place`. */
	private var groundY: Float = 0;

	private var lift: Float = 0;

	public function new() {
		super();
		addChild(anim);
		anim.setScale(Config.game_pixel);
		anim.x = -(Config.game_horse_artLeft * Config.game_pixel + Config.game_horse_width / 2);
		anim.y = Config.game_horse_height / 2 - Config.game_horse_artBottom * Config.game_pixel;
		// The sheet faces left and the run goes right. Around the box centre this costs no offset.
		scaleX = -1;
		advanceTo(0);
	}

	/** The ground line moved, so the horse stands somewhere else at the same height. */
	public inline function setGround(value: Float): Void {
		groundY = value;
		place();
	}

	/** Puts the horse the given height above the ground. */
	public inline function liftTo(value: Float): Void {
		lift = value;
		place();
	}

	/** Tilts the horse: nose up as it climbs, over onto its back once it trips. */
	public inline function tiltTo(value: Float): Void rotation = value;

	/** Carries the horse the given distance past the spot it runs on; a trip throws it forward. */
	public inline function advanceTo(value: Float): Void {
		x = Config.game_horse_x + Config.game_horse_width / 2 + value;
	}

	/** Holds the stride the horse tripped on. The tumble is a transform, so it keeps going. */
	public inline function freeze(value: Bool): Void anim.pause = value;

	/** Blinks the horse to say the run is over, or brings it back solid. */
	public function blink(value: Bool): Void {
		blinking = value;
		blinkTime = 0;
		if (!value) anim.alpha = 1;
	}

	@:listen(DeltaTime.update, blinking) private function blinkHandler(dt: DT): Void {
		blinkTime += dt;
		final period: Float = Config.game_over_blinkPeriod;
		anim.alpha = blinkTime % period < period / 2 ? 1 : Config.game_over_blinkAlpha;
	}

	private inline function place(): Void y = groundY - lift - Config.game_horse_height / 2;

}
