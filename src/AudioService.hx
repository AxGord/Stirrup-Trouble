import hxd.snd.Channel;
import hxd.snd.ChannelGroup;
import hxd.snd.Manager;
import hxd.snd.SoundGroup;
import model.SettingsModel;

/**
 * Everything the game is heard through. Player settings go on the two channel groups and fades on
 * the channel, so the two multiply instead of fighting. Master volume, `voices` and the music
 * group's priority are what keep the mix from falling over; see `<audio>` in pony.xml.
 */
@:nullSafety(Strict) final class AudioService implements DI implements HasListener {

	/** No track asked for; asset ids are generated indices starting at 0. */
	private static inline final NONE: Int = -1;

	private static final JUMPS: Array<Int> = [Assets.SFX_JUMP1, Assets.SFX_JUMP2, Assets.SFX_JUMP3];

	@:use private var settings: SettingsModel;

	private final musicGroup: ChannelGroup = new ChannelGroup('music');
	private final soundGroup: ChannelGroup = new ChannelGroup('sound');

	/** Caps simultaneous effects. A `SoundGroup`, not one of the volume groups above. */
	private final voices: SoundGroup = new SoundGroup('voices');

	/** The losing theme arrives after the crash sound, by when the player may have left the screen. */
	private var wanted: Int = NONE;

	private var current: Null<Channel> = null;

	/** Kept so releasing the key can cut it short. */
	private var jumping: Null<Channel> = null;

	/** Kept so leaving the score screen early takes it along. */
	private var crashing: Null<Channel> = null;

	private var selecting: Null<Channel> = null;

	public function new() {
		musicGroup.volume = settings.music;
		soundGroup.volume = settings.sound;
		voices.maxAudible = Config.game_audio_voices;
		// Outranks every effect in the sort that decides who keeps a source.
		musicGroup.priority = 1;
		Manager.get().masterVolume = Config.game_audio_master;
	}

	@:listen(settings.changeMusic) private function musicVolumeHandler(value: Float, previous: Float): Void musicGroup.volume = value;

	@:listen(settings.changeSound) private function soundVolumeHandler(value: Float, previous: Float): Void soundGroup.volume = value;

	/** Asking for the track already playing does nothing. */
	public function music(asset: Int): Void {
		if (wanted == asset) return;
		wanted = asset;
		crashing?.stop();
		crashing = null;
		start(asset);
	}

	/** A dragged slider asks for this many times a second, so the previous one is cut. */
	public function select(): Void {
		selecting?.stop();
		selecting = play(Assets.SFX_BTN_SELECT);
	}

	/** The race goes quiet at once; the losing theme waits for the crash sound to end. */
	public function gameOver(): Void {
		wanted = Assets.MUSIC_LOSE;
		fade();
		final channel: Channel = play(Assets.SFX_GAME_OVER);
		channel.onEnd = loseHandler;
		crashing = channel;
	}

	/** `spread` is drawn afresh each call, so a sample fired in rows does not read as a stutter. */
	public inline function sfx(asset: Int, spread: Float = 0): Void play(asset, 1 - Math.random() * spread);

	public function jump(): Void jumping = play(JUMPS[Std.random(JUMPS.length)]);

	/** Fade, not `stop`: cutting mid-waveform clicks. */
	public function cutJump(): Void {
		final channel: Null<Channel> = jumping;
		jumping = null;
		if (channel != null) channel.fadeTo(0, Config.game_audio_cut, channel.stop);
	}

	private function loseHandler(): Void {
		crashing = null;
		if (wanted == Assets.MUSIC_LOSE) start(Assets.MUSIC_LOSE);
	}

	private function start(asset: Int): Void {
		fade();
		final channel: Channel = Assets.sound(asset).play(true, 0, musicGroup);
		channel.fadeTo(1, Config.game_audio_fade);
		current = channel;
	}

	private function fade(): Void {
		final channel: Null<Channel> = current;
		current = null;
		if (channel != null) channel.fadeTo(0, Config.game_audio_fade, channel.stop);
	}

	private inline function play(asset: Int, volume: Float = 1): Channel return Assets.sound(asset).play(false, volume, soundGroup, voices);

}
