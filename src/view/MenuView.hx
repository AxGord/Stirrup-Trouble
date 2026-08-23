package view;

import h3d.Vector4;
import model.ProfileModel.BoardRow;
import pony.events.Signal2;
import pony.heaps.ui.gui.Button;
import pony.heaps.ui.gui.Node;
import pony.heaps.ui.gui.StepSlider;
import pony.math.MathTools;
import pony.ui.Presser;
import pony.ui.gui.ButtonCore;
import pony.ui.gui.ButtonCore.ButtonState;
import pony.ui.gui.StepSliderCore;

/**
 * Title screen: the player name, the start button, the volume sliders and the local leaderboard.
 * Everything is reachable from the keyboard, which is what `cursor` is: one cycle over the field,
 * the buttons and the sliders, in that order. It slides in and answers nothing until it lands.
 */
@:ui('ui/menu.xml')
final class MenuView extends HeapsXmlUi implements DI implements HasLink implements HasSignal implements HasListener {

	/** Value of `cursor` meaning the keyboard is on nothing at all. */
	private static inline final NONE: Int = -1;

	/** `cursor` walks the name field first, then `buttons`, then `sliders`. */
	private static inline final FIELD: Int = 0;

	/**
	 * Where `sliders` starts in the cursor, one past the last button. A constant rather than
	 * `buttons.length + 1` because the `@:listen` conditions read it at compile time; the
	 * constructor checks it against what was built.
	 */
	private static inline final SLIDERS: Int = 3;

	/**
	 * Milliseconds between the repeats of a held key. `Presser` is a program-wide global, set from
	 * here because the sliders are the only thing that repeats. `pressFirstDelay` is left alone:
	 * shortening it turns a deliberate single press into two.
	 */
	private static inline final REPEAT: Int = 100;

	/**
	 * What the backing of a selected field or slider is multiplied by. A button has art for being
	 * selected; the field and the sliders have none, so theirs is brightened instead.
	 */
	private static final LIT: Vector4 = new Vector4(2.4, 2.4, 2.4, 1);

	private static final UNLIT: Vector4 = new Vector4(1, 1, 1, 1);

	/** Something on this screen has just become the selected thing, by either hand. */
	@:auto public var onSelect: Signal0;

	/** The selected slider has been asked to silence itself, or to stop being silent. */
	@:auto public var onMuteMusic: Signal0;

	@:auto public var onMuteSound: Signal0;

	public var onPlay(link, never): Signal1<Int> = play_button.core.onClick;
	public var onNewName(link, never): Signal1<Int> = dice_button.core.onClick;
	public var playerName(link, link): String = field_input.text;
	public var onMusicVolume(link, never): Signal2<Float, Float> = settings_music.sliderCore.changeValue;
	public var onSoundVolume(link, never): Signal2<Float, Float> = settings_sound.sliderCore.changeValue;

	@:use private var appService: AppService;

	private final buttons: Array<Button>;
	private final sliders: Array<StepSlider>;

	private final table: BoardTable;

	/** The column comes down from above the window and the leaderboard comes up from below. */
	private final drop: DropIn;

	/** Where the keyboard is: FIELD, a button, a slider, or NONE while the menu is off. */
	@:bindable('private') private var cursor: Int = NONE;

	/** True only once the menu has landed: the run owns the same keys and one may still be down. */
	@:bindable('private') private var active: Bool = false;

	/** True while the name field holds the keyboard: the arrows are its caret then, not ours. */
	@:bindable('private') private var editing: Bool = false;

	/** True while a key is holding the selected button down, from a press this screen saw. */
	@:bindable('private') private var pressed: Bool = false;

