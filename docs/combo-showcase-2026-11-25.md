# Fight Guild combo showcase — 25 November 2026

Strong routes found by a bounded ordinary-input search, not proof of absolute maximum damage. The defender guards after the first hit. All contacts must remain in one combo. No mid-combo position, health, hitstun, wall damage or tuning edits. Tapper stance is earned through an input prelude; its setup damage is excluded. Anvil’s super example starts with 50% Momentum. Native recording verifies every simulation checksum.

Two examples per fighter, shown at 60 fps and repeated at half speed without interpolating animation frames. Updated Anvil art, magma shield effects and throw depth tracks are included.

| Fighter / example | Damage | Hits | Route |
| --- | ---: | ---: | --- |
| Fillet / midscreen route | 191 | 7 | c.S → 6Hs → 236S → 2K → 236S → 2K → 2S |
| Fillet / corner break | 278 (wall break) | 7 | c.S → 6Hs → 236S → 2K → 6P → 623Hs → 6Hs |
| Smoke / charged drive confirm | 221 | 4 | 5[D] → c.S → 2Hs → 214Hs |
| Smoke / poison sword finish | 204 | 4 | 5[D] → c.S → 2Hs → 214S |
| Shark / hook route + pull | 286 | 9 | 6S → c.S → 6S → 214S → c.S → 6S → f.S → 5Hs → 5D |
| Shark / corner break | 357 (wall break) | 9 | 6S → c.S → 6S → 214S → c.S → 6S → c.S → 6S → 6S |
| Tapper / front stance confirm | 215 | 3 | c.S → f.S → 2Hs |
| Tapper / dempsey stance route | 265 | 6 | st.5Hs → st.5S → st.5S → st.5S → st.5P → st.5K |
| Hammer / drive dash extension | 279 | 4 | 6Hs → 236S → 5D → 6Hs → 214Hs |
| Hammer / corner break | 394 (wall break) | 5 | 6Hs → 236S → 5D → 6Hs → 214Hs → 6Hs |
| Anvil / charge confirm | 153 | 2 | 5Hs → [4]6Hs |
| Anvil / launch into sky foundry | 386 | 2 | 2Hs → 63214Hs |

Conditions: normal hits against 1,000 maximum HP, fresh walls and no preloaded status effects. Tapper’s stance example starts after a real 5D setup at 935 remaining HP; only the following 265 damage counts. Anvil’s charge confirm starts at 0% Momentum, with 30 frames of back charge before the starter. His Sky Foundry example starts at 50%. All other examples start at 0%.

`[D]` means hold the button for the charged version; `[4]6Hs` means charge back then forward + Hs. `st.` marks Dempsey stance. Repeated attacks are separate inputs. Hammer’s 5D is a dash, and Shark’s 5D is a pull, so those actions add no hit by themselves.

The film JSON contains setup inputs, ordinary frame-by-frame inputs, per-contact results and replay checksums. Search limits and target character are recorded per example. These are useful current-build damage routes, not a claim of tournament optimization. Some routes expose repeated-launcher balance opportunities.

## Videos

[Combined showcase](../exports/FightGuild-Combo-Showcase-2026-11-25.mp4) — 3:25, 720p at 60 fps. Fighter sections begin at Fillet 0:00, Smoke 0:35, Shark 1:06, Tapper 1:53, Hammer 2:16 and Anvil 2:52. Each route has its own embedded chapter.

- [Fillet](../exports/FightGuild-fillet-Combos-2026-11-25.mp4)
- [Smoke](../exports/FightGuild-smoke-Combos-2026-11-25.mp4)
- [Shark](../exports/FightGuild-shark-Combos-2026-11-25.mp4)
- [Tapper](../exports/FightGuild-tapper-Combos-2026-11-25.mp4)
- [Hammer](../exports/FightGuild-hammer-Combos-2026-11-25.mp4)
- [Anvil](../exports/FightGuild-anvil-Combos-2026-11-25.mp4)

[Input traces and checksums](../exports/FightGuild-Combo-Routes-2026-11-25.json).

## Reproduce

1. Build the native extension and portable combat core from the same source.
2. Export the native configuration with `godot/tests/export_spacing_fixture.gd` into `build/combo-showcase-current/configuration.bin`.
3. Run `node scripts/search-combo-showcase.mjs`; optionally pass scenario IDs such as `fillet-midscreen` or `anvil-corner`. Use `COMBO_BEAM`, `COMBO_DEPTH`, `COMBO_AIR` and `COMBO_STANCE` to select search limits and setups. The published selection uses beam 24 / depth 10 for Fillet, Smoke and Shark, and beam 24 / depth 9 for `COMBO_STANCE=1 node scripts/search-combo-showcase.mjs tapper-stance`.
4. Run `node scripts/prepare-combo-showcase.mjs`, then `python scripts/capture-combo-showcase.py --quick`.
5. Record using `bash scripts/render-combo-showcase.sh`. A private Xvfb display and ffmpeg are required.

To replay this exact selection without repeating the search, copy `exports/FightGuild-Combo-Routes-2026-11-25.json` to `build/combo-showcase-current/film.json` after building the same native revision, then run steps 4 (capture only) and 5. The recorder checks the source tuning, art hash and every simulation frame.

The browser editor stays frozen; the search helper loads an exported native configuration instead of migrating it through the browser adapter. Recording never changes the moves to force a route to work.
