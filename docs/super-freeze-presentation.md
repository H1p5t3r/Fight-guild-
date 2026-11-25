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

The native version uses an original jagged band, paper-white rim, black shadow,
sparse fragments and the acting fighter's guild palette. It leaves the match
visible below a dark tint. The whole composition mirrors using actual facing,
not the player's starting side. The demo's 54-tick plan is:

| Presentation ticks | Treatment |
| --- | --- |
| 0–8 | Thin tear, fast entrance, aperture opens to the face |
| 9–41 | Stable face hold over the frozen match |
| 42–53 | Accelerating exit and trailing fragments |
| 54 | Cut-in removed; combat resumes on the following physics tick |

Reduced Motion uses the same freeze duration with a stationary fade, no sweeping
entrance, no aperture stretch and no moving fragments. Menu transition speed does
not lengthen this combat presentation.

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
  recovery, duration boundaries, input gates, interruption, reduced motion and
  simulation/configuration preservation.
- `python scripts/capture-super-freeze-review.py` records the native renderer at
  60 fps; `--stills` saves stills only. `--size 1920x1080` checks another viewport.
- [Current native motion preview](../exports/FightGuild-Super-Freeze-Review.mp4)
  and [Fillet still](../exports/FightGuild-Super-Freeze-Fillet.png) use the approved
  existing portrait fallback pending the new face-art selection.
