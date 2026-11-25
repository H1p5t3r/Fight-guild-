# Super-freeze cut-in

The native game has a reusable cut-in renderer and a local training/development
preview. **No super attacks, commands, damage, invulnerability, cancels or new
Momentum spending have been added.** The move-editor website remains frozen.

In Training or Development, choose **Super cut-in → Preview Player 1 / Player 2**.
Keyboard shortcuts are **F8** and **Shift+F8**. The preview holds the current
match for 54 presentation ticks (0.9 seconds at 60 Hz), then resumes. It also works
while the training Pause control is on and leaves that control's state intact.
Normal local-versus and online matches cannot trigger the test freeze.

## Reference and timing

The supplied `videoplayback.mp4` is a 640×360, 29.97 fps, 3.576-second clip.
Its useful action is approximately 0.4–1.4 seconds; the rest is blank lead/tail.
The reference opens a narrow white tear, exposes a face inside an angled black
and colored band, holds briefly, then tears/slides away. The green background is
a compositing matte, not part of the intended match treatment.

The native version rips a **strip out of the frozen match image** to reveal the
face and guild color beneath it. The strip has fixed ragged upper and lower edges;
the surrounding screen stays in place, with no stretching, separation or dimming.
The tear travels horizontally along the fighter's facing. Only the extracted
strip curls at the moving edge: its printed side carries the original match image,
turning over to expose a paper backing. The portrait stays fixed at its original
proportions as the opening passes over it.

On exit, the strip returns **in the opposite direction**: a left-to-right rip seals
right-to-left, and the mirrored version does the reverse. The curled edge unrolls
and short fibers reconnect at this returning front. Restored regions show the
original pixels immediately; no final-frame seam remains. Top/bottom edges never
slide together. The face and tear direction follow actual facing while the stage
keeps its orientation. The demo's 54-tick plan is:

| Presentation ticks | Treatment |
| --- | --- |
| 0–13 | A traveling rip removes a fixed-height strip; the extracted edge curls |
| 14–32 | Fixed face revealed through the missing strip |
| 33–53 | The strip unrolls and knits back in the reverse direction |
| 54 | Cut-in removed; combat resumes on the following physics tick |

Reduced Motion uses the same freeze duration with a stationary cut-out fade and
no traveling rip, curl or fibers. Menu transition speed does not lengthen this
combat presentation.

## Face artwork: awaiting selection

The [four-panel review](../art/ui/super-freeze-v1/face-options.png) shows Fillet and
Shark in two directions: **A / Coiled** and **B / Breakthrough**. Both show the face
and leading shoulder loaded forward before a huge attack. The existing user
process is options → selection → production; neither option has been approved
yet. New art is kept outside runtime assets until selection, then the chosen
direction can be produced consistently for all six fighters.

The current in-match preview uses existing approved portrait crops. It does not
claim those are the new forward-driving faces. The source generation, prompt,
references and checksums are in [generation.json](../art/ui/super-freeze-v1/generation.json).

`godot/assets/ui/super-freeze/portraits.json` is the replacement point for approved
portraits. Each fighter key accepts `approved: true`, a `file` relative to that
directory, and a `[x, y, width, height]` atlas `region`. Author wide face strips to
match the approximately 4:1 band; keep the eyes, mouth and chin inside its jagged
safe area, hair trailing backward. The renderer never substitutes the reference
video's character or lettering.

## Integration boundary

`SuperFreeze.present(character, facing, elapsed_ticks, total_ticks)` renders a
specific frame. `clear()` removes it. It has no autonomous timer, combat model
reference or gameplay mutations. Re-presenting an earlier tick produces the same
composition, suitable for a future saved freeze clock and rollback resimulation.
An explicit `BackBufferCopy` precedes the screen-tear shader, so each draw samples
the clean arena rather than an earlier cut-in. UV mapping respects the arena's
rectangle inside the training layout; surrounding controls are unaffected.

When supers are designed, their deterministic core activation event must own the
actor, duration and elapsed freeze ticks, with the same state on both peers.
Connect that state to `main.super_freeze.present(...)` and clear it when the freeze
ends or is rolled back. **Do not use the local preview's simulation gate online.**
This change does not implement that future core super event or freeze state.

The local preview skips model stepping while advancing only the cut-in clock.
That preserves positions, velocities, attack age, hitstop, projectiles, stun,
status durations, round timer, health and Momentum byte-for-byte. It gates input
and requires release on exit. Round reset, replay, leaving play, opening the
frame lab and focus loss clear the preview. Opening pause uses the pre-cut-in
background, so its frozen tableau cannot retain a stray cut-in image.

## Verification and review

- `bash scripts/godot.sh --headless --script tests/super_freeze_test.gd -- --test`
  checks all six fighters, both players/facings, live attacks, a live projectile,
  recovery, duration boundaries, input gates, interruption, reduced motion,
  reverse closure direction and simulation/configuration preservation.
- `python scripts/capture-super-freeze-review.py` records the native renderer at
  60 fps; `--stills` saves hold, opening and closure checkpoints. The first and
  last frames are compared against the intact match for all six fighters and
  Reduced Motion. Intermediate pixel checks verify that the upper/lower screen
  remains unchanged and that the far end is restored first during closure, in
  both facings. `--stills --inset --size 1920x1080 --display :97` also checks
  that a smaller arena's effect leaves the surrounding interface untouched.
- [Current native motion preview](../exports/FightGuild-Super-Freeze-Review.mp4)
  with [opening](../exports/FightGuild-Super-Freeze-Ripping.png),
  [knitting closure](../exports/FightGuild-Super-Freeze-Knitting.png) and
  [Fillet hold](../exports/FightGuild-Super-Freeze-Fillet.png) use the approved
  existing portrait fallback pending the new face-art selection.
