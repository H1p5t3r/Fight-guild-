# Fillet — phase transitions and animation on twos

The user's 2026-11-19 photograph sets the cadence: **a new drawing at every phase
entry, then every second frame within that phase**. This pass expands three
already selected attacks, keeping their choreography and gameplay timings.

| Attack | Original drawings | Expanded drawings | Added |
|---|---:|---:|---:|
| 5P / Elbow Snap | 8 | 12 | 4 |
| 5K / Heel Drive | 8 | 14 | 6 |
| 2S / Hip Reap | 8 | 22 | 14 |

For an attack whose first active frame is `S`, with `A` active frames and `R`
recovery frames, required drawings are at:

- Startup: `1, 3, 5, … < S`.
- Active: `S, S+2, … < S+A`.
- Recovery: `S+A, S+A+2, … < S+A+R`.

Additional approved keys remain in place, so some drawings occupy one frame.
None of these three default clips holds a drawing longer than two action frames.
Hitstop deliberately pauses the action clock. Longer edited timings still scale
the animation by phase and can require more drawings to preserve this cadence.

`baseline.json` preserves the previous clips for the before/after player.
`cadence.json` records the rule. Source records retain exact generation prompts,
references, hashes and scale/root measurements. The five final atlases contain
24 new drawings; original PNG pixels are copied unchanged to
[`fillet-ground-twos`](../../../../../godot/assets/fighters/fillet-ground-twos).
No crossfade, stretched limb, automatic interpolation or smear substitutes for
a new pose.

The first late-recovery sheet for 2S folded forward again; its correction keeps
the return toward guard. A further correction lowers its contact/recovery
in-betweens. The 5K refinement sharpens outlines and cel shadows to match the
surrounding art. Superseded generations remain in `archive/`.

`scripts/calibrate-fillet-inbetweens.py` measures scale against neighboring
approved poses, using one body scale per sheet and planted-foot roots.
`scripts/register-fillet-ground.py` combines these drawings with the original
keys, verifies the cadence and emits the shared Godot/Workshop manifest. Source
move stats, hurtbox/hitbox/pushbox timelines and root motion stay unchanged.

The packaged browser review is `fillet-motion-review.html`, with before/after,
normal/half/quarter speed, facing flip and frame stepping. A self-contained copy
is built as `build/Fillet-Animation-On-Twos.html`. The review's updated animation
keys and root positions are sampled from the compiled combat simulation.
