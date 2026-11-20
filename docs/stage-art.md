# Generated stages and travel

The Charter Grounds connect west to Foundry Walk and east to the Tide Docks. All three areas are playable after a wall break, including further breaks. The loop is:

| Area | Left break | Right break |
| --- | --- | --- |
| Charter Grounds | Foundry Walk | Tide Docks |
| Tide Docks | Charter Grounds | Foundry Walk |
| Foundry Walk | Tide Docks | Charter Grounds |

A common painted, ink-outlined guild-sport city ties together slate, red brick, dark iron, burgundy and muted teal. The starting stadium has spectator stands and pennants; the forge uses warm arches and chimneys; the quay uses timber, cranes, ships and fishing banners. These are generated scenic images, not geometry painted by the renderer.

## Layer contract

Each area uses three **separately generated 1536 × 1024 images**: an opaque distant city/sky, transparent middle architecture, and a transparent playing surface. Three additional opaque generated wall surfaces fill each visible boundary from the contact plane to the screen edge, for the full viewport height. The earlier six-prop atlas is preserved as an art study. Two additional generated cutouts form the forge/harbor passages, and an eight-region fragment atlas supplies broken masonry, iron, timber, fabric and dust.

`godot/assets/stages/` contains fifteen runtime images plus the earlier wall-prop study. `art/stages/charter-grounds-reference.png` is the style reference. `art/stages/generation/manifest.json` records original image-generator filenames and SHA-256 hashes. The originals were copied byte-for-byte; cutout corrections were performed through image generation. `cutout-revisions.json` preserves the exact correction prompts; `full-wall-prompts.json` preserves the complete prompts for the solid boundary surfaces. The initial layer briefs below describe the generation requirements; they are a reconstruction, not a verbatim prompt transcript.

- Share the reference's cel-painted materials, perspective and top-left afternoon lighting. No characters, labels, UI or readable text in scenery.
- Far: distant city, sky and atmospheric depth; no foreground floor or large nearby architecture. Harbor adds ships/water; foundry adds chimneys/industrial roofs.
- Middle: independently cut-out stands, arches, roof beams and low spectator rail. Harbor adds warehouses/rigging/cranes; foundry adds warm forge bays. Keep the floor below about y=735 and sky openings transparent.
- Floor: completely clear alpha above about y=730; uninterrupted horizontal fighting surface below. A pale sporting line appears near y=900; the runtime fighting plane now uses y=810, leaving visible paving below the feet. No architecture or props on the fighting plane.
- Passages: close broken architecture around the outer edges with a large fully transparent central opening. Forge uses brick/iron/burgundy; quay uses timber/iron/rope/teal.
- Boundary atlas: three columns by two rows, 512-pixel cells; upright isolated props anchored near cell y=480. No background or cross-cell marks.
- Fragment atlas: four columns by two rows, 384 × 512 cells; individual masonry, metal, wood, cloth and two dust shapes.

Normal play frames Fillet and Shark at about **60% of the full match window's height**, following the user's [Strive screenshot reference](research/strive-camera-framing-2026-11-16.md). Local/online versus fill the viewport; training and development keep their toolbars. Feet sit at **92.5% of arena height**, above floating Momentum meters. The camera tracks the midpoint, opens for separation or a jump above a grounded opponent, and follows shared airborne height when both fighters leave the floor. Collision boxes, characters, weapons and walls keep the same world projection. Counter zoom is composed afterward over both the scene and fighters. Reduced motion keeps essential framing.

The scenic images span **1,240 world units**, centered on the 1,000-unit fighting space. Every source pixel on the floor has a fixed world size and uses the **same zoom and horizontal camera displacement as the fighters**. The former 92–104% scenery zoom clamp and overscan-based pan are removed: a jump cannot shrink the bodies while leaving the floor almost unchanged. The architecture shares the floor's scale and vertical registration at the authored y=735 join. Its horizontal parallax weight is 0.54; the distant image uses 0.16, and the floor uses 1.0. The opaque sky supplies coverage beyond the finite scenery when the camera follows high launches; exposed upper architecture edges fade into it. Nearby plates retain their world scale rather than being resized to fill gaps.

The ground plane is y=810 in the 1024px source image, leaving paving in front of the fighters. Soft dynamic shadows use the lowest body hurtbox, never weapon geometry; they stay on the projected floor, spread/fade with height, and gain contact darkening on the ground. Background color modulation separates the more subdued scenery from the fighters. Boundary textures also have a fixed world scale and ground anchor, with bounded UV tiles through their full-height collision half-spaces and a shaded inner edge. The full-screen border coverage and hidden wall health rules are unchanged.

## Travel

New configurations use **150 ticks / 2.5 seconds**. The existing editor still supports 30–300 ticks; old saved configurations keep their chosen duration. Ground, architecture and sky move at different speeds during travel, with the foreground moving fastest. Adjoining architecture/floor images overlap through the passage, including their feathered edges, so the transition cannot expose a vertical gap. A generated portal passes the camera, fragments follow the broken side, and the existing jump/hurt/crouch poses provide provisional flight and landing. The target area name appears during arrival. Dedicated character travel animation and sound are future work.

The core captures both fighters' departure positions when the follow-up breaks the wall. Those positions, including height, and the stage index are snapshot state. The neutral reset happens with one third of the transition remaining, while the rendered flight continues smoothly to the target camera's exact position and scale. The flight briefly reduces character scale and limits its arc to available headroom to accommodate the larger silhouettes. All animation reads fixed-tick progress; pausing and rollback do not leave stale tweens or particles. Existing health, Momentum, timer, held-input and Positive Bonus rules remain in force.

Reduced motion retains essential camera framing so the fighters stay equally large and visible in play. It removes the counter accent, travel pan, flight and rotating debris; wall breaks use a scene dissolve and fighter fades between the source and destination views. The loading screen prepares all adjoining scenery along with the selected fighters.

## Review

`tests/stage_test.gd` checks both live-input wall routes, source/target stability through the reset, legacy duration preservation, overlap through travel and exact departure/landing continuity, including reduced motion. `tests/camera_test.gd` checks the standing silhouette ratio, corner and airborne visibility, floor/world landmark projection, architecture/floor registration at five arena sizes, a real jump, shared airborne framing, and restored-snapshot camera consistency. Native recovery tests cover all six directed connections at 30/90/150/151/300 ticks and snapshot replay. The packaged build verification loads every stage image.

To record the visual review with a display available:

```sh
bash scripts/godot.sh --write-movie /absolute/path/stage-review.avi --fixed-fps 60 \
  --script tests/stage_preview.gd -- --test --captures /existing/capture/folder
```

Add `--reduced` after `--` to review the quieter presentation. This fixture uses real movement, a depleting hitstun collision, a separate splat collision and a follow-up break; it lowers wall health to make both breaks easy to inspect.

`tests/camera_preview.gd -- --test --captures /existing/capture/folder` captures neutral, a one-player jump, a simultaneous jump, full separation, corner, collision overlays and a rekka using live inputs. Add `--editor` for the smaller development arena or `--reduced` for reduced-motion framing. Its silhouette percentages use the logical viewport, so window stretch does not distort the measurement.
