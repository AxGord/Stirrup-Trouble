/**
 * Entry point of the test target. `pony.Config` is built from `pony.xml` at macro time, so these
 * cases see exactly the constants the game ships with.
 */
function main(): Void {
	JumpTest.run();
	BirdTest.run();
	FrameTest.run();
	AtlasTest.run();
	AudioTest.run();
	Sys.exit(Check.report());
}
