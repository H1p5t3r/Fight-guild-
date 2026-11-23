# Receiver reactions

The user requested distinct leg, chest, head and airborne hit reactions, with **no
gameplay changes**. The native selector and contact metadata are implemented;
new sprite production is awaiting the direction choice below. The existing
calibrated hurt pose remains visible until approved drawings are installed.

## Direction review

- [A / Compact Snap](../art/characters/receiver-reactions-v1/a-compact-snap.png):
  contained joint snap, planted support and a compact airborne curl.
- [B / Whip Recoil](../art/characters/receiver-reactions-v1/b-whip-recoil.png):
  stronger hip/spine counterrotation, trailing limbs and a diagonal airborne shape.

Both are Fillet motion studies, with **contact → recoil → stun hold** in each row
and arrows showing direction. They establish the movement language for the
roster; they are not runtime sprite sheets. A/B can be mixed by row. Exact prompts
and untouched generated PNGs are preserved beside this document's linked art.
No unanswered question counts as approval. Impact-VFX selection was delegated;
character-pose selection was not.

After selection, generate transparent production keys against each character's
current references. Preserve costume, handedness, weapon silhouette and anatomy.
Register hips/support feet, check head/boot scale against ready and attack poses,
and test both facings at native gameplay size. Do not normalize bent poses by
their silhouette height; that makes crouched/airborne bodies grow. Avoid morphing,
automatic smears, stretched anatomy and softened contact timing. A contact drawing
must already read as a hit, not simply repeat neutral.

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
collision-authoring manifests. After approval, each fighter index maps to four
clips (`legs`, `chest`, `head`, `air`), each with `file`, `body_height`, and three
`frames` containing `region` and `pivot`. Per-frame file/body-height overrides are
supported. Missing art falls back to the current calibrated hurt pose.

## Verification

- Core feedback suite: 524 checks covering body regions, masks, both facings,
  airborne contacts, hitbox-key changes, trades, swept projectiles and replay.
- Godot receiver suite: selection, contact/recoil/hold timing, hitstop,
  defender slowdown, follow-ups, trades, recovery clearing and rollback.
- Existing native feedback, impact, Fillet-scale and collision suites pass.
- Compared the previous commit's core with this implementation over **382,560
  frames**: identical state checksums and hurt/push/hit boxes across all fighters
  and move slots, both facings, guarding, airborne targets, trades and random input.
- Combat data regeneration check passes unchanged. Website source and publishing
  guards remain untouched.
