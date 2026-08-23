package controller;

import model.ProfileModel;
import model.SettingsModel;
import view.SkyView;

/** Root of the service graph: owns what both screens share and passes the run between them. */
@:nullSafety(Strict) final class AppController implements DI implements HasListener {

	@:own private var appService: AppService = new AppService();

	/** First into the scene, so everything else draws over it. */
	@:own private var sky: SkyView = new SkyView();

	@:own private var settings: SettingsModel = new SettingsModel();

	@:own private var audio: AudioService = new AudioService();

	@:own private var profile: ProfileModel = new ProfileModel();
	@:own private var menu: MenuController = new MenuController();
	@:own private var game: GameController = new GameController();

	public function new() menu.show();

	@:listen(menu.onStart) private function startHandler(): Void game.start();

	@:listen(game.onOver) private function overHandler(coins: Int): Void profile.addRecord(coins);

	@:listen(game.onContinue) private function continueHandler(): Void menu.show();

}
