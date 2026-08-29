package model;

import model.Entity.EntityKind;

/**
 * The track ahead: it scrolls past at a growing speed, hands out the coins the horse reaches and
 * ends the run on the first fence it does not. Both are tested against the same rectangle in one
 * pass. `running` is the whole lifecycle: assigning it subscribes and unsubscribes the tick.
 */
@:nullSafety(Strict) final class TrackModel implements DI implements HasSignal implements HasListener {

	private static final COIN_KINDS: Array<EntityKind> = [EntityKind.Copper, EntityKind.Silver, EntityKind.Gold];

	/** How high above the ground each coin kind floats, in the same order as COIN_KINDS. */
	private static final COIN_HEIGHTS: Array<Float> = [Config.game_coin_copperY, Config.game_coin_silverY, Config.game_coin_goldY];

	@:auto public var onSpawn: Signal1<Entity>;
	@:auto public var onRemove: Signal1<Entity>;
	@:auto public var onOver: Signal0;

	/**
	 * A coin has been taken, carrying the kind that `coins` alone does not say. This is where a
	 * picked coin leaves the track and no `onRemove` follows: whoever drew it owns it from here.
	 */
	@:auto public var onPick: Signal1<Entity>;

	@:bindable public var coins: Int = 0;
	@:bindable public var distance: Float = 0;

	/** How fast the track is running past, in px/s; a trip throws the horse forward with it. */
	public var speed(default, null): Float = 0;

	/** Assigning this is the whole start/stop; `update` follows it. */
	@:bindable('private') private var running: Bool = false;

	/** Only for its height: what the track hits depends on how high the horse is. */
	@:use private var horse: HorseModel;

	private final entities: Array<Entity> = [];
	private final fenceSize: Point<Float> = new Point<Float>(Config.game_tile, Config.game_fenceHeight);
	private final coinSize: Point<Float> = new Point<Float>(Config.game_coin_size, Config.game_coin_size);

	private var nextSpawn: Float = 0;

	public function start(): Void {
		for (entity in entities) eRemove.dispatch(entity);
		entities.resize(0);
		coins = 0;
		distance = 0;
		speed = Config.game_speed;
		nextSpawn = Config.width;
		running = true;
	}

	@:listen(DeltaTime.update, running) private function update(dt: DT): Void {
		speed += Config.game_speedGrow * dt;
		distance += speed * dt;
		spawn();
		collide();
	}

	private function spawn(): Void {
		while (nextSpawn < distance + Config.width) {
			if (Std.random(Config.game_spawn_fenceLimit) < Config.game_spawn_fenceChance)
				put(new Entity(EntityKind.Fence, nextSpawn, 0, fenceSize));
			else
				putCoins();
			nextSpawn += Config.game_spawn_minGap + Std.random(Config.game_spawn_maxGap - Config.game_spawn_minGap);
		}
	}

	private function putCoins(): Void {
		final index: Int = Std.random(COIN_KINDS.length);
		for (i in 0...Config.game_coin_row)
			put(new Entity(COIN_KINDS[index], nextSpawn + i * Config.game_coin_step, COIN_HEIGHTS[index], coinSize));
	}

	private function collide(): Void {
		final width: Float = Config.game_horse_width;
		// The world is drawn shifted by horse.x, so an entity stays on screen that much longer.
		final gone: Float = distance - Config.game_horse_x;
		var i: Int = 0;
		while (i < entities.length) {
			final entity: Entity = entities[i];
			if (entity.x + entity.size.x < gone) {
				drop(i);
				continue;
			}
			if (entity.x > distance + width) break;
			// A fence is measured against the legs alone, a coin against the whole box: catching a
			// coin on the nose is a gift, tripping on the air under it is not.
			if (entity.kind == EntityKind.Fence) {
				if (entity.hits(distance + Config.game_horse_hitLeft, horse.height, Config.game_horse_hitWidth, Config.game_horse_height)) {
					crash();
					return;
				}
				i++;
				continue;
			}
			if (!entity.hits(distance, horse.height, width, Config.game_horse_height)) {
				i++;
				continue;
			}
			coins += entity.value;
			// Not `drop`: a picked coin is handed over whole and its view lives on past this.
			entities.splice(i, 1);
			ePick.dispatch(entity);
		}
	}

	private function crash(): Void {
		running = false;
		eOver.dispatch();
	}

	private inline function put(entity: Entity): Void {
		entities.push(entity);
		eSpawn.dispatch(entity);
	}

	private inline function drop(index: Int): Void eRemove.dispatch(entities.splice(index, 1)[0]);

}
