# Sprite production direction — working contract v0.5

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
| Shark | Lean diagonals; long low-volume white hair close to skull/nape and back, blue sports glasses, bone jaw shoulder, long hook plus short blade | slate `#34454D`, bone `#D9D4BD`, teal `#258A99` |
| Fillet | Compact angular silhouette; short brown hair, red shoulder/corset, ivory apron, two curved knives | charcoal `#393039`, ivory `#DDD0B1`, crimson `#A63242` |

## Fillet and Shark proportion study v2

The first proportion pass updates **32 poses per fighter**: 12 active/support, six windups, six block reactions and eight signature poses. These remain the playable atlases while the other four fighters keep their existing sheets. The remade [reference 05 model/action pages](fillet-shark-references.md) carry this mature anatomy into the character guides and serve as the drawing reference for the next sprite pass. Use the v2 windup/neutral poses to check scale continuity with the current build; use the current design decisions below for the selected ready stance and hair treatment.

Fillet's selected standard stance is **A / Stalker** from the original six-option study: wider stagger, forward-loaded low torso, longer right knife low and shorter left knife close/downward. This supersedes the intermediate B/F narrower-leg direction; do not blend the two. Shark keeps long white hair with a lower crown, less outward volume and fewer controlled locks along the nape/back. Moving hair should follow the pose without reintroducing the old radiating mane. These choices are recorded in [current design decisions](../art/characters/design-decisions.json); reference-sheet changes do not alter runtime pivots, pushboxes or body geometry.

Target roughly 7.5–8 anatomical heads in an upright body, counting the skull rather than projecting hair. Use a smaller mature head, a clear ribcage/pelvis relationship, longer athletic limbs, strong shoulders and forearms, and substantial gloves/boots. Fillet keeps compact angular gestures and a red/ivory butcher silhouette; Shark keeps broad shoulders, long diagonals, teal/slate/bone masses and white hair. The head, hand and weapon scale must remain constant across actions; do not stretch a whole sprite vertically to simulate new proportions. Preserve the palette ramps above and one hard-edged shadow grouping per material.

Every phase still normalizes to the same **150 world-pixel standing reference**. Its measured atlas `body_height`, per-pose root and local region are authoritative, including nonuniform cuts around wide weapons. The 64 body fits were authored independently of alpha, with three body regions plus at most one extension. All push dimensions remain stable; tucked-jump drawings lift the feet 50px above the standing foot/root reference, matching the existing air spacing. Fillet's Heavy Slash active was corrected to a forward double cut and fitted to its blades. Shark's moving hook remains a separate generated weapon layer.

`proportions-v2/generation.json` records exact downstream generation/correction prompts, source files and rejection reasons; the two original master prompts are explicitly marked as reconstructed briefs. Original v1 art and collision metadata live in `art/archive/proportions-v1/`. Failed v2 layouts/poses live in `art/archive/proportions-v2-studies/`. Generated pixel files are preserved; changes to pivots, atlas bounds and collision are metadata. Redraws that cross atlas boundaries or substitute attack gestures for defensive poses must be repaired before promotion.

## Smear and effect grammar

Use a shared vocabulary, not unrelated special effects for each image. A smear describes motion and must not obscure the hand, striking limb, or weapon silhouette.

- **Slash:** one tapered crescent following the actual weapon arc. Thin bright inner edge, a single character-accent body, then at most two short trailing wedges. No full circular rings unless the action actually makes that arc.
- **Thrust / dash:** a narrow directional wedge aligned with travel, broad near the source and tapered toward the trailing end. Do not turn a jab into a projectile or put an impact burst on a whiff.
- **Blunt swing:** a short broad arc with two or three angular trailing facets. Reserve radial chips and impact stars for a future contact-dependent impact layer.
- **Smoke:** two or three connected rounded lobes or one curling ribbon, using the same hard-edged value grouping as the cast. No hazy full-cell glow. Smoke's curved vocabulary is an explicit material exception, not a different rendering style.
- Windups have no released smear or impact. Active smears follow the outgoing action. Future impact shapes appear only when contact occurs; they must be separate from the reusable attack pose.

