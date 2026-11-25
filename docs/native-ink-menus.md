# Native guild-ink menus

Fight Guild's native front end uses the requested Persona 5-inspired print language: black silhouettes, paper-white type, angled selections and a continuous ink-painted menu space. The dominant color comes from the game's existing guild palette. Character select lets both guilds occupy and tear across the entire screen.

## Visible behavior

- Home features an approved combat stance as a three-tone cutout and an oversized silhouette. The six fighter buttons change the featured guild, illustration and dominant color. This is a menu preference for the current session; it does not change the match selection.
- Versus, local sides, online connection, pause, results, Controls and Sound share the ink treatment. The native Combat Lab retains its functional editing layout.
- Side-select colors follow the current matchup. Character select retains P1/P2 ownership, mirror picks and independent simplified-input toggles.
- Character select has no portrait panels. Banana cream, teal and the other guild colors cross an irregular central tear. Switching the active player shifts the boundary toward the opponent; choosing a fighter sends a short color surge into the other field. The roster stays above the artwork and the controls stay still. A mirror match uses a darker shade of the same guild for P2.
- Pause freezes the actual displayed fight: both fighters keep their attack/reaction/grab textures, camera positions, facing, scale and foreground order. Bodies fill with their own guild color, weapons turn white, and black outlines plus an offset ink shadow separate them from the dimmed arena. Angled command strips radiate around the combined visible bounds of both fighters, with guild-colored ink rays. The group focus ignores nearly transparent atlas padding. Results feature the winner and their guild. Canceling character selection restores the frozen matchup.
- Front-end posters use the existing registered combat artwork. Fillet uses her ready stance; Shark, Smoke and Hammer use their idle loops; Tapper uses his ready pose; Anvil falls back to his available windup pose. No fighter textures, attack animations, hitboxes or simulation data are modified.

| Guild | Dominant color |
| --- | --- |
| Blacksmiths | `#aeb4bc` steel grey |
| Masons | `#99b0c2` slate |
| Alchemists | `#a8ba76` sage |
| Brewers | `#d99a59` amber |
| Fishermen | `#5ab5b5` teal |
| Butchers | `#f5e8a6` banana cream |

Blacksmiths and Butchers use the user-corrected 2026-11-25 colors throughout native menus, pause silhouettes and health bars. The palette reads the same `FighterSelectPortrait.COLORS` values already used by the game. The shaders add black and paper-white without rewriting the sprites.

## Motion

The existing slower pacing is retained. All pages have fixed positions in a shared two-dimensional space. One camera moves the outgoing and incoming content together; halftone dots and long paper/ink diagonals move more slowly behind them. The background stays visible throughout. Guild colors blend as the camera travels, and character-select color clashes grow into that same field.

Navigation takes roughly 1.1–1.3 seconds, with cubic easing. Reversing during travel starts from the current camera position and retraces the same route. There is no full-screen wipe. Reduced Motion uses brief fades with no camera travel or animated guild surges.

Pause captures the last rendered viewport and copies the actual visible Sprite2D textures/transforms after locomotion, hit reactions and paired throws have selected their art. The menu enters from all four screen edges: upper/lower diagonal strips, commands from the left and right, a title from above and status from below. Staggered cubic easing settles them around the frozen pair; resume retracts them as the ink treatment clears before live combat continues. Strips stay within the viewport even when the pair is near a corner. Reduced Motion keeps their final positions and uses a brief fade. Offline simulation remains stopped. An online match continues to simulate while the menu's picture stays frozen, with the existing online-play notice. These visual clocks never enter rollback state.

Keyboard, mouse and controller actions remain native Godot controls. Up/down follows each radial command column, and left/right crosses to the corresponding command on the other side. Hidden local-only actions are skipped online. Horizontal and vertical directions both work on the two Versus choices. Held-input suppression is retained through transitions.

### Weapon material regions

`godot/assets/fighters/pause-weapon-regions.json` provides vector weapon masks keyed by source atlas path and region, independently of hurtboxes. Current combat stances for all six fighters have explicit material treatment; Smoke has no physical weapon. The masks also cover Hammer's entry/dash sheet and Fillet's first-active 5Hs drawing. Detached hooks and weapon-trail layers render white. Faces, pale hair, cloth and armor stay guild-colored.

