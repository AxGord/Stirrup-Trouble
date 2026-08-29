package model;

enum abstract EntityKind(Int) {

	final Fence;
	final Copper;
	final Silver;
	final Gold;

}

/**
 * One thing standing in the world. `y` is measured up from the ground line, so ground is 0, and
 * `size` is the collision box, which the fence's art outgrows: it draws a whole tile.
 */
@:nullSafety(Strict) final class Entity {

	public final kind: EntityKind;
	public final x: Float;
	public final y: Float;
	public final size: Point<Float>;

	public var value(get, never): Int;

	public function new(kind: EntityKind, x: Float, y: Float, size: Point<Float>) {
		this.kind = kind;
		this.x = x;
		this.y = y;
		this.size = size;
	}

	private inline function get_value(): Int {
		return switch kind {
			case EntityKind.Copper: Config.game_coin_copperScore;
			case EntityKind.Silver: Config.game_coin_silverScore;
			case EntityKind.Gold: Config.game_coin_goldScore;
			case _: 0;
		}
	}

	public inline function hits(left: Float, bottom: Float, width: Float, height: Float): Bool {
		return x < left + width && x + size.x > left && y < bottom + height && y + size.y > bottom;
	}

}
