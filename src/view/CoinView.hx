package view;

import h3d.shader.ColorAdd;
import model.Entity.EntityKind;
import pony.math.MathTools;

/**
 * A coin standing in the world, and the coin flying into the horse once it is reached.
 *
 * Standing is not still: the coin sinks and comes back, offset into that swing by its place on the
 * track so a row ripples. It only ever goes DOWN from the authored height, and the collision box
 * never moves with it, because those heights are the difficulty curve.
 *
 * `flying` is the whole of being collected: assigning it subscribes and unsubscribes the tick. One
 * progress drives both the slide into `target` and the whitening.
 *
 * Pooled, so `show` puts it back to work and `onArrive` says it is finished with. The shader is
 * held rather than set through `Drawable.colorAdd`, which can only be cleared with a null its
 * setter refuses.
 */
@:nullSafety(Strict) final class CoinView extends Anim implements HasSignal implements HasListener {

	/** Radians of swing per px of travel, from how much travel one whole swing takes. */
	private static final BOB: Float = 2 * Math.PI / Config.game_coin_bobPeriod;

	/** The flight is over; whoever owns the coin may take it back. */
	@:auto public var onArrive: Signal0;

	/** Assigning this starts and finishes the flight; the frame tick follows it. */
	@:bindable('private') private var flying: Bool = false;

	/** What the coin flies into. Read afresh every frame: the horse keeps moving while it does. */
	private final target: Object;

	/** The whitening, as its own shader so the amount added is a field write and not a rebuild. */
	private final white: ColorAdd = new ColorAdd();

	/** Where the flight started, in the coordinates of whichever layer draws it. */
	private final from: Point<Float> = new Point<Float>(0, 0);

	/**
	 * Half the drawn coin. A coin is placed by its top left corner and the horse by its middle, so
	 * this is what comes off the target for the two middles to meet.
	 */
	private final half: Point<Float> = new Point<Float>(0, 0);

	/** Where the track put the coin, which is the TOP of the swing; see `bob`. */
	private var base: Float = 0;

	/** How far into the swing this coin's own place on the track puts it. */
	private var phase: Float = 0;

	private var time: Float = 0;

	public function new(target: Object) {
		super([], Config.game_coin_fps);
		this.target = target;
	}

	/** Back to work: the frames its kind is drawn with, at the width the track asked for. */
	public function show(kind: EntityKind, width: Float): Void {
		final tiles: Array<Tile> = Assets.animation(asset(kind));
		play(tiles);
		final scale: Float = width / tiles[0].width;
		setScale(scale);
		half.x = width / 2;
		half.y = tiles[0].height * scale / 2;
	}

	/**
	 * Where the track wants the coin. `y` is the height it was authored at, which the swing only
	 * ever goes down from, and its place along the track is what offsets it into that swing.
	 */
	public function stand(x: Float, y: Float): Void {
		this.x = x;
		base = y;
		phase = x * BOB;
	}

	/**
	 * A step of the swing, clocked by distance travelled so a frozen picture is frozen whole.
	 * `1 - cos` keeps the coin at or below the authored height and eases both ends of the drop.
	 */
	public inline function bob(distance: Float): Void {
		y = base + (1 - Math.cos(phase + distance * BOB)) * Config.game_coin_bobDrop / 2;
	}

	/**
	 * Collected. The flight starts wherever the coin stands now, so its owner moves it into the
	 * layer that draws the flight first.
	 */
	public function pick(): Void {
		from.x = x;
		from.y = y;
		addShader(white);
		time = 0;
		flying = true;
	}

	@:listen(DeltaTime.update, flying) private function flyHandler(dt: DT): Void {
		time += dt;
		final progress: Float = time / Config.game_coin_pickTime;
		if (progress >= 1) {
			flying = false;
			removeShader(white);
			eArrive.dispatch();
			return;
		}
		x = MathTools.lerp(from.x, target.x - half.x, progress);
		y = MathTools.lerp(from.y, target.y - half.y, progress);
		white.color.set(progress, progress, progress);
	}

	private static inline function asset(kind: EntityKind): Int {
		return switch kind {
			case EntityKind.Silver: Assets.SILVER;
			case EntityKind.Gold: Assets.GOLD;
			case _: Assets.COPPER;
		}
	}

}
