package view;

/**
 * One strip of a wrapping layer: `period` wide, `make` fills one copy, and the strip holds as many
 * copies as the column needs plus one for the gap the slide opens. Scrolling is a fraction of the
 * travelled distance, so a far layer drifts slower than the ground.
 *
 * `step` is the blow-up the art was drawn for, and callers deliberately disagree on it. A strip
 * carrying a unique object has a second sum to satisfy: `period - <width>` must exceed that object
 * or it shows at both edges at once. See <parallax> in pony.xml, where the moon is that object.
 */
@:nullSafety(Strict) final class ParallaxLayer {

	/** How far the strip has to travel before it looks the same again. */
	private final period: Float;

	private final parallax: Float;

	/** The blow-up the art was drawn at, and so the size of one of its pixels on screen. */
	private final step: Float;

	private final make: Object -> Void;
	private final copies: Array<Object>;

	/**
	 * The strip's own node. A view adds this itself rather than handing a parent in: under strict
	 * null safety it cannot pass `this` anywhere until all of its fields, strips included, are set.
	 */
	public final root: Object = new Object();

	/**
	 * `make` fills one copy: a tiled image, a ground tile, a handful of props at their own offsets.
	 * The column is a fixed width, so the number of copies is settled here and never changes.
	 */
	public function new(period: Float, parallax: Float, step: Float, make: Object -> Void) {
		this.period = period;
		this.parallax = parallax;
		this.step = step;
		this.make = make;
		// One more than covers the column: the extra copy fills the gap the strip opens as it slides.
		copies = [for (i in 0...Math.ceil(Config.width / period) + 1) new Object(root)];
		for (copy in copies) make(copy);
		// Spreads them out: a copy's x is only ever set here, so a strip with `parallax` 0 would
		// otherwise draw its whole run stacked on the left edge.
		moveTo(0);
	}

	/** The common case: one tiled image, blown up by `scale`. */
	public static function image(tile: Tile, parallax: Float, scale: Float): ParallaxLayer {
		return new ParallaxLayer(tile.width * scale, parallax, scale, copy -> new Bitmap(tile, copy).setScale(scale));
	}

	/**
	 * Hangs the whole strip from `value`; a backdrop takes the top of the visible box, a silhouette
	 * takes its own height above the ground line so its bottom row lands on it.
	 */
	public inline function setY(value: Float): Void root.y = value;

	/**
	 * Rebuilds every copy's contents, for a strip sized by the visible box. The copies keep their
	 * places, so a rebuild is invisible where the box did not move.
	 */
	public function rebuild(): Void for (copy in copies) {
		copy.removeChildren();
		make(copy);
	}

	/**
	 * Slides the strip to where the given travelled distance puts this layer. Snapped to whole art
	 * pixels: at a fractional offset the rasteriser cuts one upscaled pixel short per period.
	 */
	public function moveTo(distance: Float): Void {
		final shift: Float = snap(wrap(distance * parallax, period), step);
		for (i => copy in copies) copy.x = i * period - shift;
	}

	/** Folds a distance back into `0...span`. */
	private static inline function wrap(value: Float, span: Float): Float {
		return value - Math.floor(value / span) * span;
	}

	/** Rounds to a whole multiple of `step`, so an upscaled art pixel is never cut short. */
	private static inline function snap(value: Float, step: Float): Float return Math.round(value / step) * step;

}
