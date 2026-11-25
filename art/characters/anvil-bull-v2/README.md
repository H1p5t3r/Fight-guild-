# Anvil / approved Bull production art

The user approved the corrected High Clamp reference on 25 November 2026. This pass carries its body, five-digit right hand, closed-jaw grin, narrower stance and inward-facing neutral shield into the native game. The left forearm owns the shield throughout. There is no hammer.

`exposure-plan.json` was written from the current native move data before generation. It preserves gameplay timing and puts the largest strike change between the last startup and first active frame. Successful grabs use the shared capture clock; missed grabs do not show a slam.

All PNGs under `godot/assets/fighters/anvil-bull-v2/` are unchanged image-generator output. `sources.json` records prompts, references, original paths and hashes. Registration changes only metadata, anatomical boxes, pivots, exposure keys and render-only shield masks. No programmatic pixel painting, resampling or warping.

Foundation sheets use three columns and two rows. Attack/reaction sheets use two columns and three rows: each column is load/contact/withdraw or contact/recoil/hold. Recovery sheets read across rows. Actual transparent gutters take precedence over nominal cell boundaries.

Source review exclusions: `slashes` top-right swaps shield ownership and is not used; f.S shares the correct compact c.S load. `kicks` top-left clips the head and is not used; its same-size withdrawn knee becomes the load. The first face-down request was rejected by the image service; the successful source uses `down_prone-floor-study.txt`, a neutral rising exercise. The rejected prompt is retained for the audit trail.

This is native game artwork. The Move Workshop website remains frozen.

## Reproduce the native registration

1. Run `python scripts/register-anvil-bull.py`.
2. Run `python scripts/generate-combat-data.py --native-only` and rebuild the native extension.
3. Run `bash scripts/godot.sh --headless --script tests/anvil_art_test.gd -- --test`.
4. Run `python scripts/capture-anvil-art.py` for the native 60 FPS review.

Registration covers all 26 enabled actions, 173 stat-timed attack exposures, seven paired tracks, movement, guard/hit reactions and both knockdown orientations. The script records measured anatomy and scale; `registration.json` summarizes coverage. Successful command grabs hold their slam through release hitstop/recovery; whiffs never show a lift. The held shield shuffle follows saved travel, so its animation remains consistent after rollback. Ordinary throws and reactions also use the new body rather than the legacy hammer costume.

## Clarity and scale pass — 25 November

The user requested a cleanup before the new combo showcase, consistent visible
size in every fight state, and **magma-orange accents** on weapon swing effects.
The Blacksmiths' guild colour remains grey.

`shield_effects.png` contains horizontal, rising, descending and low pressure
shapes. Eleven shield attacks use these only in their active exposure. The effect
envelope uses that move's actual back/reach/bottom/top values, with no extra
hurtbox. Recovery removes the effect immediately. The first-active snap, held
load and authored gameplay frame counts remain intact.

`iron_turn.png` replaces the awkward raised-hand B throw with a collar catch,
shoulder load and opposite-side release. This atlas is three columns by one row;
the rest of the body atlases retain their original layout. Its corrected spacing
is an image-generator edit, not a pixel manipulation in the registration script.

The original blanket 300px attack/reaction scale made body mass jump relative to
the idle. `HEIGHTS` now records anatomical calibration for all 18 body sources.
Each source retains one scale across its poses; grounded roots use support feet
and airborne roots use the pelvis. Crouches, prone bodies, extended arms, shields,
and effects never determine a fit-to-bounds scale. The same frame scale reaches
native collision art, reaction overlays and paired receiver overlays.

`CombatGrabs` uses the saved pair clock for front/behind ordering, supports the
carried receiver at the source drawing's palm, and releases that attachment over
the last six capture ticks. Iron Turn goes behind Anvil during its shoulder load
and comes forward as it is released. Ordinary throws also bring the receiver
forward at release. Neither player slot, facing, hitstop nor repeated rendering
advances these presentation tracks or changes the combat snapshot.

Inspect `exports/FightGuild-Anvil-Size-Review.png` for a fixed-camera comparison;
reproduce it with `python scripts/capture-anvil-art.py --size-sheet`. The native
review video includes hit, block, whiff, Drive and all three command grabs.

Discarded generation attempts are documented in `cleanup-exploration.json`:
the first effects were monochrome before the orange clarification, the initial
grab edit retained the incorrect shoulder pose, and the first corrected B atlas
had insufficient gutters. Only the final two original PNGs are registered.
