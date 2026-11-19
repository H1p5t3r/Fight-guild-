# Shark v2 — Set the Line

This pass applies the [attack animation standard](../../../docs/attack-animation-standard.md) to all 26 enabled Shark actions. It retains the selected Shoulder Snap normals, Low Scoop 2Hs and movement cycles. New sheets provide braking/withdrawal poses, special attacks, Drive actions and normal-throw captures. The attack library contains 191 registered timing cues, including two paired capture tracks. Cues can hold or reuse drawings; they are not 191 unique pictures.

The authoring source is the Shark data in the selected Fillet-v1 workshop batch, archived in `baseline-moves.json`. Every non-Drive scalar, active hitbox timeline, authored hurtbox override, input and disabled slot is preserved. In particular, slots 14–16 stay disabled, 2S stays a hard-knockdown sweep, and the saved aerial hook uses S even though its stable slot ID remains `j.214P`. Other fighters keep their tuning. Schema 24 added three editable line fields. Schema 25 retires Chase and separates pull movement from strike resolution.

## Drive roles

| Input | Action | Startup / active / recovery | Purpose |
| --- | --- | --- | --- |
| 5D | Set the Line | 16 / 4 / 24 | A grounded hook check. An unblocked hit attaches the line. |
| j.D | Cast Down | 17 / 4 / 22 | A downward overhead tag from the air. |
| 2D | Reel In | 12 / 1 / 20 | Spend a line to pull the target horizontally. Unblockable; no new stun, damage or hitstop. |

A line lasts 180 unfrozen simulation frames and breaks beyond 450 pixels on either axis, when Shark takes a hit, or when spent. **2D is the only line follow-up; 6D Chase is disabled.** Without a line, Reel In whiffs. The line is spent on the attempt.

Reel In adds horizontal displacement, without registering a strike, counter, combo hit, guard reaction, damage or hitstop. Blocking and Faultless Defense cannot stop it. A free opponent can attack, jump, dash or guard throughout; their own movement and vertical velocity continue. Already-stunned opponents keep their existing hit/block state and remaining stun until the pull ends. For example, 12 frames of remaining blockstun plus a 10-frame pull leaves 12 frames after the pull, not a fresh stun value. An interrupted pull stops extending stun immediately. Downed, waking, captured and wallsplat reactions are excluded rather than rewritten.

`Line lifetime` belongs to the tagging move. `Line maximum distance` on the tag limits persistence; on Reel it limits activation. `Line stopping gap` is root-to-root distance clamped by both pushboxes. `Reel travel duration` controls the horizontal movement and stun hold; shared hitstop pauses both clocks. Positions use 100 raw units per pixel. Older mechanic-1 tether saves retain their original repeat-input behavior. Schema-24 imports disable retired mechanic-5 Chase slots while preserving their other tuning and notes.

## Animation registration

- `sources.json` records original image-generator paths, exact PNG hashes and atlas layout. Cleanup generations also retain the earlier source identity. Runtime PNGs are copied unchanged.
- `exposure-plans.json` records held-load, first-active, brake, withdrawal and settle cues on the saved attack clock. Each phase is normalized so timing edits move its entry automatically.
- Crops, pivots and calibration are metadata. No image interpolation, body smear, recoloring or per-pose zoom is applied.
- First-active changes use the real startup boundary. On-hit playback respects shared hitstop, airborne landing, and the normal-throw tech/capture clock.
- Normal throws use separate successful-contact and whiff tracks. A failed reach does not play a completed throw.
- Hook casts use the simulation's moving diagonal weapon endpoints. Generated arcs, rope and hook seals are visual layers with no hurtboxes or extra damage.
- Anatomical fits have at most four regions. Weapon/effect reach does not enlarge the body hurtboxes. User-authored move overrides still take priority.
- Malformed candidate frames are listed in the exposure plan and excluded from the selected clips.

## Reproduce and review

```sh
python3 scripts/update-shark-kit.py
python3 scripts/register-shark-kit.py
python3 scripts/generate-combat-data.py
bash scripts/build.sh
bash scripts/build-godot.sh
node scripts/build-workbench.mjs
./build/shark-drive-tests
node tests/workbench-shark-kit.mjs
node tests/workbench-shark-kit-browser.mjs
node scripts/capture-shark-kit-review.mjs
```

The hosted/portable folder includes `shark-motion-review.html`, with all 26 actions, whiff/contact, before/after, hitboxes, mirroring and frame stepping. Earlier drawings are shown on the **current** action clock, not as a historical gameplay simulation. Utility contact examples explicitly start with a line attached. Video output lives in `build/shark-kit-review/` and contains actual 60 Hz simulation frames; the inspection video is labelled half speed.

The editor retains a user's browser-local draft across updates. Export that draft before importing `FightGuild-moves.json` to try this new Drive kit. Importing an older JSON does not silently replace its tuned Shark moves.

Review videos: [full kit at 60 fps](previews/Shark-Full-Kit-60fps.mp4) and [Drive/hooks at half speed](previews/Shark-Drive-and-Hooks-Half-Speed.mp4). Validation results and the local-file browser policy limitation are recorded in `validation.json`.
