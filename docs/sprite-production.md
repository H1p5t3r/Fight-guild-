# Sprite production direction — working contract v0.1

The six generated sets are iteration studies. The goal is a repeatable character performing a directed action, not a new illustration of that character in every frame. These rules establish the target for the production pipeline in [the backlog](backlog.md); the current images still need a consistency review before becoming approved masters.

## Shared rendering rules

- Side/three-quarter fighting-game camera, facing right in the source. Fixed camera, body proportions, costume construction, weapon dimensions, grip, and handedness across a sequence. The game mirrors presentation for left facing.
- A strong dark outer contour, thinner interior lines, and simple cel-shaded masses. One neutral top-left key light; one main shadow tone per material, with small sharp metal highlights. No independent dramatic lighting per pose, painterly gradients, airbrushed halos, or floating floor shadows.
- Muted base colors with one principal identity accent. Keep skin, cloth, leather, metal, and effects in separate named palette ramps. Lighting must not change a character's local colors. Proposed hex values below are authoring targets, not a claim that current generated pixels already conform exactly.
- Shape hierarchy: one dominant body silhouette, one readable equipment silhouette, then a few costume landmarks. Fine detail must survive at the actual in-game size or be simplified. Never substitute extra costume detail for a readable action.
- Windup compresses the silhouette and stores energy opposite the attack direction. Active extends the line of action toward the target. Keep the planted foot, pelvis/root anchor, head size, and weapon length continuous between these poses. A larger source cell must not make a larger in-game character.

| Fighter | Dominant shape and immutable landmarks | Working base / identity accent |
| --- | --- | --- |
| Anvil | Broad square mass; white beard, bald crown, rectangular shield, beaked hammer | charcoal `#302A29`, leather `#71503A`, ivory `#E4D7BB`, muted brass `#B98A3E` |
| Hammer | Tall block/triangle mass; bald head, white armor, blue cloth, rectangular hammer | ivory steel `#D9D6CF`, shadow `#545868`, blue `#2D5FB7` |
| Smoke | Narrow flowing curves; green hood, long dark hair, ivory coat tails, vials | ivory `#DCD1AA`, brown `#554333`, olive `#778B33`, vapor `#A4CA35` |
| Tapper | Sturdy rectangle with open circular hooks; blond hair/beard, hooked staff at both ends | brown `#65503A`, ivory `#D8C6A2`, ochre `#C39832`, burgundy `#713A38` |
| Shark | Lean diagonals; white hair, teal mask, bone jaw shoulder, long hook plus short blade | slate `#34454D`, bone `#D9D4BD`, teal `#258A99` |
| Fillet | Compact angular silhouette; short brown hair, red shoulder/corset, ivory apron, two curved knives | charcoal `#393039`, ivory `#DDD0B1`, crimson `#A63242` |

## Smear and effect grammar

Use a shared vocabulary, not unrelated special effects for each image. A smear describes motion and must not obscure the hand, striking limb, or weapon silhouette.

- **Slash:** one tapered crescent following the actual weapon arc. Thin bright inner edge, a single character-accent body, then at most two short trailing wedges. No full circular rings unless the action actually makes that arc.
- **Thrust / dash:** a narrow directional wedge aligned with travel, broad near the source and tapered toward the trailing end. Do not turn a jab into a projectile or put an impact burst on a whiff.
- **Blunt swing:** a short broad arc with two or three angular trailing facets. Reserve radial chips and impact stars for a future contact-dependent impact layer.
- **Smoke:** two or three connected rounded lobes or one curling ribbon, using the same hard-edged value grouping as the cast. No hazy full-cell glow. Smoke's curved vocabulary is an explicit material exception, not a different rendering style.
- Windups have no released smear or impact. Active smears follow the outgoing action. Future impact shapes appear only when contact occurs; they must be separate from the reusable attack pose.

Some first-pass active sheets include baked-in flashes, gradients, or inconsistent weapon details. Track and replace these during the consistency pass; do not treat them as new style rules. Body/equipment and effect layers should be separate in the production pipeline.

## Current build contract

Each fighter has a generated active/support atlas and a generated windup atlas. Active/support: six columns by two rows, with idle, P, K, S, Hs, D, two walking poses, jump, hurt, guard, crouch. Windup: three columns by two rows, with a neutral scale reference, then P, K, S, Hs, D anticipations. PNG alpha, original generated files preserved; atlas regions and foot pivots are metadata, not combat geometry.

The renderer displays windup during startup and the active pose on active ticks, including any hitstop that freezes those ticks. It returns to a ready pose during recovery while the simulation continues to enforce recovery. These are pose changes, not completed animation clips. Crouching, command, special, and air slots temporarily reuse the corresponding button's pose. Every distinct directed action needs its own authored sequence later.

`godot/assets/fighters/manifest.json` records source references, generation filenames, checksums, atlas regions, pivots, and scale. Runtime timing comes from the move editor. Visual silhouettes and smears never determine hit detection.

## Future action specification and review gate

For each action, record: character master/version, move ID, button, ground/air stance, facing, start/end root position, planted foot, weight shift, contact point/height, weapon grip, attack path, palette version, allowed deformation, and smear type. Reference the same approved neutral model and previous approved frame on every generation request. Keep prompt, references, generator version when available, and all rejection notes; seeds alone are not a consistency guarantee.

The future clip has **windup → active → impact → follow-through → recovery** stages. Each can contain multiple drawings. Impact is conditional on hit/block; a whiff must flow from active to follow-through. Follow-through and recovery are visual subdivisions of existing gameplay recovery until the combat design requires a distinct simulation phase. Current generation scope is windup and active only. Frame counts and timing will be authored per move rather than assumed globally.

Review at game size, on a neutral background, as a silhouette, and beside the master and adjacent frame. Check palette drift, proportion/weapon drift, foot sliding, action direction, alpha halos, clipping/neighbor contamination, and visual contact versus the debug hitbox. Reject failures before packing. Automated checks can validate files, dimensions, alpha, frame completeness, pivots, and hashes; approval of identity, shape language, and action readability remains an art review.
