import controller.LoadController;

function main(): Void {
	AssetManager.baseUrl = Config.baseUrl;
	#if js
	js.Browser.console.log('Build date: ${pony.Tools.getBuildDate()}');
	pony.JsTools.onDocReady < init;
	#else
	#if (app == 'win')
	hl.UI.closeConsole();
	#end
	inline init();
	#end
}

function init(): Void {
	// Fit to minHeight, not the nominal shape: a taller window gains sky and ground, not border.
	new HeapsApp(new Point<Int>(Config.width, Config.minHeight), Config.background).onInit < initHandler;
}

function initHandler(application: HeapsApp): Void {
	application.setScalableScene();
	#if js
	// Tab is the menu's own key; without this the browser walks its focus ring instead.
	js.Browser.window.addEventListener('keydown', (event: js.html.KeyboardEvent) -> {
		if (event.key == 'Tab') event.preventDefault();
	}, true);
	#end
	new LoadController();
}
