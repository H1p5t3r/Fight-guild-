# Native guild-ink menus

Fight Guild's native front end uses the requested Persona 5-inspired print language: black silhouettes, paper-white type, angled selections and sweeping ink cuts. The dominant color comes from the game's existing guild palette. Character select lets both guilds occupy and tear across the entire screen.

## Visible behavior

- Home features an approved combat stance as a three-tone cutout and an oversized silhouette. The six fighter buttons change the featured guild, illustration and dominant color. This is a menu preference for the current session; it does not change the match selection.
- Versus, local sides, online connection, pause, results, Controls and Sound share the ink treatment. The native Combat Lab retains its functional editing layout.
- Side-select colors follow the current matchup. Character select retains P1/P2 ownership, mirror picks and independent simplified-input toggles.
- Character select has no portrait panels. Coral, teal and the other guild colors cross an irregular central tear. Switching the active player shifts the boundary toward the opponent; choosing a fighter sends a short color surge into the other field. The roster stays above the artwork and the controls stay still. A mirror match uses a darker shade of the same guild for P2.
- Pause displays the actual matchup; results feature the winner and their guild. Canceling a new character selection restores the paused matchup's palette.
- The new silhouettes use the existing registered combat artwork. Fillet uses her ready stance; Shark, Smoke and Hammer use their idle loops; Tapper uses his ready pose; Anvil falls back to his available windup pose. No fighter textures, attack animations, hitboxes or simulation data are modified.

| Guild | Dominant color |
| --- | --- |
| Blacksmiths | `#dfb36c` brass |
| Masons | `#99b0c2` slate |
| Alchemists | `#a8ba76` sage |
| Brewers | `#d99a59` amber |
| Fishermen | `#5ab5b5` teal |
| Butchers | `#d67570` coral |

The palette reads the same `FighterSelectPortrait.COLORS` values already used by the game. The shaders add black and paper-white without rewriting the sprites.

## Motion

The existing slower menu pacing is retained. A normal page cut lasts 1.02 seconds, with paper, guild-color and black shapes crossing the view together. Text strips ease into focus; portraits enter across the cuts. Pause/resume and match entry use a separate overlay above the gameplay layer. These clocks never enter rollback state.

A second input during an ink wipe changes the destination under the current wipe instead of restarting its coverage. Back navigation reverses a new wipe. Character-select surges can be interrupted and settle on the latest active player.

Reduced Motion keeps brief fades, holds idle art, and disables wipes, portrait travel and animated guild surges. Keyboard, mouse and controller actions remain real Godot controls with their original accessible labels and focus behavior. Both horizontal and vertical directions work for the two Versus choices.

## Screenshot audit and result

Fresh native baseline captures were taken before implementation at `build/menu-redesign/before/`, covering home, versus, sides, fighters, combat, pause, results, online and controls. This was a visual/code review, not a usability study.

| Flow step | Observed issue in the baseline | Implemented response |
| --- | --- | --- |
| 1. Home → Versus | Beveled stock buttons and a subdued teal gradient did not echo the large oblique combat lettering. The hero used older attack poses. | Flat ink strips, the combat display font, large silhouettes and current combat stances. |
| 2. Side → Fighter select | Separate bordered regions contained each guild's color. The first redesign still read as two portrait cards. | A full-screen color clash, oversized unboxed fighters, irregular overlapping cuts and a movable dominance boundary. |
| 3. Character select → Match | Small sliding fades carried little of the graphic identity into gameplay. | Layered directional ink wipes across both menu pages and the menu/gameplay boundary. |
| 4. Pause → Results | Narrow utility lists sat in largely empty screens with little indication of the current matchup. | The actual fighters occupy the menu; the winner determines the results palette. |
| 5. Controls / Online | The separate warm Settings kit introduced another unrelated visual system. | Guild-accented black/paper controls and an online fighter poster, retaining readable conventional forms. |

Review artifacts:

- [Menu animation reel](../exports/FightGuild-Ink-Menu-Tour.mp4)
- [Main menu](../exports/FightGuild-Ink-Main-Menu.png)
- [Fishermen palette](../exports/FightGuild-Ink-Fishermen.png)
- [Alchemists palette](../exports/FightGuild-Ink-Alchemists.png)
- [Unboxed character select](../exports/FightGuild-Ink-Fighter-Select.png)
- [Pause](../exports/FightGuild-Ink-Pause.png)
- [Results](../exports/FightGuild-Ink-Results.png)

The reel records actual native UI tweens at 60 fps. It enters a fixture match directly to keep the reel focused on menus; the normal loading and character-intro sequence remains in the game.

## Verification and reproduction

```sh
python scripts/capture-ink-menu-review.py
python scripts/capture-ink-menu-review.py --stills --size 1920x1080
bash scripts/godot.sh --headless --script tests/ink_menu_review.gd -- --test
bash scripts/godot.sh --headless --script tests/input_menu_test.gd -- --test
bash scripts/godot.sh --headless --script tests/ui_smoke.gd -- --test
```

The focused review passes 137 checks at both 1280×720 and 1920×1080. It checks all six guild palettes, menu action bounds, active-player dominance, mirror selection, real pause/winner art, selection cancellation, reduced motion, rapid reversal and unchanged combat state. The existing native UI suite and all 31 input-menu checks pass. They cover local/online menu navigation, remapping, hotplug, held-input isolation, match entry and pause/resume. The capture runner rejects script errors even if Godot exits with code zero.

The rendered review uses Linux/Godot 4.6.3 with software OpenGL and synthetic controller events. Physical-controller and console visual checks remain separate. The browser Move Workshop and its publication workflow are unchanged.
