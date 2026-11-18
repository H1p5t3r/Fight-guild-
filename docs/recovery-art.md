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
