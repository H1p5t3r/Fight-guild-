# Shark — selected movement cycles

The selected set is **idle A, walk B, backward walk A, backdash B, run A**.
The user's “ball walk” selection is interpreted as backward walk.

| Action | Direction | Drawings | Playback |
| --- | --- | ---: | --- |
| Idle | A / Lazy Tap | 4 | Rest, lift, shoulder tap, settle; 72 / 12 / 6 / 18 action ticks |
| Walk | B / Rolling Swagger | 8 | Two alternating steps, driven by distance travelled |
| Backward walk | A / Unbothered Retreat | 8 | Faces the opponent while retreating; its own forward-playing sequence |
| Backdash | B / Shoulder Slip | 6 | Load, push, flight, catch, absorb, reset; follows configured backdash duration |
| Run | A / Shoulder Cruise | 8 | Right contact/load/drive/flight, then left contact/load/drive/flight |

The idle holds Shark's downward glance before a short handle tap on his shoulder.
Its complete loop lasts 108 action ticks, or 1.8 seconds outside hitstop. The
movement drawings use opposing ribcage/pelvis rotation, knee compression and
delayed hair and sash movement. Walk and run use eight distinct drawings;
neither loop repeats or mirrors one leg's four-key sequence to create the other.
The near leg remains identifiable as it travels behind the far leg.

## Art registration

The 34 drawings are stored in eight transparent atlases under
[`shark-movement-v1`](../godot/assets/fighters/shark-movement-v1/). The first idle
drawing also supplies the static ready pose used by existing attack entry keys.
Every drawing uses a fixed 480-source-pixel standing reference mapped to 150
world pixels. Crouching and airborne gestures retain that anatomy scale instead
of resizing to fill their cell. Grounded keys anchor their sole to the floor;
flight drawings retain a virtual floor below the lifted feet.

Each pose has four fitted body regions: legs, torso/arms, head, and the extended
forearm/knife hand. The weapons, trailing hair and cloth do not add vulnerability.
Movement speeds, dash duration, move data, attack animation clocks and pushbox
dimensions retain their existing values. The backdash's drawn hop does not make
the simulation airborne or add invulnerability.

[`generation.json`](../godot/assets/fighters/shark-movement-v1/generation.json)
records exact generation and correction prompts, references and SHA-256 hashes.
Generated PNGs remain byte-identical to their source files. Roots, crops, gait
labels and anatomical fits are metadata, reproduced by
`python scripts/register-shark-movement-art.py`, followed by
`python scripts/generate-combat-data.py`.

## Playback and review

In the browser Move Workshop, select **Shark → Movement & defense**, then
preview **Idle**, **Walk forward**, **Walk backward**, **44 / backward macro**,
or **66 / forward macro**. The last two use the character's current movement
configuration; the default Shark profile is step backdash and forward run.
No move JSON import is needed for these artwork updates.

In Godot, **Development → Sprite & collision review** exposes Ready, Walk,
Backward walk, Backdash, and Run / step dash. Frame selection, looping, mirroring
and anatomical overlays include the new keys.

The combat core selects the same pose for drawing and collision. Idle uses the
saved action clock; backdash uses saved dash age; walking and running use
distance. Hitstop, frame seeking and rollback therefore restore the displayed
drawing and its body boxes together. The new backdash phase is appended as
phase 15, preserving the indices of existing phases. Idle timing contributes
to the collision fingerprint because it determines which body pose is active.

Verification covers every movement key in both facings, alternating contact
labels and unique sprite regions, backward playback order, hitstop and rollback,
WASM/plain-JavaScript agreement, and Godot resource loading. Visual review checks
the drawn leg identities in addition to those metadata checks.