	public function new() {
		super(appService.scene);
		createUI(appService.app);
		Presser.pressDelay = REPEAT;
		buttons = [dice_button, play_button];
		sliders = [settings_music, settings_sound];
		if (SLIDERS != buttons.length + 1) throw 'SLIDERS is the cursor index after the last button';
		table = new BoardTable([
			{ rank: board_row0rank, name: board_row0name, coins: board_row0coins },
			{ rank: board_row1rank, name: board_row1name, coins: board_row1coins },
			{ rank: board_row2rank, name: board_row2name, coins: board_row2coins },
			{ rank: board_row3rank, name: board_row3name, coins: board_row3coins },
			{ rank: board_row4rank, name: board_row4name, coins: board_row4coins }
		]);
		// Clicking the field is the same selection the arrows make, so it moves the cursor too.
		field_input.onFocus = _ -> {
			editing = true;
			cursor = FIELD;
		};
		field_input.onFocusLost = _ -> editing = false;
		for (index => button in buttons) watchPointer(index + 1, button.core);
		for (index => slider in sliders) {
			// A horizontal `StepSlider` only drives its own axis, so the taller knob needs centring.
			slider.button.y = (slider.bg.h - slider.button.height) / 2;
			watchPointer(SLIDERS + index, slider.button.core);
			// Taking hold selects it, off the track as well as the knob: both dispatch `startDrag`.
			slider.sliderCore.onStartDrag << selectHandler.bind(SLIDERS + index);
		}
		drop = new DropIn(appService, this, [title, field, dice, play, settings], [board]);
		drop.onLand << landHandler;
		resizeHandler(appService.view);
	}

	/** The screen centres in the box the game is drawn in, not in the window. */
	@:listen(appService.onResize) private function resizeHandler(view: Rect<Float>): Void y = appService.screenY;

	/**
	 * Both directions of the pointer over one selectable thing. Arriving is a selection. Leaving
	 * drops `ButtonCore.state` to Default, and heaps sends one such event on the first frame
	 * before the cursor has been anywhere, so the keyboard selection is put back. `ButtonCore`
	 * subscribed first, which is what makes running after it enough.
	 */
	private function watchPointer(index: Int, core: ButtonCore): Void {
		core.touch.onOver << overHandler;
		core.touch.onOut << reselectHandler.bind(index);
		core.touch.onOutUp << reselectHandler.bind(index);
	}

	private function overHandler(): Void eSelect.dispatch();

	private function reselectHandler(index: Int): Void if (cursor == index) selectable(index).state = ButtonState.Focus;

	private function selectHandler(index: Int): Void cursor = index;

	/**
	 * Opens on PLAY, so another run is one key away. The selection is made at once and only the
	 * keys wait, so the screen arrives with PLAY already lit.
	 */
	public function show(): Void {
		visible = true;
		cursor = buttons.length;
		drop.play();
	}

	public function hide(): Void {
		visible = active = false;
		cursor = NONE;
		field_input.blur();
	}

	public inline function setBoard(rows: Array<BoardRow>): Void table.set(rows);

	/** The position the sliders open at. After this they are what says how loud the game is. */
	public function setVolumes(music: Float, sound: Float): Void {
		settings_music.sliderCore.value = music;
		settings_sound.sliderCore.value = sound;
	}

	/** Not a moment before: the key that dismissed the score is often still held when this opens. */
	private function landHandler(): Void active = true;

	// Up/Down move even while typing, or Tab would be the only way out; Left/Right are the caret's.
	@:listen(Keyboard.down - Key.Tab, active)
	@:listen(Keyboard.down - Key.Down, active)
	@:listen(Keyboard.down - Key.Right, active && !editing && cursor < SLIDERS)
	private function nextHandler(): Void moveCursor(1);

	@:listen(Keyboard.down - Key.Up, active)
	@:listen(Keyboard.down - Key.Left, active && !editing && cursor < SLIDERS)
	private function prevHandler(): Void moveCursor(-1);

	// On a slider the sideways keys belong to the slider; Up/Down and Tab still walk the screen.
	// `press` and not `down` for the auto-repeat pony gives a held key; the cursor keys stay on
	// `down` because walking a five-stop cycle on a repeat would overshoot.
	@:listen(Keyboard.press - Key.Right, active && cursor >= SLIDERS)
	private function louderHandler(): Void stepVolume(1);

