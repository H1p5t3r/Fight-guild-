# Generated stages and travel

The Charter Grounds connect west to Foundry Walk and east to the Tide Docks. All three areas are playable after a wall break, including further breaks. The loop is:

| Area | Left break | Right break |
| --- | --- | --- |
| Charter Grounds | Foundry Walk | Tide Docks |
| Tide Docks | Charter Grounds | Foundry Walk |
| Foundry Walk | Tide Docks | Charter Grounds |

A common painted, ink-outlined guild-sport city ties together slate, red brick, dark iron, burgundy and muted teal. The starting stadium has spectator stands and pennants; the forge uses warm arches and chimneys; the quay uses timber, cranes, ships and fishing banners. These are generated scenic images, not geometry painted by the renderer.

## Layer contract

Each area uses three **separately generated 1536 × 1024 images**: an opaque distant city/sky, transparent middle architecture, and a transparent playing surface. Foreground boundary props are six independent regions in a generated atlas. Two additional generated cutouts form the forge/harbor passages, and an eight-region fragment atlas supplies broken masonry, iron, timber, fabric and dust.

`godot/assets/stages/` contains the thirteen runtime images. `art/stages/charter-grounds-reference.png` is the style reference. `art/stages/generation/manifest.json` records original image-generator filenames and SHA-256 hashes. The originals were copied byte-for-byte; cutout corrections were performed through image generation. `cutout-revisions.json` preserves the exact correction prompts. The initial layer briefs below describe the generation requirements; they are a reconstruction, not a verbatim prompt transcript.

- Share the reference's cel-painted materials, perspective and top-left afternoon lighting. No characters, labels, UI or readable text in scenery.
- Far: distant city, sky and atmospheric depth; no foreground floor or large nearby architecture. Harbor adds ships/water; foundry adds chimneys/industrial roofs.
- Middle: independently cut-out stands, arches, roof beams and low spectator rail. Harbor adds warehouses/rigging/cranes; foundry adds warm forge bays. Keep the floor below about y=735 and sky openings transparent.
- Floor: completely clear alpha above about y=730; uninterrupted horizontal fighting surface below. A pale baseline at about y=900 anchors the fighters. No architecture or props on the fighting plane.
- Passages: close broken architecture around the outer edges with a large fully transparent central opening. Forge uses brick/iron/burgundy; quay uses timber/iron/rope/teal.
- Boundary atlas: three columns by two rows, 512-pixel cells; upright isolated props anchored near cell y=480. No background or cross-cell marks.
- Fragment atlas: four columns by two rows, 384 × 512 cells; individual masonry, metal, wood, cloth and two dust shapes.

Normal play tracks the fighters' midpoint with a restrained 1.0–1.2 zoom. Additional space beyond the physical walls keeps the fighter silhouettes inside the frame. The distant, middle and floor planes respond at 0.16, 0.54 and 1.0 depth weights, with overscan to avoid exposed image edges. Collision boxes, characters and boundary props share the same world projection. Counter zoom is composed afterward so feet remain attached to the ground.

## Travel

New configurations use **150 ticks / 2.5 seconds**. The existing editor still supports 30–300 ticks; old saved configurations keep their chosen duration. Ground, architecture and sky move at different speeds during travel. A generated portal passes the camera, fragments follow the broken side, and the existing jump/hurt/crouch poses provide provisional flight and landing. The target area name appears during arrival. Dedicated character travel animation and sound are future work.

The core captures both fighters' departure positions when the follow-up breaks the wall. Those positions and the stage index are snapshot state. The neutral reset happens with one third of the transition remaining, while the rendered flight continues smoothly to the target camera's exact position and scale. All animation reads fixed-tick progress; pausing and rollback do not leave stale tweens or particles. Existing health, Momentum, timer, held-input and Positive Bonus rules remain in force.

Reduced motion uses a stationary camera, a scene dissolve and fighter fades around the reset, without flight or rotating debris. The loading screen prepares all adjoining scenery along with the selected fighters.

## Review

`tests/stage_test.gd` checks both live-input wall routes, source/target stability through the reset, legacy duration preservation, layer coverage and exact landing continuity. Native recovery tests cover all six directed connections at 30/90/150/151/300 ticks and snapshot replay. The packaged build verification loads every stage image.

To record the visual review with a display available:

```sh
bash scripts/godot.sh --write-movie /absolute/path/stage-review.avi --fixed-fps 60 \
  --script tests/stage_preview.gd -- --test --captures /existing/capture/folder
```

Add `--reduced` after `--` to review the quieter presentation. This fixture uses real movement, a launcher and a splat follow-up; it lowers wall durability to make both breaks easy to inspect.
