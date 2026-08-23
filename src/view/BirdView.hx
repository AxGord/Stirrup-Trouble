package view;

/**
 * One bird crossing the sky. Pure decoration: drawn where nothing can reach it, so no collision
 * and no model knows it exists.
 *
 * Its clock is the travelled distance, not the wall, so it freezes with the rest of the picture
 * when a run ends and only the wingbeat needs pausing.
 *
 * An `Object` around the `Anim` rather than an `Anim` itself: the sheet faces left, so a bird
 * outrunning the horse is mirrored, and the wrapper keeps `x` its left edge either way.
 */
@:nullSafety(Strict) final class BirdView extends Object {

	/** Radians of rise and fall per px of travel, from how much travel one whole swing takes. */
	private static final BOB: Float = 2 * Math.PI / Config.game_bird_bobPeriod;

	/** True from the moment it is launched until it has left the column by the far edge. */
	public var flying(default, null): Bool = false;

	/** How high above the ground line its lowest drawn pixel was put. */
	public var lift(default, null): Float = 0;

	private final anim: Anim = new Anim([], Config.game_bird_fps);

	/** One cell of the sheet on screen: how far past an edge the bird is wholly outside it. */
	private var cell: Float = 0;

	/** The cell's top, which the bob moves the bird around rather than away from. */
	private var top: Float = 0;

	/** Where the crossing started, and the distance it started at. */
	private var from: Float = 0;

	private var since: Float = 0;

	/**
	 * Share of the travelled distance this bird slides by; the sign is the direction, positive
	 * back down the column and negative past the horse. See <bird> in pony.xml.
	 */
	private var drift: Float = 0;

	/** How far into the swing its own starting place puts it, so a pair never beats together. */
	private var phase: Float = 0;

	public function new() {
		super();
		addChild(anim);
		visible = false;
	}

	/**
	 * Back to work as one of the species, facing one of the two ways. A bird outlives any one
	 * flight, so the frames and mirroring are set here rather than in the constructor.
	 */
	public function show(tiles: Array<Tile>, mirror: Bool): Void {
		final scale: Int = Config.game_bird_scale;
		anim.play(tiles);
		anim.setScale(scale);
		cell = tiles[0].width * scale;
		// The flip is around the cell's own left edge, so the cell's width puts it back.
		anim.scaleX = mirror ? -scale : scale;
		anim.x = mirror ? cell : 0;
	}

	/** Puts the bird the given height above the given ground line; both are the flock's business. */
	public function place(value: Float, groundY: Float): Void {
		lift = value;
		top = groundY - value - Config.game_bird_artBottom * Config.game_bird_scale;
	}

	/**
	 * Starts a crossing from the distance the track has reached. The drift's sign picks the edge it
	 * enters by; `back` is how far behind the leader a follower starts.
	 */
	public function launch(distance: Float, drift: Float, back: Float): Void {
		from = drift > 0 ? Config.width + back : -cell - back;
		since = distance;
		this.drift = drift;
		phase = from * BOB;
		flying = visible = true;
		moveTo(distance);
	}

	/** Steps the crossing, and says whether any of the bird is still inside the column. */
	public function moveTo(distance: Float): Bool {
		x = from - (distance - since) * drift;
		y = top + Math.sin(phase + distance * BOB) * Config.game_bird_bobRange;
		return drift > 0 ? x > -cell : x < Config.width;
	}

	/** Gone by the far edge, or a new run: the flock may hand this one out again. */
	public inline function retire(): Void flying = visible = false;

	/** Holds the wingbeat still. The crossing is measured in distance, so it stops on its own. */
	public inline function freeze(value: Bool): Void anim.pause = value;

}
