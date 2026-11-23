# Knockdown animation and sprite scale

All six fighters now have two generated six-pose recovery sequences:

| Knockdown | Resting pose | Get-up path |
|---|---|---|
| Soft | On the back, face up | Elbow brace → seated → kneel → rise → ready |
| Hard | Prone, face down | Brace → kneel → rise → ready anticipation → ready |

`knockdown = 1` selects the back-lying sequence; `knockdown = 2` selects the face-down sequence. Both keep the existing automatic recovery in place. The down pose holds for the move's down duration; the five get-up drawings fit the configured wakeup duration. Zero wakeup frames skip the get-up clip. A one-frame wakeup uses its final drawing. Hitstop pauses the sequence, and rollback restores its exact frame. No action, invulnerability, throw protection or recovery timing changes are introduced by the artwork.

The game, Sprite review and browser combat preview share the same atlas regions, feet/root registration and fixed source scale. Every pose has three body hurt regions; weapons remain excluded. Existing knockdown protection remains authoritative.

Tapper's old 400px scale was also applied to his 470px idle drawing. Source batches are now calibrated to the same 150-world-pixel standing reference, and repeated drawings use the same scale in every slot. A crouch stays shorter and a raised weapon can extend farther; neither changes the character's scale. His authored hitboxes, pushbox, inputs and frame data are unchanged; inherited body hurtboxes follow the corrected art scale.

Original generated PNGs and exact prompts live in `godot/assets/fighters/recovery-v1/`. Run `python scripts/register-recovery-art.py` and `python scripts/generate-combat-data.py` after revising registration metadata. `node scripts/review-recovery-art.mjs` renders comparison sheets to `build/recovery-review/` without altering source pixels. No transition smears are added.

## Fillet hit-reaction calibration (2026-11-23)

The legacy hurt drawing inherited the whole active atlas's 310px reference. It
looked oversized beside the approved Stalker stance and newer attack drawings.
That single pose now uses a fixed 350px standing-equivalent reference: about 11%
smaller, uniformly, with the same foot/root pivot. It is shared by ordinary hitstun,
air reel, wall splat and held/captured reactions. No camera-dependent or per-tick
resizing is applied. Knockdown/get-up, idle, movement and attack registration are
unchanged; their different silhouettes still reflect their poses.

Run `python scripts/calibrate-fillet-reactions.py` followed by
`python scripts/generate-combat-data.py` to reproduce the registration and matching
body hurtboxes. Only this pose's three inherited body boxes and the collision
fingerprint change. Move stats, authored attack boxes and pushboxes stay intact;
both online players must use the updated build. Original image bytes are retained.

The native scale test exercises actual grounded and launched hits in both facings,
checks the anchored foot, and guards against another visible size jump. The native
preview in `godot/tests/fillet_scale_preview.gd` compares the old and corrected
reaction at the same zoom. [View the comparison](../exports/Fillet-Hit-Reaction-Scale.png)
or regenerate it with `python scripts/capture-fillet-scale.py`. The
[gameplay impact review](../exports/FightGuild-Impact-Review.mp4) also uses the
corrected reaction. The move-editor website remains paused.
