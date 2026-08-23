package model;

import hxd.Save;

/** One finished run. */
typedef ScoreRecord = {
	name: String,
	coins: Int
}

/** One line of the leaderboard: a record with the place it took. */
typedef BoardRow = {
	rank: Int,
	record: ScoreRecord,
	last: Bool
}

private typedef ProfileData = {
	name: String,
	records: Array<ScoreRecord>
}

/**
 * Player name and the local history of finished games. Persisted through `hxd.Save`:
 * localStorage on js, a file elsewhere.
 */
@:nullSafety(Strict) final class ProfileModel implements HasSignal {

	private static inline final SAVE_NAME: String = 'horse_game';
	private static inline final TOP_ROWS: Int = 3;

	@:auto public var onChange: Signal0;

	public var name(get, never): String;

	private final data: ProfileData;

	private var last: Null<ScoreRecord> = null;

	public function new() data = Save.load(fresh(), SAVE_NAME);

	private inline function get_name(): String return data.name;

	public function rename(value: String): Void {
		final trimmed: String = StringTools.trim(value);
		data.name = trimmed.length > 0 ? trimmed : NameGenerator.make();
		save();
	}

	public function addRecord(coins: Int): Void {
		final record: ScoreRecord = { name: data.name, coins: coins };
		data.records.push(record);
		while (data.records.length > Config.game_board_records) data.records.shift();
		last = record;
		save();
	}

	/**
	 * The visible slice of the ranking: the leaders, plus the last game and the row above it once
	 * it ranks below them.
	 */
	public function board(): Array<BoardRow> {
		final ranking: Array<ScoreRecord> = data.records.copy();
		ranking.sort(byCoins);
		final record: Null<ScoreRecord> = last;
		final index: Int = record == null ? -1 : ranking.indexOf(record);
		final size: Int = Config.game_board_rows;
		final places: Array<Int> = index < size ? [for (i in 0...size) i] : [for (i in 0...TOP_ROWS) i].concat([index - 1, index]);
		return [for (i in places) if (i < ranking.length) { rank: i + 1, record: ranking[i], last: i == index }];
	}

	/** True when the run that just finished took the top of the ranking. */
	public function lastIsBest(): Bool {
		final rows: Array<BoardRow> = board();
		return rows.length > 0 && rows[0].last;
	}

	private function save(): Void {
		Save.save(data, SAVE_NAME);
		eChange.dispatch();
	}

	private static function byCoins(a: ScoreRecord, b: ScoreRecord): Int return b.coins - a.coins;

	private static inline function fresh(): ProfileData return { name: NameGenerator.make(), records: [] };

}
