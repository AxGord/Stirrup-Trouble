package model;

/** What the horse is doing right now; see the `@:listen` conditions below. */
enum abstract Phase(Int) {

	final Idle;
	final Ground;
	final Air;

	/** Tumbling after a trip: the same fall as `Air`, but spinning and out of the player's hands. */
	final Fall;

}

/**
 * The horse. It runs on its own, the player only controls the jump.
 *
 * `phase` drives the subscriptions themselves, so a handler exists only while its phase is
 * current: standing on the ground IS listening for a press.
 */
@:nullSafety(Strict) final class HorseModel implements HasSignal implements HasListener {

	@:auto public var onPress: Signal0;
	@:auto public var onRelease: Signal0;

	/** The tumble is done; the horse lies where the flip dropped it. */
	@:auto public var onSettle: Signal0;

	@:auto public var onJump: Signal0;

	/** A jump was let go of on the way up, so it has been cut short. */
	@:auto public var onCut: Signal0;

	/** Back on the ground out of a jump. A trip ends on `onSettle` instead. */
	@:auto public var onLand: Signal0;

	/** How far the horse is above the ground. */
	@:bindable public var height: Float = 0;

	/** Tilt from upright in radians, nose down positive. */
	@:bindable public var angle: Float = 0;

	/** How far ahead of its running position a trip has thrown the horse. */
	@:bindable public var advance: Float = 0;

	/** Drives every subscription below: each handler names the phase it is awake in. */
	@:bindable('private') private var phase: Phase = Phase.Idle;

	private var speedY: Float = 0;
	private var speedX: Float = 0;

	/** Jump input; where it comes from is the controller's business. */
	public function press(): Void ePress.dispatch();

	public function release(): Void eRelease.dispatch();

	public function start(): Void {
		height = 0;
		speedY = 0;
		speedX = 0;
		angle = 0;
		advance = 0;
		phase = Phase.Ground;
	}

	public function stop(): Void phase = Phase.Idle;

	/**
	 * Trips over what it just hit: thrown into a hop and spun, so the flip lands it on its back a
	 * fence or so further on. The horse is told only that it hit something, and at what speed.
	 */
	public function trip(speed: Float): Void {
		speedY = Config.game_horse_tripImpulse;
		// It was moving when it hit, so it keeps going: a tumble on the spot reads as the world stopping.
		speedX = speed * Config.game_horse_tripCarry;
		phase = Phase.Fall;
	}

	@:listen(onPress, phase == Phase.Ground) private function jump(): Void {
		speedY = Config.game_horse_jumpImpulse;
		phase = Phase.Air;
		eJump.dispatch();
	}

	@:listenOnce(onRelease, phase == Phase.Air) private function cut(): Void {
		// Only a climb can be cut: past the top the key has nothing left to give away.
		if (speedY > 0) {
			speedY *= Config.game_horse_jumpCut;
			eCut.dispatch();
		}
	}

	// Ahead of everything else on the tick: the track measures collisions against the height set here.
	@:listen(DeltaTime.update, phase == Phase.Air, priority = -10) private function fly(dt: DT): Void {
		final landed: Bool = fall(dt);
		// Only gravity acts, so the ratio stays inside -1..1 on its own. Landing zeroes it with speedY.
		angle = -Config.game_horse_tilt * speedY / Config.game_horse_jumpImpulse;
		if (!landed) return;
		phase = Phase.Ground;
		eLand.dispatch();
	}

	// No priority: the track has already stopped, so nothing is measured against this.
	@:listen(DeltaTime.update, phase == Phase.Fall) private function tumble(dt: DT): Void {
		advance += speedX * dt;
		if (!fall(dt)) {
			angle += Config.game_horse_tripSpin * dt;
			return;
		}
		// Settles onto whichever side the flip had reached, never mid-roll.
		angle = Math.round(angle / Math.PI) * Math.PI;
		phase = Phase.Idle;
		eSettle.dispatch();
	}

	/** Integrates one frame of falling and returns true on the frame that reaches the ground. */
	private inline function fall(dt: DT): Bool {
		speedY -= Config.game_gravity * dt;
		final next: Float = height + speedY * dt;
		if (next > 0) {
			height = next;
			return false;
		}
		height = 0;
		speedY = 0;
		return true;
	}

}
