package controller;

import model.Entity;
import model.Entity.EntityKind;
import model.HorseModel;
import model.ProfileModel;
import model.TrackModel;
import view.HudView;
import view.OverView;
import view.WorldView;

/** Models never touch a view and views never read a model; these handlers are the whole wiring. */
@:nullSafety(Strict) final class GameController implements DI implements HasSignal implements HasListener {

	@:auto public var onOver: Signal1<Int>;
	@:auto public var onContinue: Signal0;

	/** The window is where a jump comes from, wherever in it the player taps. */
	@:use private var appService: AppService;

	/** Only to say what the finished run came to; the record itself is filed above. */
	@:use private var profile: ProfileModel;

	@:use private var audio: AudioService;

	@:own private var horse: HorseModel = new HorseModel();
	@:own private var track: TrackModel = new TrackModel();
	@:own private var world: WorldView = new WorldView();
	@:own private var hud: HudView = new HudView();
	@:own private var over: OverView = new OverView();

	public function new() setVisible(false);

	public function start(): Void {
		audio.music(Assets.MUSIC_RACE);
		setVisible(true);
		hud.setCoins(0);
		world.start();
		horse.start();
		track.start();
	}

	@:listen(appService.onPress)
	@:listen(Keyboard.down - Key.Space)
	@:listen(Keyboard.down - Key.Up)
	@:listen(Keyboard.down - Key.W)
	private function pressHandler(): Void horse.press();

	@:listen(appService.onRelease)
	@:listen(Keyboard.up - Key.Space)
	@:listen(Keyboard.up - Key.Up)
	@:listen(Keyboard.up - Key.W)
	private function releaseHandler(): Void horse.release();

	@:listen(track.onSpawn) private function spawnHandler(entity: Entity): Void world.spawn(entity);

	@:listen(track.onRemove) private function removeHandler(entity: Entity): Void world.despawn(entity);

	@:listen(track.changeDistance) private function distanceHandler(value: Float, previous: Float): Void world.moveTo(value);

	@:listen(horse.changeHeight) private function heightHandler(value: Float, previous: Float): Void world.liftTo(value);

	@:listen(horse.changeAngle) private function angleHandler(value: Float, previous: Float): Void world.tiltTo(value);

	@:listen(horse.changeAdvance) private function advanceHandler(value: Float, previous: Float): Void world.advanceTo(value);

	@:listen(horse.onJump) private function jumpHandler(): Void audio.jump();

	@:listen(horse.onCut) private function cutHandler(): Void audio.cutJump();

	@:listen(horse.onLand) private function landHandler(): Void audio.sfx(Assets.SFX_JUMP_END);

	@:listen(track.changeCoins) private function coinsHandler(value: Int, previous: Int): Void {
		hud.setCoins(value);
		hud.spin();
	}

	@:listen(track.onPick) private function pickHandler(entity: Entity): Void {
		world.pick(entity);
		final asset: Int = switch entity.kind {
			case EntityKind.Copper: Assets.SFX_COIN_COPPER;
			case EntityKind.Silver: Assets.SFX_COIN_SILVER;
			case EntityKind.Gold: Assets.SFX_COIN_GOLD;
			case EntityKind.Fence: throw 'Fence is not picked up';
		}
		audio.sfx(asset, Config.game_audio_coinSpread);
	}

	/** The track has already stopped itself. */
	@:listen(track.onOver) private function overHandler(): Void {
		horse.trip(track.speed);
		world.freeze(true);
		audio.gameOver();
		// Synchronous, so AppController files the record before the board below is read.
		eOver.dispatch(track.coins);
		// Topping an empty board with nothing collected is not a record.
		over.show(track.coins, track.coins > 0 && profile.lastIsBest(), profile.board());
	}

	@:listen(horse.onSettle) private function settleHandler(): Void world.blink(true);

	/**
	 * A frame late on purpose: handing over inside the key's own dispatch would let one Enter both
	 * leave this screen and press PLAY behind it.
	 */
	@:listen(over.onContinue) private function continueHandler(): Void DeltaTime.skipUpdate(finish);

	private function finish(): Void {
		// Dismissing the screen mid-flip is allowed, so the tumble may still be running.
		horse.stop();
		world.blink(false);
		world.freeze(false);
		over.hide();
		setVisible(false);
		eContinue.dispatch();
	}

	private function setVisible(value: Bool): Void {
		world.visible = value;
		hud.visible = value;
	}

}
