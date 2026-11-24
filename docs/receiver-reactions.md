# Receiver reactions

The user requested distinct leg, chest, head and airborne hit reactions, with **no
gameplay changes**. The user selected **A / Compact Snap** on 2026-11-24.
All six fighters now use the production sprites: **24 clips / 72 drawings**,
with contact, recoil and stun-hold keys for each family. The game still uses
its original combat poses and collision geometry underneath this visual layer.

Watch the [native animation review](../exports/FightGuild-Compact-Snap-Reactions.mp4)
for each fighter beside their current idle, at normal and half-speed playback.
This is a pose/timing review using an illustrative eight-frame hitstop, not a
new attack or a change to any move's stats.

## Direction review

- [A / Compact Snap](../art/characters/receiver-reactions-v1/a-compact-snap.png):
  contained joint snap, planted support and a compact airborne curl.
- [B / Whip Recoil](../art/characters/receiver-reactions-v1/b-whip-recoil.png):
  stronger hip/spine counterrotation, trailing limbs and a diagonal airborne shape.

Both are Fillet motion studies, with **contact → recoil → stun hold** in each row
and arrows showing direction. A is the approved movement language for the roster;
the review boards themselves are not runtime sprite sheets. Their exact prompts
and untouched PNGs remain beside the linked art. Production prompts, character
references, source paths and SHA-256 hashes live in
`godot/assets/fighters/reactions-v1/generation.json`.

Production keys use transparent images against each character's
current references. Preserve costume, handedness, weapon silhouette and anatomy.
Register hips/support feet, check head/boot scale against ready and attack poses,
and test both facings at native gameplay size. Do not normalize bent poses by
their silhouette height; that makes crouched/airborne bodies grow. Avoid morphing,
automatic smears, stretched anatomy and softened contact timing. A contact drawing
must already read as a hit, not simply repeat neutral. The render atlas has no
baked-in sparks, smear frames, opponent, floor shadow or generated motion blur.

`scripts/register-reaction-art.py` reproduces registration without changing PNG
pixels. Each fighter keeps one standing-equivalent scale across all twelve keys.
Grounded keys register at their soles; air keys register at a fitted hip plus
fixed virtual leg length, so knee tucks do not move the body root or resize it.
Frame boundaries follow the actual transparent gutters rather than assuming
the generator placed every row at an exact quarter of the image height.
Smoke retains her unarmed, flowing silhouette; Shark keeps his hook and blue
sports glasses; Tapper's staff stays secured behind his recoil poses. Fillet's
black hair, thin arms and knife handedness remain registered to her reference.

## Selection and clocks

The cosmetic event retains its twelve-field layout. `flags` now carries:

| Bits | Meaning |
| --- | --- |
| 0 | Projectile contact |
| 1–2 | 1 legs, 2 chest, 3 head; 0 falls back to chest |
| 3 | Defender was airborne at contact |

These flags do not enter `State`, move configuration, collision data, network
fingerprints or checksums. Core/schema remains 27. All six fighters use the same
selector. Main `FighterArt.PHASES` and compiled hurt/push geometry stay unchanged.

For melee, sample the real overlapping hurtbox using the active hitbox key,
before either side of a trade is interrupted. When a strike covers several body
regions, select the overlap nearest that hitbox's vertical center; ties keep the
stable region/box order. Disabled regions retain their semantic identity rather
than being renumbered. The optional fourth extension represents arms/complex
body shapes and uses chest recoil. Weapons never create a hurt region. Guard
height (low/mid/high) does not determine anatomical hit location.

Moving projectiles use the first swept contact, then the closest vertical body
point to break simultaneous ties. This also handles fast vertical projectiles
that pass across several regions in one simulation tick. Region metadata is
captured before any projectile damage changes the defender's pose.

Airborne contact overrides the anatomical family. A grounded launch switches to
air art when the existing simulation raises the body. This changes no launch or
velocity values. Knockdown, get-up, capture, wall splat and wall travel retain their
existing dedicated presentation. Blocking, Faultless Defense and armor do not
start hit reactions. Throws use chest contact metadata at damaging release; their
capture/knockdown presentation still takes precedence.

Each receiver has a separate cosmetic history entry:

- Action ages 0–1: contact drawing, held throughout shared hitstop.
- Ages 2–4: sharp recoil.
- Age 5 onward: held stun pose, for as long as the fighter remains stunned/reeling.

The clock also respects defender-only counter slowdown. It outlives the short
impact burst, resets on a new hit, and clears when the defender recovers. Rollback
replaces future reactions alongside other cues; trades have independent receiver
entries. Rendering never changes stun duration or makes a fighter actionable.

`godot/assets/fighters/reactions-v1/manifest.json` is deliberately separate from
collision-authoring manifests. Each fighter index maps to four
clips (`legs`, `chest`, `head`, `air`), each with `file`, `body_height`, and three
`frames` containing `region` and `pivot`. Per-frame file/body-height overrides are
supported. Missing art falls back to the current calibrated hurt pose.

## Verification

- Core feedback suite: 524 checks covering body regions, masks, both facings,
  airborne contacts, hitbox-key changes, trades, swept projectiles and replay.
- Godot receiver suite: selection, contact/recoil/hold timing, hitstop,
  defender slowdown, follow-ups, trades, recovery clearing and rollback. Production
  acceptance covers **48 actual-contact scenarios**: six fighters × four families
  × both facings. All three keys render through the native arena, with identical
  snapshots and hurtboxes before/after every render.
- Existing native feedback, impact, Fillet-scale and collision suites pass.
- Compared the previous commit's core with this implementation over **382,560
  frames**: identical state checksums and hurt/push/hit boxes across all fighters
  and move slots, both facings, guarding, airborne targets, trades and random input.
- Combat data regeneration check passes unchanged. Website source and publishing
  guards remain untouched.
- The 2026-11-24 art pass changes no core source, main fighter manifest, move data
  or collision data. Windows debug/release libraries remain current.

Review commands:

```sh
python scripts/register-reaction-art.py --check
bash scripts/godot.sh --headless --script res://tests/reactions_test.gd -- --test
python scripts/capture-reaction-review.py
```
