# Guild Ball menu style in Fight Guild

Source: the user-supplied `guildball-menu-reference-pack-2026-11-15.zip`, taken from Guild Ball's `development/menu-polish` at `32f73150944dfa6b1e5b7b82c3d666c02644e3dc`. Every supplied checksum was verified before import. Archive SHA-256: `94ba49536ee82d856a98b4363092de1f27448a109de42bd8c86d5f21c050386b`.

## Shared owners and assets

- `godot/scripts/guild_theme.gd` owns the normal and Settings themes. Normal menus, fighter selection, the online lobby, pause/results, sprite review and the development editor use charcoal / blue / brass. Controls owns a separate cream / warm-grey / burnt-orange theme.
- `godot/Content/UI/Stock` contains the supplied PNG surfaces, Godot style resources and manifest unchanged. Button slices remain 12 logical pixels with 6/3 content padding. Panel margins and asymmetric corners retain the supplied resource measurements. Semantic actions use Essential, Primary, Secondary and Danger variations; focus remains an independent outline.
- `godot/Content/UI/Settings` contains the supplied warm SVG surfaces. They are scoped to Controls; they do not recolor ordinary menus. The reference pack also includes surfaces for future settings controls, while native Controls now supports remapping and device/deadzone settings; see [input controls](input-controls.md).
- `godot/Content/Fonts` contains Barlow Condensed regular/semibold and the supplied Phosphor font. Font licenses are retained there and in the packaged `licenses/` directory. Menu headings use semibold; body and supporting text use regular. The existing large combat-feedback numerals keep their display font.
- Editable stock masters live in `art/ui-stock/svg`. New small checkbox glyphs live in `godot/assets/ui/icons`; they use the stock palette and remain separate from labels and behavior.
- `references/menu-style` retains the handoff, home, Controls and component-state reference captures. Other projects' sample names, data and text were not imported into game behavior.

## Layout and behavior

The home screen adapts the reference's palette, type and button surfaces to a fighting-game title screen: a large Fight Guild wordmark, an Anvil/Shark face-off and direct Versus, Training and Development choices. `home_faceoff.gd` reads the existing windup atlases for its decorative fighter artwork; it never starts or advances the combat simulation. Angled planes, a VS divider and guild-colored nameplates frame the pair. The six-fighter roster appears below the artwork, while mode help follows mouse hover or keyboard/controller focus. The unused runtime copies of the earlier concept-sheet cards were removed; original concept art remains under `art/characters`.

Character select takes its personality direction from the user's **2XKO** reference: a shared stage with large opposing fighters, oversized names, angled portrait tiles in a central 2×3 roster, and short character lines. It uses Fight Guild's existing sprites, fonts and palette. Guild-color planes and original geometric motifs identify each fighter; these are provisional UI motifs, not canonical guild crests. No external game's art or UI assets are included.

`FighterSelect` owns draft choices and native keyboard/controller focus. `FighterSelectPortrait` crossfades and slides the existing windup artwork with a brief guild-colored smear. `FighterRosterTile` draws clipped atlas portraits, player badges, hover color and an independent focus outline. Mirror matches show both player badges on the same tile. Online displays only the local player's controls. Character selection does not change combat pose rendering or simulation data.

`GameMenus` keeps fixed navigation and uses grouped panels for connection, pause and results. Character select keeps its roster, input toggles and start action visible together at 720p. `controls_guide.gd` keeps its heading, scheme tabs and 40-pixel Close action fixed while bindings scroll. Closing it restores focus to the opening control. Native buttons, checkboxes, option pickers, editable fields and keyboard/controller actions retain their behavior.

The reference's newspaper drawing/page-turn films were not supplied. `guild_backdrop.gd` supplies a quiet, static teal/brass gradient based on the reference home screen; it does not attempt to reproduce the absent films. Replace this still layer when the actual background films become available. Decorative layers ignore pointer input.

Page navigation uses interruptible eased slides/crossfades (840 ms in, 540 ms out), match entry/resume uses an 840 ms fade, and portrait changes use a 780 ms entrance. `MenuMotion.FULL_DURATION_SCALE` applies the shared 3× pace to full-motion fades, slides and reveals, including loading and ceremony artwork. New navigation retargets from the visible state; outgoing pages lose pointer/focus access immediately. **Motion: Reduced** in the home footer persists locally and removes translation and smear accents, shortening fades to at most 90 ms. Ceremony pauses retain their reading time and online synchronization. Animation time never enters combat or rollback snapshots.

The project uses a 1280×720 logical canvas and scales to 1920×1080. The development workbench and gatling reference now sit below the editor's other tools, inside its scroll area, leaving the arena and practice controls usable at 720p.

## Match HUD