Older flattened attack, movement and reaction sheets without authored material regions use a conservative neutral-metal fallback with protected head/torso areas and isolated-highlight rejection. It can miss dark/wooden weapon sections or misclassify exposed pale details. Complete material masks for those older sheets remain an art-pipeline task; the freeze, registration and menu behavior work for all poses. New art should export a body/weapon matte or registered weapon polygons alongside the atlas. Do not derive these masks from active hurtboxes: invulnerability must never change pause coloring.

## Screenshot audit and result

Fresh native baseline captures were taken before implementation at `build/menu-redesign/before/`, covering home, versus, sides, fighters, combat, pause, results, online and controls. This was a visual/code review, not a usability study.

| Flow step | Observed issue in the baseline | Implemented response |
| --- | --- | --- |
| 1. Home → Versus | Beveled stock buttons and a subdued teal gradient did not echo the large oblique combat lettering. The hero used older attack poses. | Flat ink strips, the combat display font, large silhouettes and current combat stances. |
| 2. Side → Fighter select | Separate bordered regions contained each guild's color. The first redesign still read as two portrait cards. | A full-screen color clash, oversized unboxed fighters, irregular overlapping cuts and a movable dominance boundary. |
| 3. Navigation | Wipes hid the route between disconnected pages. | A shared camera and continuous parallax landmarks expose the path and reverse without snapping. |
| 4. Pause → Results | Pause replaced the fight with a new idle poster. | The displayed fight freezes into guild/white silhouettes at its actual positions; results retain the winner treatment. |
| 5. Controls / Online | The separate warm Settings kit introduced another unrelated visual system. | Guild-accented black/paper controls and an online fighter poster, retaining readable conventional forms. |

Review artifacts:

- [Menu animation reel](../exports/FightGuild-Ink-Menu-Tour.mp4)
- [Main menu](../exports/FightGuild-Ink-Main-Menu.png)
- [Fishermen palette](../exports/FightGuild-Ink-Fishermen.png)
- [Alchemists palette](../exports/FightGuild-Ink-Alchemists.png)
- [Unboxed character select](../exports/FightGuild-Ink-Fighter-Select.png)
- [Pause](../exports/FightGuild-Ink-Pause.png)
- [Paused active attack](../exports/FightGuild-Ink-Pause-Attack.png)
- [Blacksmiths pause treatment](../exports/FightGuild-Ink-Pause-Blacksmiths.png)
- [Results](../exports/FightGuild-Ink-Results.png)

The reel records actual native UI tweens at 60 fps, forward/back travel, idle pause and first-active attack pause/resume. It enters a fixture match directly to keep the reel focused on menus; the normal loading and character-intro sequence remains in the game.

## Verification and reproduction

```sh
python scripts/capture-ink-menu-review.py
python scripts/capture-ink-menu-review.py --stills --size 1920x1080
bash scripts/godot.sh --headless --script tests/ink_menu_review.gd -- --test
bash scripts/godot.sh --headless --script tests/pause_tableau_test.gd -- --test
bash scripts/godot.sh --headless --script tests/input_menu_test.gd -- --test
bash scripts/godot.sh --headless --script tests/ui_smoke.gd -- --test
```

The rendered review passes at both 1280×720 and 1920×1080. It checks all six guild palettes, menu action bounds, active-player dominance, mirror selection, pause/winner art, selection cancellation, reduced motion, interrupted camera travel and unchanged combat state. Rendered pixel probes verify that Fillet's hair and pale shirt take her guild color while her knife stays white. The 410-check pause suite covers actual texture/pivot/transform preservation and frozen copies while live simulation advances, across all six fighters, mirrored attacks, airborne and knockdown poses, paired throws and a detached hook. The rendered menu checks also cover pair anchoring, corner-safe command bounds, arrivals beyond screen borders and Reduced Motion staying in place. The native UI suite and 31 input-menu checks cover local/online navigation, hotplug, held-input isolation, match entry and pause/resume. The capture runner rejects script errors even if Godot exits with code zero.

The rendered review uses Linux/Godot 4.6.3 with software OpenGL and synthetic controller events. Physical-controller and console visual checks remain separate. The browser Move Workshop and its publication workflow are unchanged.
