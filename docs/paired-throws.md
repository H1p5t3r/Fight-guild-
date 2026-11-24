# Paired throws: A / Collar Fold

The user selected **A / Collar Fold** on November 24 and requested longer grab
animations. The native game now has **36 paired drawings across all six fighters**:
catch, load and turn for the grabber; caught, folded and turned poses for the
receiver. Grounded normal grabs hold for **40 action ticks** and the authored
command grabs hold for **52**. Startup and the normal throw's six-tick tech window
remain unchanged. The move-editor website remains frozen.

Watch [the native review](../exports/FightGuild-Collar-Fold-Grabs.mp4) for twelve
scenarios, including both Fillet command grabs, a back throw at the wall, a throw
tech, Wound, Tapper's headbutt/tackle and each other fighter's normal throw.
The recording uses the current shipped data at normal 60 Hz simulation speed.
The [previous review](../exports/FightGuild-Throw-Presentation.mp4) retains the
shorter timing and older capture drawings for comparison.

## Timing and gameplay

| Ground capture | Previous hold | New hold | Techable action ticks |
| --- | ---: | ---: | ---: |
| Fillet normal throws | 24 | 40 | 1–6 |
| Anvil, Hammer, Smoke and Shark normals | 6 | 40 | 1–6 |
| Tapper normal throws | 6 gate + 20 grip | 6 gate + 34 grip = 40 | 1–6 of gate |
| Fillet command grabs | 28 | 52 | None |
| Tapper 5D collar/headbutt | 20 | 40 | Existing strike defense |
| Tapper st.236D tackle/punch | 24 | 52 | None |

These counts exclude existing shared hitstop. At 60 Hz, 40 ticks is about 0.67
seconds and 52 is about 0.87 seconds. Normal throws still start in two frames.
Command-grab startup, damage, post-release recovery/advantage, release gaps,
knockdowns and stance/bleed outcomes retain their prior values. Wound and air
throws retain their separate existing timing and presentation.

Fillet's extra time is inserted in the held section of her paired root tracks.
The first four catch ticks and the final movement segments keep their original
speeds, positions and side switch. Damage still pays once at the final capture
tick. This is an intentional gameplay timing change: characters remain captured
longer and the match clock continues to run normally; it is not a render-time
pause that conceals an already actionable character.

Ordinary one-stage legacy throws now use `grabFrames` for the total capture hold,
with a minimum six-tick gate. An explicit zero in an older move file retains the
old six-tick behavior. Tapper's `actionType = 4` keeps its separate grip stage,
so his `grabFrames` is not counted twice. His finish pose starts four ticks before
damage. Fillet continues to use `extensions.params.pairTicks` and `pairTracks`.
The renderer reads the saved capture clock/duration/facing from the core.

Core schema stays **27** because the state layout is unchanged. Rules revision
advances to **4**, so peers with the older capture behavior fail the existing
compatibility fingerprint. Windows debug/release libraries and the source-ZIP
repair bundle are rebuilt for the new defaults and behavior.

## Paired artwork and registration

The [approved direction board](../art/characters/paired-throws-v1/receiver-options.png)
is a motion study. Production preserves the full weapons and uses each fighter's
current identity references: Fillet's black hair and long-right/short-left knives,
Shark's full hook and blue glasses, Smoke's unarmed silhouette and Tapper's secured
staff.

Runtime PNGs and exact prompts/source hashes are in
`godot/assets/fighters/grabs-v1/`. The images remain untouched image-generator
outputs. Anvil's first background result is retained separately in
`art/characters/paired-throws-v1/anvil-before-alpha.png`; the corrected transparent
image is the runtime source. Registration never edits sprite pixels.

`scripts/register-grab-art.py` supplies fixed anatomy scale, grounded foot roots
and hand/forearm/collar landmarks. `CombatGrabs` composites the paired poses only
during capture. It keeps floor height fixed, never stretches a body, and bounds
horizontal alignment offsets to 18 world pixels per fighter. Back-throw turning
keys follow the existing side crossing. Main fighter/collision manifests are
unchanged, so weapons do not add hurtboxes and the physics roots do not follow
cosmetic contact adjustments.

The new grip does not replace signature finishes. Fillet's last sixteen command
capture ticks retain her approved knife-finish keys, rescheduled into the longer
hold. Tapper retains the headbutt; his tackle transitions to his existing kneeling
punch and the receiver's approved back-down pose. Wound keeps its separate
downed-to-standing sequence. No interpolated morphs or automatic smears are added.

## Release and foreground

After Fillet's damaging release, the approved Compact Snap chest reaction holds
through `pairRecovery`, then clears when the defender becomes actionable. Its
clock respects hitstop and rollback. A recovery lock alone does not create a hit
cue: the attacker, a successful throw tech and Wound's non-damaging release still
avoid false recoil. Knockdown, wakeup and wall-splat art keep priority.

Capture owners and their weapons render in front throughout the grip, including
the initial freeze/tech window. After release, normal last-contact ordering
resumes. Rendering never overwrites the core's `foregroundPlayer` state.

## Data and verification

`scripts/update-grab-timing.py` updates defaults and creates
`2026-11-24-collar-fold/FightGuild-Collar-Fold.json`, preserving every other field,
note, art brief, photo and saved sequence from the prior Hammer batch. It is
idempotent. Existing personal move drafts are preserved; use **Load latest
workshop batch** in Godot to opt into the new default hold timings. No website
files or publishing guards are updated.

- C++ timing suite: **29,165 checks**, including every attacker/receiver, both
  player slots/facings, two-frame normal startup, exact release timing, one damage
  payment, C1/C6 tech acceptance, C7 rejection, old-zero compatibility and replay.
- Native paired suite: **84 actual captures**, all six receivers, both slots and
  facings, corners, tech, Wound and Tapper. Checks release keys, grip roles, fixed
  anatomy scale, bounded horizontal registration, snapshots/hurtboxes around
  rendering, and exact rollback of the cosmetic release clock.
- Fillet runtime/geometry, Tapper, core, recovery and feedback regressions pass.
  Native receiver, impact, scale, collision and Workshop-batch checks also pass.
- Twelve native review cases verify that each capture starts and releases.

```sh
python scripts/register-grab-art.py --check
python scripts/generate-combat-data.py --check
bash scripts/godot.sh --headless --script res://tests/paired_throws_test.gd -- --test
python scripts/capture-paired-throw-review.py --stills
python scripts/capture-paired-throw-review.py
```
