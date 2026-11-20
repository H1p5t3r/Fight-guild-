# Smoke attack animation and approved specials

**20 November update:** the four specials now use the
[guide-audited recovery pass](attack-animation-audit-2026-11-20.md), with eight new
recovery drawings and 37 timed cues. Register that pass with
`scripts/register-smoke-specials-v3.py`. The earlier registration below is the
historical November 18 import and should not be used to replace the current
workshop batch.

This pass implements the selected Venom Sabre and Furnace Cleaver effects with
backhand body movement. Both effects sweep in a horizontal arc parallel to the
ground. Smoke's hands are empty: there is no physical sword, handle or hilt.
The close and far crystal casts share P2 / Smoked Obsidian art and size.

## Current workshop batch

The original [18 November upload](../godot/data/workshop/2026-11-18-user-smoke/FightGuild-moves-2026-11-18.json)
is preserved byte for byte. The playable
[animation batch](../godot/data/workshop/2026-11-18-user-smoke/FightGuild-Smoke-Animations.json)
differs only in these four `artPose` selectors. All move values, movement,
hitbox timelines, hurtbox masks, notes and embedded pose references are retained,
including the submitted Tapper edits.

| Actual input | Stable slot / legacy ID | Art selector | Visual |
| --- | --- | --- | --- |
| 236S | 14 / `236P` | 21 | Close Smoked Obsidian pillar |
| 236Hs | 25 / `236K` | 22 | Far Smoked Obsidian pillar |
| 214S | 15 / `236S` | 23 | Venom Sabre backhand |
| 214Hs | 16 / `623Hs` | 24 | Furnace Cleaver backhand |

Slot IDs are persistence keys; the editor's input label reflects the mapped
button and motion. The pillars use the same four-frame atlas and 100 × 150
world-pixel projectile dimensions. Their placement is 150 versus 300 pixels.
The uploaded startup and lifetime differences remain authored values: close
13f / 36f lifetime, far 25f / 120f lifetime. Stationary projectiles ignore
velocity and gravity fields. The existing j.D ember keeps its own artwork.

Fresh game/editor sessions load this batch. Existing saved drafts remain local;
export a backup and import the animation batch to adopt its new selectors.
The hosted editor remains at https://h1p5t3r.github.io/Fight-guild-/.

## Backdraft and attack entries

2Hs has eight body keys: gather, coil, eruption, twist, crest, follow-through,
recover and settle. It begins from the approved H crouch. Three separately
generated fire-column keys follow the three active hitbox stages; a fourth
residual effect follows during recovery. The move remains **18 / 9 / 28** and
**one hit**, with active shape changes at frames 1, 4 and 7.

Every enabled Smoke attack has an entry from A standing, H crouching or the
existing airborne pose. Ground throws share a reach key within their 2f startup.
Normal entries do not redraw the existing active normals. Automatic transition
smears remain removed.

Animation keys divide each existing windup/active/recovery phase by percentage.
They do not add combat ticks; editing timing resizes their allotted durations.
The saved action age selects body art and anatomical hurtboxes together, so
hitstop, counter slowdown and rollback freeze or restore both. Selecting another
art pose opts out of the slot's custom clip. These animation timings are authored
in the manifest, not exposed as a new editor control in this pass.

## Art and review

`godot/assets/fighters/smoke-attacks-v2/generation.json` retains exact prompts and
original generation paths. PNGs are copied unchanged. Atlas crops, pivots,
fixed anatomy scales and fitted body boxes are metadata. Unequal columns on
the sword-effect atlas are isolated by crop metadata. Effects never add hurtboxes.

All 32 new animation keys and eight special windup/active poses use at most
four anatomical boxes. The uploaded sword active hurtboxes and masks take
precedence over these fallback body fits. Push profiles are unchanged.
Backdraft's column renders behind its owner; the backhand arcs render in front.
Both stay inside their owner's foreground group and mirror with facing.

In Development → Sprite & collision review, Smoke now has **Dedicated move**
and **Smoke / Backdraft animation** clips, with mirroring and frame selection.
The browser preview uses the same combat clock and generated layers.

Rebuild metadata with `python scripts/register-smoke-attacks-v2.py`, then
`python scripts/generate-combat-data.py`. Rebuild the native core and workshop
afterward. The registration script is repeatable; it does not modify the raw
upload or append duplicate art selectors.
