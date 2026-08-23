/**
 * Pictures land in one atlas; a name's first segment is the `<input>` root it came from. Sound is
 * not packed, so those fields give `@:asset` no region name. `ui/` regions are named in
 * `ui/menu.xml`, not here. See pony.xml.
 *
 * The repeated literals and missing types are required: `HasAssetBuilder` only matches an
 * unannotated var whose value is a string constant.
 */
@:assets_path('')
@:nullSafety(Strict) final class Assets implements HasAsset {

	@:asset('horse/run') public static final HORSE = 'game.atlas';
	@:asset('coin/copper') public static final COPPER = 'game.atlas';
	@:asset('coin/silver') public static final SILVER = 'game.atlas';
	@:asset('coin/gold') public static final GOLD = 'game.atlas';
	@:asset('bird/black') public static final BIRD_BLACK = 'game.atlas';
	@:asset('bird/eagle') public static final BIRD_EAGLE = 'game.atlas';
	@:asset('bird/sparrow') public static final BIRD_SPARROW = 'game.atlas';
	@:asset('sky/bg') public static final SKY_BG = 'game.atlas';
	@:asset('sky/far') public static final SKY_FAR = 'game.atlas';
	@:asset('sky/mountains') public static final SKY_MOUNTAINS = 'game.atlas';
	@:asset('sky/trees') public static final SKY_TREES = 'game.atlas';
	@:asset('sky/near') public static final SKY_NEAR = 'game.atlas';
	// Stored small and drawn back up, so the world shares the horse's pixel size.
	@:asset('tiles/ground') public static final GROUND = 'game.atlas';
	@:asset('tiles/fill') public static final FILL = 'game.atlas';
	@:asset('tiles/fence') public static final FENCE = 'game.atlas';
	// `sky` and `city` tile, the rest are props standing on the ground line.
	@:asset('town/sky') public static final TOWN_SKY = 'game.atlas';
	@:asset('town/city') public static final TOWN_CITY = 'game.atlas';
	@:asset('town/ground') public static final TOWN_GROUND = 'game.atlas';
	@:asset('town/house') public static final TOWN_HOUSE = 'game.atlas';
	@:asset('town/wagon') public static final TOWN_WAGON = 'game.atlas';
	@:asset('town/well') public static final TOWN_WELL = 'game.atlas';
	@:asset('town/lamp') public static final TOWN_LAMP = 'game.atlas';
	@:asset public static final MUSIC_MAIN = 'music/main.mp3';
	@:asset public static final MUSIC_RACE = 'music/race.mp3';
	@:asset public static final MUSIC_LOSE = 'music/lose.mp3';
	@:asset public static final SFX_BTN_SELECT = 'sound/btn_select.mp3';
	@:asset public static final SFX_BTN_PRESS = 'sound/btn_press.mp3';
	@:asset public static final SFX_BTN_START = 'sound/btn_start.mp3';
	@:asset public static final SFX_COIN_COPPER = 'sound/coin1.mp3';
	@:asset public static final SFX_COIN_SILVER = 'sound/coin2.mp3';
	@:asset public static final SFX_COIN_GOLD = 'sound/coin3.mp3';
	@:asset public static final SFX_GAME_OVER = 'sound/game_over.mp3';
	@:asset public static final SFX_JUMP_END = 'sound/jump_end.mp3';
	// Picked at random on each jump, so they are addressed as a range.
	@:asset public static final SFX_JUMP1 = 'sound/jump1.mp3';
	@:asset public static final SFX_JUMP2 = 'sound/jump2.mp3';
	@:asset public static final SFX_JUMP3 = 'sound/jump3.mp3';

}