`FightHud` carries the same type and palette into gameplay. Character names sit **inside the HP bars**, with outlined cream lettering that remains readable over both filled and depleted sections. Portraits attach to the outside ends, on the left for P1 and the right for P2. The separate nameplate boxes are removed, and the health bars move up into their former space. An open circular timer dial, the Scrum call and two small diamond win marks complete the top HUD. Fillet and Shark use newly generated high-resolution head-and-shoulder cutouts, overlapping the outer ends without thumbnail frames; the other four fighters use tighter crops from their existing atlases. Source hashes and the portrait brief are recorded in `godot/assets/ui/fighter-portraits-generation.json`. Health uses the fighter's guild palette at every value: Blacksmiths brass, Masons slate blue, Alchemists sage, Brewers amber, Fishermen teal, and Butchers rose. Mirror matches share their guild color. Damage clears each outside end toward the center timer, with a darker guild-tinted empty region; remaining health stays next to the timer. A shallow bend at 30% remaining health lowers each inner end by eight logical pixels; rail, fill, highlight and depletion edge follow the same mirrored profile. Player labels, score marks and Momentum use brass for Player 1 and teal for Player 2 regardless of their positions. Versus fills the viewport without the application toolbar or outside margins. Escape/controller Start still opens the match menu, which now also exposes Controls. Training and Development keep their toolbars. Momentum floats over the foreground with a soft bottom fade instead of a hard full-width panel. The three Momentum sections share the shaped framing; Faultless Defense changes the meter to mint green and names the active defense.

The HUD draws above fighter sprites, while outlined combo numerals sit higher in the stage background and grow from a small two-hit count to their maximum size at ten hits. COUNTER, PUNISH, REVERSAL, the intro names, and the opening ceremony use the same headline typography. All displayed values and feedback clocks still come directly from the combat state. Training/Development retain health numbers and move/frame diagnostics; Versus shows guild identity, an optional Simple indicator and score. Positive Bonus replaces the supporting status text while active. The narrower development arena scales the HUD with a minimum size for supporting labels.

`ArenaStage` uses generated sky, architecture and floor images with horizontal parallax. The floor and fighters share one world projection; scenic anchors register architecture against it, and dynamic body shadows ground the feet; see [stage presentation](stage-art.md). The hitbox grid appears only when hitboxes are enabled. Rendering does not change positions, collisions or combat rules.

`tests/hud_preview.gd -- --test --screenshot PATH` captures the native HUD with an unsaved six-hit fixture. Add `--neutral`, `--low-health`, `--fd`, `--training`, or `--development` to review specific states; `--p1 N --p2 N` selects portraits. `--hits N` captures a chosen count from 2 to 20 for size comparisons. Fixture move edits and scores never save to the player configuration.

## Review

On a machine with a rendering display:

```bash
bash scripts/godot.sh --resolution 1280x720 --script tests/ui_smoke.gd -- --test --home --screenshot /absolute/path/home-720.png
bash scripts/godot.sh --resolution 1920x1080 --script tests/ui_smoke.gd -- --test --controls --screenshot /absolute/path/controls-1080.png
bash scripts/godot.sh --resolution 1280x720 --script tests/style_review.gd -- --screenshot /absolute/path/surface-states.png
```

For quicker character-select captures, use `tests/menu_preview.gd -- --test --fighters --p1 0 --p2 4 --screenshot /absolute/path/select.png`. `--online`, `--training` and `--mirror` inspect those variants. The same script's `--tour` plays a reproducible native navigation tour; Godot's `--write-movie /absolute/path/tour.avi --fixed-fps 60` can record it.

The surface fixture shows normal, hover, pressed, focus and disabled artwork together. Actual input behavior is exercised by the menu suite: entry/back paths, keyboard/controller navigation, motion-only selection, pause/rematch, input isolation, Controls tabs/fixed footer/focus return, and ENet handshake/cancellation/disconnect recovery. The host-port check also prevents delayed SpinBox text from replacing the selected value.

## Match entrance

`MatchEntry` presents real selected-atlas loading, two skippable fighter spotlights, and a four-beat on-screen ceremony. Copy and beat timings live in `godot/data/match_ceremony.json`. The current calls are “The stands hunger for legends.” → “Let the guilds give them names.” → “1st Scrum” / “2nd Scrum” / “Final Down” → “Break the line!” Intros reuse existing windup poses with character-specific motion; dedicated authored intro frames and recorded announcer audio can replace these presentation assets later.

Each intro now lasts 3.5 seconds, with an 840 ms reveal and 540 ms exit. The two opening phrases last 3 seconds each, the Scrum call lasts 1.8 seconds, and the release call lasts 1.65 seconds. Intermissions hold for 3.5 seconds. Full-motion loading has a 1.95-second minimum for an initial match and a 900 ms minimum between Scrums; slow resource preparation extends it until the artwork is ready.

Offline combat remains at frame zero until release. Online protocol 4 has separate readiness barriers for introductions and the opening, so the core cannot start while either player is still preparing. Skipping an intro does not skip the opening; a held selection confirm must be released before it can skip. Back cancels safely. Practice/development enter through loading without the full ceremony, and practice Reset stays immediate.

The first-to-two score screen advances automatically between Scrums. `MatchScore` records confirmed outcomes; draws replay the same call. Network preparation uses a fresh generation for each Scrum, including draw replays, so delayed inputs/state checks cannot reach the new rollback session. Both peers verify the prior score before advancing.

`tests/entry_preview.gd` captures `--loading`, `--intro`, `--second`, `--opening`, `--call`, `--final` and `--release` with `--screenshot PATH`. `--tour` records one entrance; `--match-tour` uses an unsaved KO fixture to demonstrate a real 1–1 / Final Down match through the normal presentation flow. Both support Godot's `--write-movie PATH.avi --fixed-fps 60`.
