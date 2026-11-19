# Shark v2 — Set the Line

This pass applies the [attack animation standard](../../../docs/attack-animation-standard.md) to all 27 enabled Shark actions. It retains the selected Shoulder Snap normals, Low Scoop 2Hs and movement cycles. New sheets provide braking/withdrawal poses, special attacks, Drive actions and normal-throw captures. The attack library contains 198 registered timing cues, including two paired capture tracks. Cues can hold or reuse drawings; they are not 198 unique pictures.

The authoring source is the Shark data in the selected Fillet-v1 workshop batch, archived in `baseline-moves.json`. Every non-Drive scalar, active hitbox timeline, authored hurtbox override, input and disabled slot is preserved. In particular, slots 14–16 stay disabled, 2S stays a hard-knockdown sweep, and the saved aerial hook uses S even though its stable slot ID remains `j.214P`. Other fighters keep their tuning. Schema 24 adds three editable line fields.

## Drive roles

| Input | Action | Startup / active / recovery | Purpose |
| --- | --- | --- | --- |
| 5D | Set the Line | 16 / 4 / 24 | A grounded hook check. An unblocked hit attaches the line. |
| j.D | Cast Down | 17 / 4 / 22 | A downward overhead tag from the air. |
| 2D | Reel In | 12 / 1 / 20 | Spend a line to pull a grounded target toward Shark. Deals no damage. |
| 6D | Chase Line | 8 / 10 / 10 | Spend a line to move Shark toward the target, up to 140 game pixels. Deals no damage. |

A line lasts 180 unfrozen simulation frames and breaks beyond 450 pixels on either axis, when Shark takes a hit, or when spent. Reel is a strike resolved through the regular guard/FD and hurtbox path: blocking prevents the drag, jumping avoids it, and the line is spent on the attempt. Chase has no attack box or invulnerability, keeps its starting direction, and stops at body spacing. It cannot automatically switch sides. Both actions whiff without a line. These are provisional tuning values, editable in the Drive panel.

`Line lifetime` belongs to the tagging move. `Line maximum distance` on the tag limits persistence; on Reel/Chase it limits the action. `Line stopping gap` is root-to-root distance clamped by both pushboxes. `Reel travel duration` controls Reel's pull ticks; `Line chase speed` controls movement during Chase's active span. Positions use 100 raw units per pixel. Older mechanic-1 tether saves retain their original repeat-input behavior.

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

The hosted/portable folder includes `shark-motion-review.html`, with all 27 actions, whiff/contact, before/after, hitboxes, mirroring and frame stepping. Earlier drawings are shown on the **current** action clock, not as a historical gameplay simulation. Utility contact examples explicitly start with a line attached. Video output lives in `build/shark-kit-review/` and contains actual 60 Hz simulation frames; the inspection video is labelled half speed.

The editor retains a user's browser-local draft across updates. Export that draft before importing `FightGuild-moves.json` to try this new Drive kit. Importing an older JSON does not silently replace its tuned Shark moves.

Review videos: [full kit at 60 fps](previews/Shark-Full-Kit-60fps.mp4) and [Drive/hooks at half speed](previews/Shark-Drive-and-Hooks-Half-Speed.mp4). Validation results and the local-file browser policy limitation are recorded in `validation.json`.
