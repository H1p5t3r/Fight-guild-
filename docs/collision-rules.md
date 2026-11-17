# Sprite collision and starter move rules

Combat runs at 60 fixed ticks per second. **No attack may start faster than 5 frames. Weapons do not extend hurtboxes.** These rules apply to the default kits, Move editor, imported tuning and native/WebAssembly core APIs.

## Three separate shapes

- **Hurtboxes (cyan):** **at most four per pose**. Three required boxes cover the legs, torso and arms together, and head. A fourth is reserved for an extended limb or a complex pose, such as a kicking leg or raised arms. All 160 drawings follow this grouping. Equipment worn on the body is included with the body; projecting blades, shafts, shields, hair, loose cloth and smears add no vulnerable area. A weapon overlapping the underlying body does not make that body invulnerable. These are broad combat regions, so a leg box can also cover the gap between the legs.
- **Pushboxes (green):** stable body spacing per fighter, with standing, crouching and tucked-jump heights. These do not expand with a weapon or attacking limb. Movement sweeps retain left/right order while vertically overlapping, so walking, dashing and advancing attacks cannot tunnel through an opponent. Wall-blocked separation transfers to the other fighter. Vertical clearance permits jump-overs; landing resolves any remaining overlap.
- **Hitboxes (orange):** a damaging rectangle for ordinary strikes, or eight narrow moving rectangles along a hook spear, following its limb, weapon or visible strike arc. Hitboxes exist only during active frames and hit any opposing body hurtbox. Touching only a weapon outside the body does not connect. Boxes mirror around the same foot/root pivot as the art.

All 192 move slots (157 enabled) have startup, active/recovery duration, damage, hitstun, blockstun, hitstop, pushback and strike geometry. [Move stats](move-stats.md) lists the values and first-active-frame block advantage. Kits remain provisional: variants without signature art share button artwork and its strike rectangle. Per-move hurtbox profiles can override windup, active and recovery independently; dedicated animation and geometry changes within a phase remain backlog work. Gatling routes and the existing special-cancel rules remain in force.

Startup counts the first active tick: a 5f move has four windup ticks and can first connect on tick five. The core selects the visual pose as well as collision geometry; hitstop freezes the attack's age. Counter hits and block reactions still depend on actual contact timing.

## Review and tune

The browser [Move Workshop](move-workshop.md) now has a **Hurtboxes** tab. Enable a custom phase, then move/resize its body regions using numeric fields or blue canvas handles. JSON stores these as `move.hurtboxes`, with optional `windup`, `active` and `recovery` profiles. Each has required `legs`, `torsoArms`, `head` and an optional `extension`, expressed as `[left, bottom, right, top]` in integer hundredths of game pixels relative to the fighter. Omitted phases inherit compiled sprite geometry. Editing a move never changes another attack sharing its artwork. Schema-13 Godot imports and saves these profiles; they drive real collision checks, overlays and compatibility fingerprints. Older saves retain inherited poses. Pushboxes remain independent.

In **Development**, enable **Hitboxes**, pause and use **+1 frame** to inspect live collision. **Sprite review** covers basic/signature attack pairs, all block reactions, ready, walk, jump, hurt, crouch and the legacy guard pose. Toggle collision or left-facing display there. Each caption shows its hurtbox count out of four. The active preview uses the current edited basic move hitbox and displays its frame data.

The Move editor exposes **Hitbox back**, **Hitbox front**, **Bottom** and **Height** in world pixels. Negative back offsets can extend behind the root. Startup has a hard 5f minimum; importing a faster value rejects the entire edit without changing the live move set. Schema-1 through schema-9 files migrate to schema 10, preserving edits; see the current combat-tuning migration rules. Existing saves retain their old tuning/ranges; use **Restore default move set** to try the new starter kits.

## Authoring and reproducibility

`godot/data/fighter_collision.json` (authoring schema 2) owns body rectangles in atlas-region pixel coordinates and push dimensions in hundredths of a world pixel. Each pose's `hurt` object has required `legs`, `torsoArms` and `head` rectangles, and at most one optional `extension`. Describe that fourth region in `extensionFor`. Each rectangle is `[left, top, right, bottom]` in image space. The compiler rejects extra or missing regions; native storage also has a hard four-box capacity. Rectangles always compile in legs / torso-and-arms / head / extension order. Edit body rectangles independently from the `strike` rectangle; never derive hurtboxes from the full alpha silhouette, because it contains weapons and effects. Saved move tuning uses the updated body geometry automatically.

`godot/data/starter_moves.json` owns the initial move stats. `hitPose` selects the shared button strike rectangle; `artPose` selects a dedicated signature pose. Diagonal hooks use authored hand/range/thickness values and eight moving spear segments; their tether is harmless. `godot/assets/fighters/manifest.json` supplies the identical region pivot and 150px body-height normalization used by the renderer.

Run `python scripts/generate-combat-data.py` after changing these sources. It regenerates `core/combat_data.h` and the stats reference using integer outward rounding. Rebuild the native extensions and WASM core afterward. `--check` rejects stale generated files in both test paths. Runtime collision uses only integer math, with no image sampling or engine physics, and the online fingerprint includes the compiled collision hash as well as move tuning.

For a native contact sheet, run `bash scripts/godot.sh --script tests/collision_review.gd -- --character 0 --screenshot /absolute/path.png` with a display. Character indices 0–5 follow Anvil, Hammer, Smoke, Tapper, Shark and Fillet. This renders the original 24 poses with compiled geometry. `tests/signature_review.gd` renders the additional eight poses; add `--shark` for Shark, `--mirror` for left facing, or `--clean` to hide boxes.

Fillet and Shark now use 64 v2 body fits with updated atlas roots and strike regions. All push dimensions remain stable; tucked-jump art uses the standing foot/root reference with the tucked soles 50px above it, preserving jump-over clearance. Both facings use the same compiled rectangles. The original v1 art and geometry are archived together for comparison.

## Wallboxes

Two solid half-spaces bound x=0 and x=1000px at all playable heights; their debug rectangles extend beyond every camera edge. A swept pushbox collision during hitstun removes the magnitude of horizontal velocity from the contacted wall's hidden health, then consumes that velocity and remaining travel. Depletion and splat require separate impacts. Both fighters share each wall's pool. Blocks and voluntary movement cannot damage walls. Purple WALL overlays use `boxes(-1, WallBox)` from the same native simulation.

## Timed attack hitboxes

Schema 14 adds optional active-frame keys to each move. A key can inherit the
ordinary shape, hold up to four custom attack rectangles, or create a gap with
no hitboxes. Each key holds until the next; unused keys beyond Active stay saved.
These attack boxes are separate from the maximum four body hurtboxes per pose.
Weapon reach still adds no body hurtboxes.

Multiple boxes and keys share one contact by default. Enabling multiple hits
allows separate hit numbers 1–32, consumed once each per execution on hit or
block. Overlapping boxes with the same number cannot stack hits. The consumed
mask rolls back with the fighter. Throws continue using their range resolver.


Per-move vulnerability switches can disable any of those four regions during windup, active or recovery without deleting their fitted coordinates. Universal 6P starts with only legs vulnerable during windup/active and full coverage in recovery. Disabled regions do not collide with melee or projectile hits; pushboxes and throw eligibility remain independent. See the Move Workshop’s Regions that can be hit controls.
