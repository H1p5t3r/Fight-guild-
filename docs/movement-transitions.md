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
selector has no render clock or independent rollback state.

The native capture also records Hammer and Tapper as the remaining movement
baseline. Its 750 simulation states can be compared byte-for-byte through their
checksums with the pre-change capture. The focused before/after Fillet video is
`exports/FightGuild-Fillet-Movement.mp4`.

## Remaining work in roadmap item 4

- **Hammer:** A / Grounded March and B / Pressure Shuffle footwork options have
  been shown; production artwork awaits the user's choice. The option board is
  `art/characters/movement-transitions-v1/hammer-footwork-options.png`.
- **Tapper:** his existing four-pose stance loop continues while travelling;
  dedicated stance footwork and a fuller return from stance normals remain.
- Ground locomotion still has the existing phase selection. This pass does not
  claim to resolve distance-based gait entry or add a new stance travel cycle.

The Move Workshop website and its publishing guards remain unchanged.
