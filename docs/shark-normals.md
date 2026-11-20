# Shark normals — Ky reference and visual choices

Status: playable iteration. A / Shoulder Snap, 2 / Low Scoop and the revised
[fluid motion study](../art/characters/shark-normal-options-v1/low-scoop-fluidity.png)
are approved. The16 selected normals now have source timings, traced attack
geometry, dedicated windup/active drawings, clean entry keys and body-only
hurtboxes.2Hs has an eight-key clip with separate contacts on active frames1/2.
The initial stiff production attempts were rejected and never registered.

The user's saved Dustloop Ky Kiske Frame Data page supplies **16 non-D normals**.
The [source manifest](../references/frame-data/ky-kiske-2026-11-18/source.json)
preserves table text, notes, source hash, saved timestamp and diagram URLs.
The [slot proposal](../references/frame-data/ky-kiske-2026-11-18/shark-proposal.json)
maps these moves onto Shark without touching other slots.

## First choice: movement from Shoulder Rest

All options use Shark's current **F / Shoulder Rest** idle, blue sports glasses,
low-volume long white hair, right-hand hook and left-hand triangular blade.
Each board compares the same f.S and 6Hs windup/active poses. Their frame data and
planned attack ranges are the same; the choice concerns body motion and silhouette.
These are concept boards, not cropped production sprites or collision references.

- [A / Shoulder Snap](../art/characters/shark-normal-options-v1/A-shoulder-snap.png):
  compact shoulder-led release, direct poke and controlled chop. Recommended
  starting point for clear spacing and a quick return to the relaxed idle.
- [B / Low Tide](../art/characters/shark-normal-options-v1/B-low-tide.png):
  deeper leg loading and a long low lunge. Stronger whole-body commitment.
- [C / Crosscurrent](../art/characters/shark-normal-options-v1/C-crosscurrent.png):
  more torso rotation, knife-hand counterbalance and a larger hook wheel.

Choices can be mixed by move. The drawings' apparent reach will be calibrated
against the source diagrams during production; pose exploration does not set
world-space hitboxes. Final anatomy/root scale and weapon length must stay fixed.

## Saved source values

H is displayed as Hs to match Fight Guild notation. Startup includes the first
active frame; raw damage is before Fight Guild scaling. IAD advantages depend
on air contact/landing and are not fixed grounded blockstun values.

| Move | Start | Active | Recovery | Raw damage | Guard | On block | Hitbox image |
| --- | ---: | --- | ---: | --- | --- | --- | --- |
| 5P | 5 | 4 | 7 | 26 | All | -1 | Inline supplement |
| 5K | 7 | 8 | 6 | 30 | Low | -2 | Yes |
| c.S | 7 | 6 | 10 | 42 | All | +1 | Yes |
| f.S | 10 | 3 | 20 | 34 | All | -9 | Yes |
| 5Hs | 12 | 6 | 21 | 48 | All | -8 | Inline supplement |
| 2P | 5 | 4 | 8 | 22 | All | -2 | Yes |
| 2K | 6 | 4 | 10 | 26 | Low | -2 | Yes |
| 2S | 11 | 2 | 24 | 32 | Low | -12 | Yes |
| 2Hs | 11 | 1,4 | 28 | 14, 40 | All | -13 | Inline supplement |
| j.P | 6 | 3 | 9 | 20 | High | — | Yes |
| j.K | 7 | 4 | 12 | 26 | High | -1 (IAD) | Yes |
| j.S | 7 | 3 | 21 | 32 | High | -1 (IAD) | Yes |
| j.Hs | 13 | 4 | 23 | 44 | High | +5 (IAD) | Yes |
| 6P | 9 | 5 | 22 | 34 | All | -13 | Yes |
| 6K | 25 | 2 | 11 | 40 | All | +4 | Yes |
| 6Hs | 15 | 4 | 26 | 52 | All | -13 | Yes |

There are **14 embedded diagrams covering 13 moves**: j.Hs has two diagrams.
5P, 5Hs and both 2Hs diagrams are absent from the archive, but the user supplied
all four as inline images after choosing A. Their provenance is recorded in
`supplemental.json`; no nonexistent local files or hashes are claimed. The
original `source.json` accurately retains the archive's missing-image records.
These pictures require a documented root/scale estimate, not a claim of exact
source engine coordinates.

## Approved motion standard

