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
| Fillet | Compact angular silhouette; short black hair, slender arms, red shoulder/corset, ivory apron, two curved knives | charcoal `#393039`, ivory `#DDD0B1`, crimson `#A63242` |

## Fillet and Shark proportion study v2

The first proportion pass updates **32 poses per fighter**: 12 active/support, six windups, six block reactions and eight signature poses. Their attack and defensive drawings remain playable; the new locomotion pass below replaces their neutral and two-pose walking presentation. Anvil, Hammer and Smoke retain their original locomotion; Tapper now has the separate pass below. The current [reference 05 model/action pages](fillet-shark-references.md) carry this mature anatomy into the character guides and serve as the drawing reference for the next sprite pass. Use the v2 windup/neutral poses to check scale continuity with the current build; use the current design decisions below for the selected ready stance and hair treatment.

Fillet's selected standard stance is **A / Stalker** from the original six-option study: wider stagger, forward-loaded low torso, longer right knife low and shorter left knife close/downward. This supersedes the intermediate B/F narrower-leg direction; do not blend the two. Shark keeps long white hair with a lower crown, less outward volume and fewer controlled locks along the nape/back. Moving hair should follow the pose without reintroducing the old radiating mane. Shark uses **F / Shoulder Rest**, balancing the hook across his shoulders in his right hand and keeping the separate left knife low. Physical blue sports glasses replace the old eye mask. These choices are recorded in [current design decisions](../art/characters/design-decisions.json); the locomotion pass registers these choices with new roots and body fits while retaining the existing push profiles.

Target roughly 7.5–8 anatomical heads in an upright body, counting the skull rather than projecting hair. Use a smaller mature head, a clear ribcage/pelvis relationship, longer athletic limbs, strong shoulders and forearms, and substantial gloves/boots. Fillet keeps compact angular gestures and a red/ivory butcher silhouette; Shark keeps broad shoulders, long diagonals, teal/slate/bone masses and white hair. The head, hand and weapon scale must remain constant across actions; do not stretch a whole sprite vertically to simulate new proportions. Preserve the palette ramps above and one hard-edged shadow grouping per material.

Every phase still normalizes to the same **150 world-pixel standing reference**. Its measured atlas `body_height`, per-pose root and local region are authoritative, including nonuniform cuts around wide weapons. The 64 body fits were authored independently of alpha, with three body regions plus at most one extension. All push dimensions remain stable; tucked-jump drawings lift the feet 50px above the standing foot/root reference, matching the existing air spacing. Fillet's Heavy Slash active was corrected to a forward double cut and fitted to its blades. Shark's moving hook remains a separate generated weapon layer.

`proportions-v2/generation.json` records exact downstream generation/correction prompts, source files and rejection reasons; the two original master prompts are explicitly marked as reconstructed briefs. Original v1 art and collision metadata live in `art/archive/proportions-v1/`. Failed v2 layouts/poses live in `art/archive/proportions-v2-studies/`. Generated pixel files are preserved; changes to pivots, atlas bounds and collision are metadata. Redraws that cross atlas boundaries or substitute attack gestures for defensive poses must be repaired before promotion.

## Selected stances and locomotion v1

Fillet and Shark each add **one ready sprite, eight walk frames and eight run
frames**, bringing the available catalog to **194 poses**. Fillet keeps the low,
wide Stalker silhouette and compact knife carry. Shark keeps F / Shoulder Rest,
blue sports glasses, long low-volume white hair and a controlled shoulder carry
through his forward-driving run. The run has distinct compression, drive and
flight drawings. These are generated iteration loops, with final cleanup and
further in-betweens still available for art feedback.

`locomotion-v1/generation.json` retains exact prompts, references and checksums.
Original generated PNGs are unchanged. Atlas regions, opacity bounds and foot
roots live in the main manifest. Upright body normalization remains 150 game
pixels; Fillet's bent stance naturally appears shorter. Each new pose has three
independently authored body hurtboxes: legs, torso/arms, head. The four-box cap
and existing push dimensions remain in force. Hair, cloth and both weapons do
not add hurt regions.

The core selects ready/walk/run as pose phases 5/6/7. Grounded recovery returns
to the selected ready stance; crouch, jump, attacks and defensive reactions keep
their existing poses. Distance travelled drives eight-frame gait playback:
one frame per five walking-speed ticks or three full-run-speed ticks of travel.
Acceleration therefore slows the run cycle, backward travel reverses the walk,
and hitstop freezes it. Zero velocity at a wall or pushbox returns to ready.
The phase is derived from integer simulation position, speed and facing, so
native, browser preview and rollback require no independent animation clock.

Development → Sprite & collision review now supports **Run**, animated Walk/Run,
manual frame selection, mirroring and per-frame hurtboxes. The browser Move
Workshop uses the same new frames for its walk/run approaches and ready states.
The [offline movement viewer](../exports/FightGuild-Movement-Preview.html) also
shows both complete loops with slow playback, frame scrubbing and hurtboxes.
Rebuild it with `python scripts/build-locomotion-preview.py`.

