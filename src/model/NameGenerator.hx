package model;

/** Gives every player a throwaway cowboy alias. */
@:nullSafety(Strict) final class NameGenerator {

	private static final TITLES: Array<String> = [
		  'Dusty',   'Lucky', 'Rowdy',   'Wild',      'Sly',  'Grumpy', 'Fearless', 'Lonesome',
		'Crooked', 'Thirsty', 'Rusty', 'Sleepy', 'Reckless', 'Two-Gun',   'Silent',      'Mad'
	];

	private static final NAMES: Array<String> = [
		'Bronco', 'Mustang', 'Stirrup', 'Saddle', 'Buckaroo', 'Wrangler', 'Cactus', 'Whiskers',
		'Hoofer',  'Pancho', 'Trotter', 'Bandit',     'Colt', 'Maverick', 'Nugget',    'Pinto'
	];

	public static function make(): String return '${pick(TITLES)} ${pick(NAMES)}';

	private static inline function pick(list: Array<String>): String return list[Std.random(list.length)];

}
