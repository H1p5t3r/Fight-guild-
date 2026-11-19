# Fillet ground normals — first playable art pass

The eleven selected ground normals now use **92 generated pose keys** in Godot
and the browser Move Workshop: eight keys per move and twelve for c.S. The new
drawings cover windup, contact, follow-through and recovery. Review arrows and
transition smears are absent from the gameplay art.

| Move | Selected motion |
|---|---|
| 5P | A / Elbow Snap |
| 2P | B / Shoulder Slip |
| 5K | A / Heel Drive |
| 2K | B / Ankle Snap |
| c.S | Short LEFT reverse-grip rising cut from the supplied packet |
| f.S | B / Hip-led |
| 5Hs | B / Hip Cross |
| 2S | B / Hip Reap from the second study |
| 2Hs | B / Rear-Leg Coil |
| 6P | B / Rib Slip, with corrected LEFT-short / RIGHT-long arm ownership |
| 6Hs | B / Rib Whip |

The [production directory](../art/characters/fillet-v1/production/ground-v1/README.md)
retains prompts, references and source checksums. All twelve generated PNGs are
preserved unchanged. `scripts/register-fillet-ground.py` derives atlas regions,
transparent gutters, sole pivots, body scale metadata and phase keys. It can
rebuild this metadata from the tracked PNGs when the original generation paths
are unavailable.

Animation keys use the simulation's action clock. Edited timings scale the keys
within windup, active and recovery; hitstop holds the current drawing and saved
state replay restores it. The final recovery drawing remains visible on the
move's last displayed frame. Disabled/contextual geometry previews use the same
phase mapping. Older imported Fillet kits keep their existing art selection.

No move stats, canonical hitboxes, hurtboxes, pushboxes or root-motion keys change.
The shared animation table now supports eight keys per phase and 128 pose slots
per fighter. This accommodates c.S's five active keys and Fillet's 92 drawings.

## Verification

- Native combat regressions, including all 3,576 canonical Fillet geometry
  comparisons, passed after the animation integration.
- `tests/fillet-ground-art.test.mjs` verifies all 92 keys on authored ticks in
  both facing directions, edited timings, real hitstop, replay and legacy imports.
- `tests/workbench-fillet-ground-browser.mjs` verifies the actual browser canvas
  draws all 92 keys from the correct source file and region, plus desktop/mobile
  previews. It writes review captures to `build/fillet-ground-review/`.
- The Godot art catalog validates transparency, image hashes, regions and pose
  counts across all six fighters, now 631 body keys. Source atlas dimensions are
  checked per frame because c.S uses larger cells than the other moves.
- Atlas boundary inspection found no dense body or weapon pixels crossing the
  final registered edges. The native game and both editor delivery formats build.

## Remaining art work

This is a first playable raster pass, not completion of the full Fillet art
package. Exact anatomical/weapon alignment against canonical geometry, support
foot variants and continuous entry/exit animation still need refinement.
Facing uses the existing mirrored renderer; independently drawn reverse views
remain future work. Air normals, specials and paired actions retain their current
art until the user selects their replacement motion directions. Track those
fifteen remaining actions in the [selection log](../art/characters/fillet-v1/review/selection-log.json).
