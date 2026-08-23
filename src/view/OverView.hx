package view;

import h2d.Interactive;
import model.ProfileModel.BoardRow;

/**
 * Sits over the frozen run: what it came to, where that put the player on the board, and the one
 * key or click it waits for. It slides in and stays deaf until it has landed, so the key that
 * ended the run cannot dismiss the score before it is read.
 */
@:ui('ui/over.xml')
final class OverView extends HeapsXmlUi implements DI implements HasSignal implements HasListener {

	@:auto public var onContinue: Signal0;

	@:use private var appService: AppService;

	private final table: BoardTable;
	private final touch: Interactive;

	/** The heading comes down from above the window and the board and its line come up from below. */
	private final drop: DropIn;

	/** Armed only once the screen has finished arriving. */
	@:bindable('private') private var waiting: Bool = false;

	public function new() {
		super(appService.scene);
		createUI(appService.app);
		table = new BoardTable([
			{ rank: board_row0rank, name: board_row0name, coins: board_row0coins },
			{ rank: board_row1rank, name: board_row1name, coins: board_row1coins },
			{ rank: board_row2rank, name: board_row2name, coins: board_row2coins },
			{ rank: board_row3rank, name: board_row3name, coins: board_row3coins },
			{ rank: board_row4rank, name: board_row4name, coins: board_row4coins }
		]);
		drop = new DropIn(appService, this, [head], [board, hint]);
		drop.onLand << landHandler;
		visible = false;
		// Sits on top of the run's own click sheet, so a click here never reaches the horse.
		touch = new Interactive(Config.width, 0, this);
		touch.onPush = _ -> dismiss();
		resizeHandler(appService.view);
	}

	/** The screen centres in the box the game is drawn in, and its click sheet covers all of it. */
	@:listen(appService.onResize) private function resizeHandler(view: Rect<Float>): Void {
		y = appService.screenY;
		touch.y = view.y - y;
		touch.height = view.height;
	}

	public function show(coins: Int, record: Bool, rows: Array<BoardRow>): Void {
		head_score.text = record ? 'NEW RECORD  $coins' : 'COINS  $coins';
		table.set(rows);
		visible = true;
		// After the text: the drop measures the blocks, and text is the last thing that moves them.
		drop.play();
	}

	public function hide(): Void visible = false;

	/** Not a moment before: the key that ended the run is often still down while the score arrives. */
	private function landHandler(): Void waiting = true;

	@:listen(Keyboard.down, waiting) private function keyHandler(key: Key): Void dismiss();

	/**
	 * Dropping `waiting` unsubscribes `keyHandler` inside its own dispatch, so a mashed key cannot
	 * continue twice. The click sheet outlives the screen, hence the guard.
	 */
	private function dismiss(): Void {
		if (!waiting) return;
		waiting = false;
		eContinue.dispatch();
	}

}
