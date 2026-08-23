package model;

import hxd.Save;

private typedef SettingsData = {
	music: Float,
	sound: Float
}

/**
 * How loud each half of the sound is. Linear gain, 0..1: the slider value is the channel group
 * volume, no curve. Persisted through `hxd.Save` under a name of its own, so clearing the
 * scoreboard does not take the settings with it.
 */
@:nullSafety(Strict) final class SettingsModel implements HasSignal implements HasListener {

	private static inline final SAVE_NAME: String = 'horse_game_settings';

	@:bindable public var music: Float = Config.game_audio_music;
	@:bindable public var sound: Float = Config.game_audio_sound;

	public function new() {
		// Declaration initializers run before this, so the fields already hold the config defaults.
		final data: SettingsData = Save.load({ music: music, sound: sound }, SAVE_NAME);
		music = data.music;
		sound = data.sound;
	}

	/** Silences the music, or restores it to the default; the previous value is not remembered. */
	public function muteMusic(): Void music = music > 0 ? 0 : Config.game_audio_music;

	/** The same for the effects. */
	public function muteSound(): Void sound = sound > 0 ? 0 : Config.game_audio_sound;

	/**
	 * The builder appends `listen()` to the end of the constructor, so loading the saved values
	 * above does not come back through here as a save of what was just read.
	 */
	@:listen(changeMusic)
	@:listen(changeSound)
	private function changeHandler(value: Float, previous: Float): Void Save.save({ music: music, sound: sound }, SAVE_NAME);

}