The first four production attempts were rejected for stiffness and are not
registered as gameplay art. Keep character proportions, not a frozen torso.
Lead with hips and weight transfer; rotate the ribcage against the pelvis, bend
the spine and allow a rear heel to lift or pivot. Use a compressed anticipation,
an extended contact, a real braking pose and a loose settling recovery. Hair and
cloth lag behind the body. The user approved this six-pose Low Scoop study.
The art can move locally around its root without adding unrequested gameplay
travel. No body/limb smear frames are introduced.

## Gameplay details to carry forward

- 5K and 2S are lows. c.S is +1 and 6K is +4 on block.
- 6Hs is a **mid**, even though its visual swing descends from above.
- 6P has two source vulnerability windows: frames 1–3 below-crouch and 4–13
  low-profile. Shark's four body regions and existing hurtbox toggles must
  express the adaptation without making weapons vulnerable.
- 2Hs has two contacts: 14 then 40 raw damage over 1 + 4 active frames. Its
  second hit has a specific floating-crumple sequence: 33f total, airborne
  hitstun 1–19, standing hitstun 20–27, blocking allowed 28–33. The current
  generic crumple is not equivalent. This iteration uses an ordinary small
  launch/float with33f final hitstun; the special airborne/standing/guard-only
  crumple phases remain unimplemented. This is an explicit utility approximation.
- j.Hs changes geometry but is not listed as a multi-hit. The archive does not
  label the exact frame boundary between its two diagrams.
- 6Hs lists separate normal/wall-bounce knockdown advantage. That annotation
  does not mean that every hit should gain a wall bounce.
- Ky's source Combo Decay, proximity units, wall damage and RISC figures require
  adaptation to this engine's units/rules. Preserve Fight Guild's universal
  gatlings and the existing Momentum system.

## Playable assets and tuning

- `godot/assets/fighters/shark-normals-v1/`:16 unchanged generated PNGs,
  exact prompts, original generator paths, correction history and hashes.
- `scripts/register-shark-normals.py`:20 signature pairs (four existing specials
  preserved plus16 normals),26 action-animation keys, authored foot roots and
  at most four anatomical hurtboxes. Anatomy scale uses540 source pixels for
  the normal sheets and850 for the taller Low Scoop sheets, independent of
  weapon/effect bounds. No automatic body smearing.
- `scripts/build-shark-hitboxes.py`:18 red-shape traces. Yellow reference width
  is normalized to40 local pixels; live pushboxes stay unchanged.5Hs follows
  the outlined strike conservatively because upper solid red/green shapes in
  the inline export are ambiguous. j.Hs switches geometry on active frame3,
  an explicit estimate, and remains one hit.
- `scripts/build-shark-data.py`:derives
  `2026-11-18-shark/FightGuild-Shark-Normals.json` from the immutable latest
  Smoke animation batch. Only the16 selected Shark slots and appended brief
  text change. Submitted art photos and existing prose remain intact.

2Hs has11f startup,5 active frames (1 +4),28 recovery and14/40 raw damage.
The editor's multi-hit switch can make those geometries one hit. Its second
hit is taller with less forward reach, so the outer first-hit tip can fail to
connect again; this depends on opponent body shape. Source picture scaling,
art-to-box alignment, proximity85px, push/launch and air stun remain provisional.
The source 6P vulnerability is adapted with head/extension off on1–3 and legs
only on4–13; these four-region masks do not exactly reproduce source cyan shapes.
Mid/large counters retain the project's21/31f freeze and25/35f defender slowdown.
6Hs is a mid with soft knockdown and an air-hit-only wall bounce, not an overhead.
Its source knockdown-advantage figures are not claimed as exact local timing.

Both native and browser rendering use the saved action clock: hitstop freezes
these drawings and seeking/replay restores the same pose. The native Sprite
Review exposes all20 dedicated selectors and a full2Hs animation clip for Shark.
Existing browser saves keep priority. Export a backup, then import the new batch
to take its new selectors and source stats; loading the site alone does not
replace a local draft.

All D attacks (including 2D, j.D and charged D), current hook-pull specials and
follow-ups, throws, movement tuning and other fighters remain outside this pass.
No Ky specials, supers, Shock State or Dragon Install are added. No automatic
transition smear frames are planned. Production follows the approved fluid-motion revision.

Exact generation prompts and source paths are retained alongside the boards in
`art/characters/shark-normal-options-v1/generation.json`. Re-extract the reference
with `scripts/extract-dustloop-frame-archive.py <archive.mht> ky-kiske --exclude-dust`.
