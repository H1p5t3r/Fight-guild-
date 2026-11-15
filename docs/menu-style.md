# Guild Ball menu style in Fight Guild

Source: the user-supplied `guildball-menu-reference-pack-2026-11-15.zip`, taken from Guild Ball's `development/menu-polish` at `32f73150944dfa6b1e5b7b82c3d666c02644e3dc`. Every supplied checksum was verified before import. Archive SHA-256: `94ba49536ee82d856a98b4363092de1f27448a109de42bd8c86d5f21c050386b`.

## Shared owners and assets

- `godot/scripts/guild_theme.gd` owns the normal and Settings themes. Normal menus, fighter selection, the online lobby, pause/results, sprite review and the development editor use charcoal / blue / brass. Controls owns a separate cream / warm-grey / burnt-orange theme.
- `godot/Content/UI/Stock` contains the supplied PNG surfaces, Godot style resources and manifest unchanged. Button slices remain 12 logical pixels with 6/3 content padding. Panel margins and asymmetric corners retain the supplied resource measurements. Semantic actions use Essential, Primary, Secondary and Danger variations; focus remains an independent outline.
- `godot/Content/UI/Settings` contains the supplied warm SVG surfaces. They are scoped to Controls; they do not recolor ordinary menus. The reference pack also includes surfaces for future settings controls, but this pass adds no Display/Sound settings or control remapping.
- `godot/Content/Fonts` contains Barlow Condensed regular/semibold and the supplied Phosphor font. Font licenses are retained there and in the packaged `licenses/` directory. Menu headings use semibold; body and supporting text use regular. The existing large combat-feedback numerals keep their display font.
- Editable stock masters live in `art/ui-stock/svg`. New small checkbox glyphs live in `godot/assets/ui/icons`; they use the stock palette and remain separate from labels and behavior.
- `references/menu-style` retains the handoff, home, Controls and component-state reference captures. Other projects' sample names, data and text were not imported into game behavior.

## Layout and behavior

The home screen adapts the reference's palette, type and button surfaces to a fighting-game title screen: a large Fight Guild wordmark, an Anvil/Shark face-off and direct Versus, Training and Development choices. `home_faceoff.gd` reads the existing windup atlases for its decorative fighter artwork; it never starts or advances the combat simulation. Angled planes, a VS divider and guild-colored nameplates frame the pair. The six-fighter roster appears below the artwork, while mode help follows mouse hover or keyboard/controller focus. The unused runtime copies of the earlier concept-sheet cards were removed; original concept art remains under `art/characters`.

`GameMenus` uses grouped compact panels with a fixed heading/navigation area. Fighter select keeps its start action outside the scrolling body. `controls_guide.gd` keeps its heading, scheme tabs and 40-pixel Close action fixed while bindings scroll. Closing it restores focus to the opening control. Native buttons, checkboxes, option pickers, editable fields and keyboard/controller actions retain their behavior.

The reference's newspaper drawing/page-turn films were not supplied. `guild_backdrop.gd` supplies a quiet, static teal/brass gradient based on the reference home screen; there is no fabricated film playback or motion setting. Replace this still layer when the actual background films become available. Decorative layers ignore pointer input.

The project uses a 1280×720 logical canvas and scales to 1920×1080. The development workbench and gatling reference now sit below the editor's other tools, inside its scroll area, leaving the arena and practice controls usable at 720p.

## Review

On a machine with a rendering display:

```bash
bash scripts/godot.sh --resolution 1280x720 --script tests/ui_smoke.gd -- --test --home --screenshot /absolute/path/home-720.png
bash scripts/godot.sh --resolution 1920x1080 --script tests/ui_smoke.gd -- --test --controls --screenshot /absolute/path/controls-1080.png
bash scripts/godot.sh --resolution 1280x720 --script tests/style_review.gd -- --screenshot /absolute/path/surface-states.png
```

The surface fixture shows normal, hover, pressed, focus and disabled artwork together. Actual input behavior is exercised by the menu suite: entry/back paths, keyboard/controller navigation, simplified controls, pause/rematch, input isolation, Controls tabs/fixed footer/focus return, and ENet handshake/cancellation/disconnect recovery. The host-port check also prevents delayed SpinBox text from replacing the selected value.
