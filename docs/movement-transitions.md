# Native movement transitions

## Fillet — first pass, 2026-11-24

The old neutral jump reverted to the first-generation tucked drawing when an air
attack ended. Takeoff and landing also switched straight between older crouch/air
art and the current wide Stalker stance.

`CombatMovement` now selects matching takeoff, flight, dash and landing drawings
from the **selected Fillet movement contract** in
`art/characters/fillet-v1/MOVEMENT_ANIMATION.json`. Her current attack animations
keep their own timing and always take priority, including the final displayed
attack tick. There is no new movement lock or blend between poses.

- Prejump holds compression, then extends on its final two ticks.
- Saved vertical velocity selects fast ascent, slower ascent, apex, early descent
  and landing preparation. Thresholds follow the character's jump speed/gravity.
- The air-dash pause holds the compact guard; forward lean begins with the actual
  velocity burst.
- Ground contact absorbs through the existing landing recovery, then rises on its
  final tick. Zero recovery means no extra animation lock.
- Hit reactions, guard, FD, knockdown, capture, paired recovery and active attacks
  take priority over movement art.

The two original generated RGBA atlases and a separate render-only manifest live
in `godot/assets/fighters/movement-v1/`. The sources, prompts and references are
recorded in `art/characters/movement-transitions-v1/`. Air frames use a common
belt landmark matched to the approved j.P drawing; ground frames use the foot
contact line. Anatomy scale stays fixed per sheet. No root interpolation,
crossfade, automatic smear, or gameplay geometry change is involved.

## Verification and review

Run:

```sh
bash scripts/godot.sh --headless --script res://tests/movement_presentation_test.gd -- --test
python scripts/capture-movement-review.py
```

The test uses current Workshop data and actual inputs in both facings, exercises
empty jumps, j.P, j.K, dash arrest/burst and landing, and restores/replays native
snapshots. Every arena refresh must preserve the snapshot and hurtboxes. The art
selector for Fillet's air poses has no render clock or independent rollback state.

The native capture also records Hammer and Tapper as the remaining movement
baseline. Its 750 simulation states can be compared byte-for-byte through their
checksums with the pre-change capture. The focused before/after Fillet video is
`exports/FightGuild-Fillet-Movement.mp4`.

## Hammer and Tapper — 2026-11-24

The user said **“Continue with your judgement”**, delegating the remaining art
choice. Hammer uses **A / Grounded March**, following his existing Shoulder Drive
design. Eight drawings each cover walking, retreating and running. The run/walk
cycles change support legs; the first walk generation's repeated lead leg was
corrected before registration. All three sheets use a fixed anatomy scale and
registered belt/floor landmarks. Source generations, the correction and prompts
are preserved in `art/characters/movement-transitions-v2/`.

Tapper keeps the staff on his back and fists raised during stance travel. Four
keys each cover forward/back shuffles and forward/back step dashes. Four pairs
of withdrawal/settle drawings cover `st.P`, `st.K`, `st.S` and `st.Hs`:

- Load and active poses retain the existing attack drawings and clocks.
- The first `max(1, recovery / 7)` recovery ticks hold the strike drawing.
- The next interval withdraws; the last 45% settles into his rolling guard.
- A legal cancel or other state transition immediately wins over the artwork.

Tapper's grounded stance and stance-strike source drawings also receive a
render-only support-foot registration correction. Their old pivots put the boots
slightly below the floor. This does not alter core poses or authored hurtboxes.

`CombatLocomotion` records a bounded 360-frame visual history, longer than the
240-frame rollback window. Each replay replaces predicted future entries. Gait
entry starts on a contact pose; subsequent keys follow actual root travel,
including acceleration. Starting at a different stage position cannot change the
entry key. Hitstop/counter holds freeze playback, while a blocked root plants a
contact pose even if requested run velocity remains nonzero. Ground stops get a
brief, interruptible settle. Step dashes use the existing saved dash age.

Hammer's stride distances stay fixed at 16 world units per walk key, 30 per run
key and 12.5 per retreat key. His later movement retune lowers walk speed and
raises run acceleration/cap; those speed changes now alter the cadence naturally
instead of also rescaling stride distances. See [current movement tuning](hammer-kit.md).

This history never enters native snapshots, gameplay hashes or collision data.
As with combat cues, a standalone imported snapshot without its prior visual
history starts a fresh gait; ordinary in-session rollback has the needed history.
Other fighters retain their existing ground gait selection.

Additional verification:

```sh
bash scripts/godot.sh --headless --script res://tests/locomotion_presentation_test.gd -- --test
python scripts/capture-movement-review.py --output build/movement-v2-final --details
```

The extended native review records 1,182 frames, including all four stance
withdrawals and both step dashes. Its baseline 750 gameplay records/checksums
match the pre-art capture. The edited before/after review is
`exports/FightGuild-Movement-Transitions.mp4`. Hammer's neutral air pose and the
other fighters' existing movement art remain available for future art passes.

The Move Workshop website and its publishing guards remain unchanged.
