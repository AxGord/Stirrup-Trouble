package view;

import model.ProfileModel.BoardRow;

/** The three texts one leaderboard line is drawn from. */
typedef BoardCells = {
	rank: Text,
	name: Text,
	coins: Text
}

/**
 * Fills the table `ui/board.xml` draws. Both screens include the same XML, but its generated ids
 * are fields of the including class, so each hands its own nodes here.
 */
@:nullSafety(Strict) final class BoardTable {

	private static inline final LAST_COLOR: Int = 0xFFD34D;
	private static inline final ROW_COLOR: Int = 0xF5E6C8;

	private final cells: Array<BoardCells>;

	public function new(cells: Array<BoardCells>) this.cells = cells;

	public function set(rows: Array<BoardRow>): Void {
		for (index => line in cells) setLine(line, index < rows.length ? rows[index] : null);
	}

	private static function setLine(line: BoardCells, row: Null<BoardRow>): Void {
		if (row == null) {
			line.rank.text = line.name.text = line.coins.text = '';
			return;
		}
		line.rank.text = '${row.rank}.';
		line.name.text = row.record.name;
		line.coins.text = '${row.record.coins}';
		line.rank.textColor = line.name.textColor = line.coins.textColor = row.last ? LAST_COLOR : ROW_COLOR;
	}

}