This pass does not redraw the older attack, jump, block, portrait or intro art.
Those drawings still need the latest costume, hair and eyewear consistency pass.
A separate breathing loop and transition in-betweens remain future animation.

## Smear and effect grammar

Use a shared vocabulary, not unrelated special effects for each image. All swing bands now target **three times their previous perpendicular thickness**, preserving the weapon path, length, guild color and reach. The thin highlight is an edge within that thicker colored band. A smear describes motion and must not obscure the hand, striking limb, or weapon silhouette.

- **Slash:** one tapered crescent following the actual weapon arc. Thin bright inner edge, a single character-accent body, then at most two short trailing wedges. No full circular rings unless the action actually makes that arc.
- **Thrust / dash:** a narrow directional wedge aligned with travel, broad near the source and tapered toward the trailing end. Do not turn a jab into a projectile or put an impact burst on a whiff.
- **Blunt swing:** a short broad arc with two or three angular trailing facets. Reserve radial chips and impact stars for a future contact-dependent impact layer.
- **Smoke:** two or three connected rounded lobes or one curling ribbon, using the same hard-edged value grouping as the cast. No hazy full-cell glow. Smoke's curved vocabulary is an explicit material exception, not a different rendering style.
- Windups have no released smear or impact. Active smears follow the outgoing action. Future impact shapes appear only when contact occurs; they must be separate from the reusable attack pose.

`swings-v3/generation.json` records the generated thickness pass for Anvil S/Hs,
Tapper Hs, Smoke K/S, Fillet Hs and all four Fillet signatures. Only edited
frames select the new images using an optional manifest frame `file` override;
their untouched neighbors and signature windups keep their original pixels.
This is an image-generated **3x thickness target**, not an exact mathematical
dilation of every pixel. Original atlases remain available for comparison.
Widened texture crops use empty gutters where possible. Anvil uses a
registered `render_region` trim with logical atlas margins to remove neighboring
fragments without moving the source pivot or collision coordinates. Smoke S and Tapper Hs have
generated fragment cleanups; Tapper also needed a background-alpha correction. Two rejected cleanups with opaque haze are
preserved under `art/archive/swing-v3-studies/`. Roots, body scale,
attack hitboxes, reach, movement and timings stay unchanged.

Some first-pass active sheets include baked-in flashes, gradients, or inconsistent weapon details. Track and replace these during the consistency pass; do not treat them as new style rules. Body/equipment and effect layers should be separate in the production pipeline.

## Current build contract

Each fighter has a generated active/support atlas a generated windup atlas and a generated block-reaction atlas. Active/support: four columns by three rows for Fillet/Shark v2, six columns by two rows for the other fighters, with idle, P, K, S, Hs, D, two walking poses, jump, hurt, guard, crouch. Windup: three columns by two rows, with a neutral scale reference, then P, K, S, Hs, D anticipations. Block reactions: three columns by two rows, row-major stable contact/settle, pressure contact/hold, guard-break contact/stagger. Stable and pressure maintain a closed silhouette, with pressure more compressed; broken guard opens the arms and chest. No baked-in impact effects in the defensive sheets. The contact pose settles after four unfrozen ticks; hitstop pauses it. PNG alpha, original generated files preserved; atlas regions, foot pivots and scale also anchor separately authored body/strike rectangles. Weapons and effects never extend hurtboxes. Regenerate compiled collision after geometry changes; see [collision rules](collision-rules.md).

The renderer displays windup during startup and the active pose on active ticks, including any hitstop that freezes those ticks. It returns to a ready pose during recovery while the simulation continues to enforce recovery. These are pose changes, not completed animation clips. Slots without dedicated signature art temporarily reuse the corresponding button’s pose. Fillet and Shark add four dedicated windup/active pairs each, taking the original catalog to 160 poses before the 34 new ready/locomotion drawings. Shark’s hook body and generated spear are separate layers; core endpoints direct weapon travel. The initial eight recovery ticks reuse the hook active body during weapon retraction; no new recovery drawing is implied. Every distinct directed action needs its own authored sequence later.

`godot/assets/fighters/manifest.json` records source references, generation filenames, checksums, atlas regions, pivots, and scale. Runtime attack timing comes from the move editor; the initial defensive settle transition is four ticks. `signature-generation.json` records exact signature, weapon-layer and cleanup prompts; `generation-prompts.json` includes the original windup prompts and explicitly marked reconstructed block prompt briefs. Visual silhouettes and smears never determine hit detection.

## Future action specification and review gate