	@:listen(Keyboard.press - Key.Left, active && cursor >= SLIDERS)
	private function quieterHandler(): Void stepVolume(-1);

	/**
	 * Mute and unmute on the same key. A slider has no click of its own, so both keys that press a
	 * button elsewhere do this. What silencing means is the settings' business.
	 */
	@:listen(Keyboard.down - Key.Enter, active && cursor >= SLIDERS)
	@:listen(Keyboard.down - Key.Space, active && cursor >= SLIDERS)
	private function muteHandler(): Void if (cursor == SLIDERS)
		eMuteMusic.dispatch()
	else
		eMuteSound.dispatch();

	// Press and release like the mouse. The window excludes NONE, the name field and the sliders.
	@:listen(Keyboard.down - Key.Enter, active && cursor > FIELD && cursor < SLIDERS)
	@:listen(Keyboard.down - Key.Space, active && cursor > FIELD && cursor < SLIDERS)
	private function pressHandler(): Void {
		pressed = true;
		selected().core.state = ButtonState.Press;
	}

	// Gated on the press this screen saw: the key that dismissed the score is still held here.
	@:listen(Keyboard.up - Key.Enter, pressed)
	@:listen(Keyboard.up - Key.Space, pressed)
	private function releaseHandler(): Void {
		pressed = false;
		final button: Button = selected();
		button.core.state = ButtonState.Focus;
		button.core.click(button.core.mode);
	}

	/** The keyboard drives the same Focus state the pointer does, so both look identical. */
	@:listen(changeCursor) private function cursorHandler(value: Int, previous: Int): Void {
		// Moving the selection cancels a held key, as dragging the pointer off a button does.
		pressed = false;
		if (previous > FIELD) selectable(previous).state = ButtonState.Default;
		if (value > FIELD) selectable(value).state = ButtonState.Focus;
		light(previous, UNLIT);
		light(value, LIT);
		if (value == FIELD) {
			// Guard the other direction: onFocus is what set the cursor here.
			if (!field_input.hasFocus()) field_input.focus();
		} else if (previous == FIELD) {
			field_input.blur();
		}
		// Leaving the screen is not a selection; arriving anywhere on it is.
		if (value != NONE) eSelect.dispatch();
	}

	/** Steps the keyboard along the cycle; from NONE it enters at whichever end it came from. */
	private function moveCursor(step: Int): Void {
		final total: Int = SLIDERS + sliders.length;
		cursor = cursor == NONE ? (step > 0 ? FIELD : total - 1) : (cursor + step + total) % total;
	}

	/**
	 * One notch of the slider's own step, so the keyboard and a drag land on the same grid.
	 * Through `percent`, not `value`: the core rounds a percent, but a value written straight in
	 * arrives unrounded and dispatches a second time once the core tidies it.
	 */
	private function stepVolume(step: Int): Void {
		final core: StepSliderCore = sliders[cursor - SLIDERS].sliderCore;
		core.percent = MathTools.limit(core.percent + step * core.percentStep, 0, 1);
	}

	/** Which `ButtonCore` a cursor position owns the state of: a button, or a slider's knob. */
	private inline function selectable(index: Int): ButtonCore
		return index < SLIDERS ? buttons[index - 1].core : sliders[index - SLIDERS].button.core;

	private inline function light(index: Int, tint: Vector4): Void {
		final node: Null<Node> = backing(index);
		if (node != null) node.tint = tint;
	}

	/** The rectangle a cursor position is lit on, for the two stops with no art of their own. */
	private inline function backing(index: Int): Null<Node> {
		return if (index == FIELD)
			field_panel;
		else if (index >= SLIDERS)
			sliders[index - SLIDERS].bg;
		else
			null;
	}

	private inline function selected(): Button return buttons[cursor - 1];

}
