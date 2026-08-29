package view;

import model.Entity;
import pony.TypedFPool;

/**
 * Everything the track puts on screen, in two layers. `world` holds every spawned entity at its
 * world position and is shifted whole by the travelled distance, so only a coin's swing is
 * repositioned per frame. `pickups` sits above it, where a collected coin stops scrolling.
 *
 * Coin views churn for the whole run, so they are pooled. Each is subscribed to once when first
 * made: a pooled coin is always the same instance.
 */
@:nullSafety(Strict) final class TrackView extends Object {

	/** Entities where the track put them; the whole layer slides by the travelled distance. */
	private final world: Object = new Object();

	/** Coins on their way in, out from under the track's scroll and over what still stands. */
	private final pickups: Object = new Object();

	private final views: Map<Entity, Object> = [];

	/**
	 * The coins still standing, which are the ones with a swing to step. An index into `views`,
	 * not a second truth: `spawn` and `take` are the only writers and they write both.
	 */
	private final standing: Array<CoinView> = [];

	/** What a collected coin flies into; handed to every coin this layer makes. */
	private final target: Object;

	private final coins: TypedFPool<CoinView>;

	/** The travelled distance, kept because it is the clock a coin's swing is read from. */
	private var distance: Float = 0;

	public function new(target: Object) {
		super();
		this.target = target;
		coins = new TypedFPool<CoinView>(makeCoin);
		addChild(world);
		addChild(pickups);
	}

	public function spawn(entity: Entity): Void {
		final object: Object = if (entity.kind == EntityKind.Fence) {
			final fence: Object = fenceView();
			// Its own box stops at the rail, but the whole tile is drawn, standing on the ground line.
			fence.setPosition(entity.x, -Config.game_tile);
			fence;
		} else {
			final coin: CoinView = coinView(entity);
			coin.stand(entity.x, -(entity.y + entity.size.y));
			coin.bob(distance);
			standing.push(coin);
			coin;
		}
		world.addChild(object);
		views[entity] = object;
	}

	public function despawn(entity: Entity): Void {
		final object: Object = take(entity);
		if (entity.kind == EntityKind.Fence)
			object.remove();
		else
			release(cast(object, CoinView));
	}

	/**
	 * A collected coin leaves the world for the layer above and flies itself the rest of the way.
	 * The model has already let go of the entity, so no `despawn` follows.
	 */
	public function pick(entity: Entity): Void {
		final coin: CoinView = cast(take(entity), CoinView);
		coin.setPosition(world.x + coin.x, world.y + coin.y);
		pickups.addChild(coin);
		coin.pick();
	}

	/** Scrolls the standing entities to the given travelled distance, and swings the coins by it. */
	public function moveTo(value: Float): Void {
		distance = value;
		world.x = Config.game_horse_x - value;
		for (coin in standing) coin.bob(value);
	}

	/** Puts the world's own origin on the ground line, which the window is free to move. */
	public inline function setY(value: Float): Void world.y = value;

	/** Holds every drawn frame still, or lets it run again. A flight is a transform and goes on. */
	public function freeze(value: Bool): Void {
		for (object in views) if (Std.isOfType(object, Anim)) cast(object, Anim).pause = value;
		for (coin in pickups) cast(coin, Anim).pause = value;
	}

	private function makeCoin(): CoinView {
		final coin: CoinView = new CoinView(target);
		coin.onArrive << release.bind(coin);
		return coin;
	}

	private function fenceView(): Object {
		final tile: Tile = Assets.getTexture(Assets.FENCE);
		final bitmap: Bitmap = new Bitmap(tile);
		bitmap.setScale(Config.game_tile / tile.width);
		return bitmap;
	}

	private function coinView(entity: Entity): CoinView {
		final coin: CoinView = coins.get();
		coin.show(entity.kind, entity.size.x);
		return coin;
	}

	/** Hands an entity's view over and forgets it; what becomes of it is the caller's. */
	private function take(entity: Entity): Object {
		final object: Null<Object> = views[entity];
		if (object == null) throw 'No view for entity';
		views.remove(entity);
		if (entity.kind != EntityKind.Fence) standing.remove(cast(object, CoinView));
		return object;
	}

	/** Puts a coin's view back in the pool: off the screen and ready for the next one. */
	private function release(coin: CoinView): Void {
		coin.remove();
		coins.ret(coin);
	}

}
