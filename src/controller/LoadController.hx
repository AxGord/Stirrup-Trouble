package controller;

import view.HudView;
import view.MenuView;

/** Loads the atlas and both UI files, then starts the service graph. */
@:nullSafety(Strict) final class LoadController {

	private var controller: Null<AppController> = null;

	public function new() AssetManager.loadComplete(initLoad, loadHandler);

	private function initLoad(cb: Int -> Int -> Void): Void {
		final loaders: Array<(Int -> Int -> Void) -> Void> = [Assets.loadAllAssets.bind(true), MenuView.loadUI, HudView.loadUI];
		final methods: Array<Int -> Int -> Void> = AssetManager.loadList(loaders.length, cb);
		for (i in 0...loaders.length) loaders[i](methods[i]);
	}

	private function loadHandler(): Void {
		#if js
		js.Browser.document.getElementById('preloader')?.remove();
		#end
		AppController.create(null, appHandler);
	}

	private function appHandler(value: AppController): Void controller = value;

}
