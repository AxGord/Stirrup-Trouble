Stirrup Trouble
===============

Endless runner for the "Horsin' Around" game jam. Haxe + Heaps + Pony.

The horse runs on its own; you only jump, over the fences and up to whichever coins you can reach.
Copper sits low, silver needs a hop, gold needs a full jump. Holding the jump goes higher, letting
go cuts it short. A fence trips the horse into a somersault, the picture freezes where it lands and
the score comes up.

Play: `Space` / `Up` / `W` / click. Any key or a click returns to the menu.

Link to the game
-----
<https://axgord.itch.io/stirrup-trouble>


Build
-----

1. [Node.js](https://nodejs.org/) (lts), [Haxe](https://haxe.org/),
   [TexturePacker](https://www.codeandweb.com/texturepacker), [ffmpeg](https://ffmpeg.org/)
2. [Pony](https://github.com/AxGord/Pony): `haxelib install pony && haxelib run pony`
3. `pony prepare` installs libs, cuts the spritesheets, packs the atlas, converts the audio
4. `pony build js` writes `bin/app.js`
5. `pony server` serves `bin/` on <http://localhost:2000>

Use `pony build js`, not `haxe js.hxml`: the plain compile skips the uglify step that prepends
`docready.js`, and the page then fails on `$global.docReady is not a function`.

`pony run test` builds and runs the tests. They are declared in `pony.xml` like every other target,
so any build compiles them and a test that stops compiling is caught everywhere. Running belongs to
`<run>` and not to a `--cmd` in the hxml: pony reads only the compiler's stderr, so a `--cmd`'s
output is discarded and one that prints past the pipe buffer deadlocks the build.

The target is js on node, not neko: `src/import.hx` resolves heaps eagerly and pony's `Keyboard`
has no neko backend.

Credits
-------

Three of these are CC-BY and the credit is a condition of use: the birds' page asks to be linked
back to, and the GUI's licence asks that changes be indicated. The rest are CC0 or public domain.

* Tiles:
  [Platformer Art Complete Pack](https://opengameart.org/content/platformer-art-complete-pack-often-updated)
  by Kenney Vleugels ([kenney.nl](https://kenney.nl/)), CC0. `castleMid` and `castleCenter` are the
  ground; the pack is lit for daylight, so it reads brighter than the dusk backdrop on purpose.
* Backdrop: Parallax Mountain Pack by Luis Zuno ([@ansimuz](https://ansimuz.com/)), CC0. No link:
  the drop is `parallax_mountain_pack.zip` from 2015 and its own `license.txt` is what names the
  author and the licence.
* Title screen: [GothicVania Town](https://ansimuz.itch.io/gothicvania-town) by the same author,
  public domain. `TownView` composes a still frame from its tiling layers and drifts only the sky.
* GUI: [RPG GUI construction kit v1.0](https://opengameart.org/content/rpg-gui-construction-kit-v10)
  by Lamoot (Matjaz Lamut), CC-BY 3.0, **modified**. Its button is one image; the three states in
  `art/ui/` are it desaturated (resting), warmed (hover and keyboard selection) and warmed then
  darkened (pressed). That recolour is the change the licence asks to see named.
* Horse: [Pixel Horse](https://opengameart.org/content/pixel-horse) by alizard, CC0. Only
  `horse_run_cycle.png` is used.
* Coins: [Animated Coins](https://opengameart.org/content/animated-coins) by Clint Bellanger,
  CC-BY 3.0. The page asks to be credited as "Clint Bellanger for Liberated Pixel Art".
* Birds: [\[LPC\] Birds](https://opengameart.org/content/lpc-birds) by bluecarrot16, commissioned
  by castelonia, CC-BY 3.0. The page asks for a link back to itself, which is the link above.
* Music and sound effects: written for the jam by AxGord <axgord@gmail.com>, like the code.

None of this is in the game yet; it lives here and on the itch page, and the win, mac and android
builds carry neither. Wherever it ends up shown in-game, the birds' link-back stays a README
obligation, because a link is not clickable there.