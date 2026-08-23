package controller;

import model.NameGenerator;
import model.ProfileModel;
import model.SettingsModel;
import view.MenuView;
import view.TownView;

/** Title screen logic, and the owner of the backdrop the screen sits on. */
@:nullSafety(Strict) final class MenuController implements DI implements HasSignal implements HasListener {

	@:auto public var onStart: Signal0;

	@:use private var profile: ProfileModel;
	@:use private var settings: SettingsModel;
	@:use private var audio: AudioService;

	/** Declared before the menu, so the menu draws over it. */
	@:own private var town: TownView = new TownView();

	@:own private var view: MenuView = new MenuView();

	public function new() {
		view.setVolumes(settings.music, settings.sound);
		refresh();
	}

	public function show(): Void {
		audio.music(Assets.MUSIC_MAIN);
		town.show();
		view.show();
		refresh();
	}

	@:listen(view.onPlay) private function playHandler(mode: Int): Void {
		audio.sfx(Assets.SFX_BTN_START);
		profile.rename(view.playerName);
		view.hide();
		town.hide();
		eStart.dispatch();
	}

	@:listen(view.onNewName) private function newNameHandler(mode: Int): Void {
		audio.sfx(Assets.SFX_BTN_PRESS);
		profile.rename(NameGenerator.make());
	}

	@:listen(view.onSelect) private function selectHandler(): Void audio.select();

	@:listen(view.onMusicVolume) private function musicHandler(value: Float, previous: Float): Void settings.music = value;

	/** The sound slider has nothing to listen to while it moves, so it clicks at its new volume. */
	@:listen(view.onSoundVolume) private function soundHandler(value: Float, previous: Float): Void {
		settings.sound = value;
		audio.select();
	}

	@:listen(view.onMuteMusic) private function muteMusicHandler(): Void settings.muteMusic();

	@:listen(view.onMuteSound) private function muteSoundHandler(): Void settings.muteSound();

	/**
	 * Mute is decided in the settings, so the knob follows as well as leads. Writing a slider the
	 * value it already holds dispatches nothing, so the two cannot chase.
	 */
	@:listen(settings.changeMusic)
	@:listen(settings.changeSound)
	private function volumeHandler(value: Float, previous: Float): Void view.setVolumes(settings.music, settings.sound);

	@:listen(profile.onChange) private function changeHandler(): Void refresh();

	private function refresh(): Void {
		view.playerName = profile.name;
		view.setBoard(profile.board());
	}

}