The [Fillet/Shark reference handoff](fillet-shark-references.md#using-an-edited-move-brief-for-the-next-sprite-pass) connects model identity to the workshop's current move JSON, art notes, embedded pose photos, enabled slots, active hitbox keys and optional multi-hit groups. Drawing-sheet arrows and registration marks are illustrative; edited game-space movement, reach and collision remain authoritative. Generate to those values rather than silently changing them to fit a new silhouette.

For each action, record: character master/version, move ID, button, ground/air stance, facing, start/end root position, planted foot, weight shift, contact point/height, weapon grip, attack path, palette version, allowed deformation, and smear type. Reference the same approved neutral model and previous approved frame on every generation request. Keep prompt, references, generator version when available, and all rejection notes; seeds alone are not a consistency guarantee.

The future clip has **windup → active → impact → follow-through → recovery** stages. Each can contain multiple drawings. Impact is conditional on hit/block; a whiff must flow from active to follow-through. Follow-through and recovery are visual subdivisions of existing gameplay recovery until the combat design requires a distinct simulation phase. Current attack generation scope is windup and active only. The separately requested defensive clips add two reaction drawings per block category. Frame counts and timing will be authored per move rather than assumed globally.

Review at game size, on a neutral background, as a silhouette, and beside the master and adjacent frame. Check palette drift, proportion/weapon drift, foot sliding, action direction, alpha halos, clipping/neighbor contamination, and visual contact versus the debug hitbox. Reject failures before packing. Automated checks can validate files, dimensions, alpha, frame completeness, pivots, and hashes; approval of identity, shape language, and action readability remains an art review.


## Tapper normal and rolling kit v1 — 18 November 2026

The generated set in `godot/assets/fighters/tapper-v1/` provides 32 windup/active pairs, one normal ready, four rolling idles, eight walk frames and an eight-pose finite step dash. It keeps the brewer palette, mature anatomy, blond beard/hair, burgundy cloth and double-hook staff. Stance fists are free, with the staff secured across his back. Existing block reactions remain from the previous pass; full impact, follow-through and recovery animation is still on the backlog.

`generation.json` records the original prompts; `repairs.json` records the image-generator corrections for atlas gutters. `scripts/register-tapper-art.py` copies original PNGs without pixel edits, then registers atlas rectangles, roots, body heights and body-only hurtbox fits. `manifest.json` preserves per-frame source filenames/hashes. Rejected edge/gutter attempts are archived in `art/archive/tapper-v1-studies/`. The capture/punch, step and five normal/throw sheets were regenerated to remove adjacent-cell fragments. A render-only crop excludes the next row’s hook from one anticipation cell; roots and collision coordinates stay intact. All new runtime regions were checked for detached fragments. No transition smear frames are used.

Runtime idle animation advances on the fighter's deterministic clock and freezes with hitstop. Walk frames follow distance, while Tapper's step advances by dash age and does not loop as a run. Both renderers read the same art metadata; collision authoring compiles from those pivots/scales. Weapon, cloth and tankard silhouettes do not enlarge hurtboxes. See the [kit guide](tapper-design.md) for action indexing and current utility.

## Smoke normal kit v1 — 18 November 2026

`godot/assets/fighters/smoke-v1/` contains twenty generated windup/active pairs, including charged 6[Hs] and 5[D], plus a separate drifting ember projectile. Compact lime gas defines light checks, broad gray smoke defines spacing tools, and orange/ivory ignition defines heavy attacks. All share Smoke's olive hood, dark hair, ivory coat and strapped alchemist costume. Original generated pixels and exact prompts are preserved in `generation.json`; `scripts/register-smoke-art.py` registers transparent gutters, roots and body-only hurtboxes without editing the PNGs.

The support atlas mixes new standing, crouching, airborne and button poses with the existing walk and reaction drawings. Per-frame body heights keep those retained drawings at their original scale. Each normal selects its own pair through `artPose`; j.D emits the separately rendered ember. There are no added transition smear frames. Full locomotion/reaction consistency and impact/follow-through/recovery drawings remain future passes.

Attack rectangles come from Queen Dizzy's uploaded diagrams, scaled to project units; anatomical vulnerability stays tied to Smoke's own body. Leo diagrams adjust Tapper's normal hitboxes only. See [Smoke's kit and source notes](smoke-design.md) for the trace calibration, missing Leo diagrams and provisional mechanics.

## Knockdown recovery v1 — 18 November 2026

Every fighter now has a separate six-pose face-down/hard sequence and six-pose face-up/soft sequence, including five get-up drawings. The deterministic recovery timer selects the clip; artwork does not change action timing. Tapper uses calibrated source-batch heights across ready, movement, stance and attacks. See [recovery art and scale rules](recovery-art.md) for registration, provenance and review commands. The original PNGs are preserved and no transition smears are used.

## Smoke approved A/H idle loops

Smoke now uses the approved A / Open Current standing loop and H / Uncoiled Vapor crouch. Four body keys per clip and eight separate rear-vapor keys share the saved action clock; no transition smears are added. See [idle registration and review](smoke-idle.md).

Smoke's approved G3 / Suspended Sway has separate advancing and retreating drift
drawings, with R4 / Regal Surge for running. Four drawings per drift play through
eight keys; run and rear vapor each have eight distinct drawings. Source PNGs
are unchanged. Fixed clip scales and four-region anatomical boxes are registered
alongside the art. See [movement registration and review](smoke-movement.md).
