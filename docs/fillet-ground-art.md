# Fillet ground normals — first playable art pass

The original eleven ground normals used **92 generated pose keys** in Godot
and the browser Move Workshop: eight keys per move and twelve for c.S. The new
drawings cover windup, contact, follow-through and recovery. Review arrows and
automatic limb smears are absent from the gameplay art. The follow-up 2S pass
adds an explicitly requested generated knife arc: its bright edge reaches the
live hitbox at 116 px on action frames 12–14 and 108 px on frame 15, then fades
during recovery. The effect carries no hurtbox.

The user approved the [attack-timing standard](attack-animation-standard.md)
and its application to the full kit. The [whole-kit pass](../art/characters/fillet-v1/production/kit-timing/README.md)
now covers **26 actions and five successful capture tracks**, with 270 registered
action/effect/capture cues. The last startup pose stays loaded; the first active
frame receives the strongest attacking change. The 2S pre-contact drawing is
omitted, leaving six consistent body drawings and its approved knife arc.

`fillet-motion-review.html` starts on 2S at game speed and includes every attack,
actual contact freeze, movement, capture clocks, landing interruptions and frame
stepping. Earlier on-twos production files remain archived for comparison.

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
The shared table supports sixteen exposure keys per phase and 320 registered
pose slots per fighter. Captures have separate saved-clock pose tracks.

## Verification

- Native Fillet runtime checks and all 3,576 canonical geometry comparisons.
- `tests/fillet-ground-art.test.mjs`: all 26 attacks, edited phase timing, first
  active redraw, actual hitstop, landing, paired capture clocks and rollback.
- `tests/workbench-fillet-ground-browser.mjs`: all 234 action/effect cues in the
  editor's geometry inspection, with mobile and desktop rendering.
- `tests/workbench-fillet-motion-review-browser.mjs`: every real contact example,
  the five successful captures, nine-frame sweep freeze, landing and mobile UI.
- Godot validates PNG provenance, alpha, atlas regions and effect transforms in
  both facings across the 809 body/cue entries in the six-character catalog.

See the whole-kit production README for remaining raster-art limitations.