Some first-pass active sheets include baked-in flashes, gradients, or inconsistent weapon details. Track and replace these during the consistency pass; do not treat them as new style rules. Body/equipment and effect layers should be separate in the production pipeline.

## Current build contract

Each fighter has a generated active/support atlas a generated windup atlas and a generated block-reaction atlas. Active/support: four columns by three rows for Fillet/Shark v2, six columns by two rows for the other fighters, with idle, P, K, S, Hs, D, two walking poses, jump, hurt, guard, crouch. Windup: three columns by two rows, with a neutral scale reference, then P, K, S, Hs, D anticipations. Block reactions: three columns by two rows, row-major stable contact/settle, pressure contact/hold, guard-break contact/stagger. Stable and pressure maintain a closed silhouette, with pressure more compressed; broken guard opens the arms and chest. No baked-in impact effects in the defensive sheets. The contact pose settles after four unfrozen ticks; hitstop pauses it. PNG alpha, original generated files preserved; atlas regions, foot pivots and scale also anchor separately authored body/strike rectangles. Weapons and effects never extend hurtboxes. Regenerate compiled collision after geometry changes; see [collision rules](collision-rules.md).

The renderer displays windup during startup and the active pose on active ticks, including any hitstop that freezes those ticks. It returns to a ready pose during recovery while the simulation continues to enforce recovery. These are pose changes, not completed animation clips. Slots without dedicated signature art temporarily reuse the corresponding button’s pose. Fillet and Shark add four dedicated windup/active pairs each, taking the catalog to 160 poses. Shark’s hook body and generated spear are separate layers; core endpoints direct weapon travel. The initial eight recovery ticks reuse the hook active body during weapon retraction; no new recovery drawing is implied. Every distinct directed action needs its own authored sequence later.

`godot/assets/fighters/manifest.json` records source references, generation filenames, checksums, atlas regions, pivots, and scale. Runtime attack timing comes from the move editor; the initial defensive settle transition is four ticks. `signature-generation.json` records exact signature, weapon-layer and cleanup prompts; `generation-prompts.json` includes the original windup prompts and explicitly marked reconstructed block prompt briefs. Visual silhouettes and smears never determine hit detection.

## Future action specification and review gate

The [Fillet/Shark reference handoff](fillet-shark-references.md#using-an-edited-move-brief-for-the-next-sprite-pass) connects model identity to the workshop's current move JSON, art notes, embedded pose photos, enabled slots, active hitbox keys and optional multi-hit groups. Drawing-sheet arrows and registration marks are illustrative; edited game-space movement, reach and collision remain authoritative. Generate to those values rather than silently changing them to fit a new silhouette.

For each action, record: character master/version, move ID, button, ground/air stance, facing, start/end root position, planted foot, weight shift, contact point/height, weapon grip, attack path, palette version, allowed deformation, and smear type. Reference the same approved neutral model and previous approved frame on every generation request. Keep prompt, references, generator version when available, and all rejection notes; seeds alone are not a consistency guarantee.

The future clip has **windup → active → impact → follow-through → recovery** stages. Each can contain multiple drawings. Impact is conditional on hit/block; a whiff must flow from active to follow-through. Follow-through and recovery are visual subdivisions of existing gameplay recovery until the combat design requires a distinct simulation phase. Current attack generation scope is windup and active only. The separately requested defensive clips add two reaction drawings per block category. Frame counts and timing will be authored per move rather than assumed globally.

Review at game size, on a neutral background, as a silhouette, and beside the master and adjacent frame. Check palette drift, proportion/weapon drift, foot sliding, action direction, alpha halos, clipping/neighbor contamination, and visual contact versus the debug hitbox. Reject failures before packing. Automated checks can validate files, dimensions, alpha, frame completeness, pivots, and hashes; approval of identity, shape language, and action readability remains an art review.
