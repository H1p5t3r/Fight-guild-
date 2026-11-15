# Sprite collision and starter move rules

Combat runs at 60 fixed ticks per second. **No attack may start faster than 5 frames. Weapons do not extend hurtboxes.** These rules apply to the default kits, Move editor, imported tuning and native/WebAssembly core APIs.

## Three separate shapes

- **Hurtboxes (cyan):** head, torso, arms and legs traced against every existing drawing: 12 active/support, 6 windup and 6 block poses for each of the six fighters. Equipment worn on the body is included with the body; projecting blades, shafts, shields, hair, loose cloth and smears add no vulnerable area. A weapon overlapping the underlying body does not make that body invulnerable.
- **Pushboxes (green):** stable body spacing per fighter, with standing, crouching and tucked-jump heights. These do not expand with a weapon or attacking limb. Movement sweeps retain left/right order while vertically overlapping, so walking, dashing and advancing attacks cannot tunnel through an opponent. Wall-blocked separation transfers to the other fighter. Vertical clearance permits jump-overs; landing resolves any remaining overlap.
- **Hitboxes (orange):** one preliminary damaging rectangle per current button image, following its limb, weapon or visible strike arc. Hitboxes exist only during active frames and hit any opposing body hurtbox. Touching only a weapon outside the body does not connect. Boxes mirror around the same foot/root pivot as the art.

All 132 current move slots have startup, active/recovery duration, damage, hitstun, blockstun, hitstop, pushback and strike geometry. [Move stats](move-stats.md) lists the values and first-active-frame block advantage. Kits remain provisional: crouching, command, special and air variants currently share button artwork and its strike rectangle. Dedicated per-move animation/geometry is backlog work. Gatling routes and the existing special-cancel rules remain in force.

Startup counts the first active tick: a 5f move has four windup ticks and can first connect on tick five. The core selects the visual pose as well as collision geometry; hitstop freezes the attack's age. Counter hits and block reactions still depend on actual contact timing.

## Review and tune

In **Development**, enable **Hitboxes**, pause and use **+1 frame** to inspect live collision. **Sprite review** covers attack pairs, all block reactions, ready, walk, jump, hurt, crouch and the legacy guard pose. Toggle collision or left-facing display there. The active preview uses the current edited basic move hitbox and displays its frame data.

The Move editor exposes **Hitbox back**, **Hitbox front**, **Bottom** and **Height** in world pixels. Negative back offsets can extend behind the root. Startup has a hard 5f minimum; importing a faster value rejects the entire edit without changing the live move set. Schema-1 through schema-4 files migrate to schema 5, preserving their edits and previous 12px hitbox origin. Existing saves retain their old tuning/ranges; use **Restore default move set** to try the new starter kits.

## Authoring and reproducibility

`godot/data/fighter_collision.json` owns body rectangles in atlas-region pixel coordinates and push dimensions in hundredths of a world pixel. Each rectangle is `[left, top, right, bottom]` in image space. Edit the body rectangles independently from the `strike` rectangle; never derive hurtboxes from the full alpha silhouette, because it contains weapons and effects.

`godot/data/starter_moves.json` owns the initial move stats. `hitPose` selects the corresponding active-image strike rectangle. `godot/assets/fighters/manifest.json` supplies the identical region pivot and 150px body-height normalization used by the renderer.

Run `python scripts/generate-combat-data.py` after changing these sources. It regenerates `core/combat_data.h` and the stats reference using integer outward rounding. Rebuild the native extensions and WASM core afterward. `--check` rejects stale generated files in both test paths. Runtime collision uses only integer math, with no image sampling or engine physics, and the online fingerprint includes the compiled collision hash as well as move tuning.

For a native contact sheet, run `bash scripts/godot.sh --script tests/collision_review.gd -- --character 0 --screenshot /absolute/path.png` with a display. Character indices 0–5 follow Anvil, Hammer, Smoke, Tapper, Shark and Fillet. This renders all 24 poses with the compiled geometry for review after art changes.
