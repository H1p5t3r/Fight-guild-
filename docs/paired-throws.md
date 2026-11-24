# Paired throw presentation

This pass continues roadmap item 2 in native Godot. It changes **presentation
only**. Move stats, captures, root tracks, facing, damage, tech windows, recovery,
knockdowns, collision geometry and core/network snapshots remain unchanged.
The move-editor website and its disabled publishing jobs are untouched.

## Completed: release reactions and capture layering

Fillet's authored normal and command throws do not use normal hitstun after their
damaging release. They lock the defender using `pairRecovery`. Previously the
receiver immediately returned to idle, even during release hitstop and the
remaining recovery lock.

The release now uses the already approved **Compact Snap** chest contact, recoil
and hold drawings for every defender. Its cosmetic clock holds during shared
hitstop, then advances with the existing action timing, and clears on recovery.
A lock alone does not create a hit reaction: the attacker, successful throw techs
and Fillet's non-damaging Wound release still have no receiver cue. Knockdown,
wakeup, capture and wall-splat art retain priority.

During capture, the arena draws the capture owner and their weapon in front.
This includes the initial freeze/tech gate, before the core records damage, and
Tapper's longer collar/tackle grips. After capture, normal last-contact ordering
resumes. This is a render-time decision; the core's `foregroundPlayer` value is
not overwritten. Menus and HUD keep their existing layer order.

Watch [the native review](../exports/FightGuild-Throw-Presentation.mp4): forward
throw, back throw at a wall, both command grabs, successful tech, Wound and
Tapper's collar capture. It runs the current shipped move data at 60 simulation
frames per second. **Capture drawings in the video are the existing art.** Only
the release and layering fixes are installed in this step.

## New grip direction: awaiting selection

The user-approved art process remains **options → selection → production**.
The [direction board](../art/characters/paired-throws-v1/receiver-options.png)
shows three poses and motion arrows for each choice:

- **A / Collar Fold:** compact catch, forward compression and chest recoil.
- **B / Shoulder Turn:** stronger torso rotation and an off-balance release.

This board is an original image-generation motion study, not a runtime sheet.
Its untouched source and exact prompt are recorded in
`art/characters/paired-throws-v1/generation.json`. Production must retain exact
weapons and handedness rather than copying the concept board's shortened hook.
Fillet keeps her long right-hand knife, short left-hand knife and left shoulder
armour. Shark keeps his full hook, knife and blue sports glasses.

After selection, register paired contact landmarks against the actual roots and
capture clocks, using fixed anatomy scale and individual grounded/airborne
anchors. Verify both player slots, facing directions and corner clamping.
Do not stretch bodies or weapons to manufacture a grip; do not alter gameplay
root tracks to conceal an art mismatch. Back throws need their own turning keys;
Tapper's collar/headbutt and running tackle need appropriate receiver silhouettes.
Keep damage on the current damaging release frame, not on a concept-board pose.

## Existing timing to preserve

| Capture | Capture ticks | Capture freeze | Release freeze | Owner / receiver recovery |
| --- | ---: | ---: | ---: | ---: |
| Fillet normal throws | 24 | 6 | 8 | 12 / 14 |
| Fillet command grabs | 28 | 6 | 8 | 16 / 18 |
| Fillet Wound | 20 | 4 | 0 | From current move extensions |
| Legacy normal throw gate | 6 | Move hitstop | Existing contact resolution | Existing knockdown/recovery |
| Tapper collar / tackle grip | 20 / 24 | Existing contact resolution | Existing contact resolution | Existing knockdown/recovery |

These are documentation of the current configuration, not hardcoded animation
timers. Preserve data-driven capture tracks, release gaps and edited timings.

## Verification

`paired_throws_test.gd` exercises **84 actual captures** using the current shipped
Workshop snapshot: all six receivers across Fillet's four damaging throws,
both player slots and facings, left/center/right placement, throw techs,
non-damaging Wound, the remaining roster's normal throws and Tapper's longer grips.
It checks contact/recoil/hold keys, hitstop, single damage resolution, clearing on
recovery, exact replay of cosmetic cues and core checksum, and unchanged snapshots
and hurtboxes around every render. Stale capture owners cannot override normal
last-contact ordering after release.

Existing receiver, feedback, impact, Fillet-v1, Tapper, scale and collision suites
also pass. Combat-data generation and reaction-atlas registration remain
unchanged. No native library rebuild is needed for these GDScript-only fixes.

```sh
bash scripts/godot.sh --headless --script res://tests/paired_throws_test.gd -- --test
python scripts/capture-paired-throw-review.py
```
