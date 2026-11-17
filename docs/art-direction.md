# Art direction

## Target

Faithful Guild Ball character identities translated into an Arc System Works / Guilty Gear Strive-inspired fighting-game visual language. The intended eventual presentation is stylized 3D with carefully authored anime shading.

The generated images are visual concepts. They do not establish a working 3D shader, consistent model geometry, a rig, or finished game assets.

## Feedback history

1. Three initial directions explored painterly fantasy, graphic ink, and living miniatures.
2. The user chose the graphic ink direction as closest, but asked for a stronger ArcSys influence.
3. A more saturated cel-shaded fight scene was judged very close stylistically. Missing 3D form and inaccurate characters remained problems.
4. The user supplied six custom character reference sheets from another project to ground identity and costume.
5. A subsequent volumetric Smoke/Hammer render study drifted toward conventional detailed fantasy rendering and was rejected as too far from ArcSys.
6. The user requested remaking all six complete reference guides in the game's new style.
7. The user required original miniature weapons. The current guides incorporate a reference-based equipment correction pass.
8. Fillet and Shark's reference 03 set remakes the model guides around the mature anatomy and adds separate signature windup/active pages. Matching layouts, material palettes, fixed weapon studies and detached FX samples support repeatable action drawing. See [the reference pack and editor handoff](fillet-shark-references.md).
9. The user selected **A / Stalker** as Fillet's standard combat stance, superseding the interim B/F leg-spacing preference. Reference 05 also selects Shark F / Shoulder Rest and replaces his face paint with blue sports glasses, retaining long, lower-volume white hair.

The current six sheets remain candidates for review. Do not treat the latest generation as user approval.

The native Godot sprite studies now use the [sprite production contract](sprite-production.md). It defines shared palettes, silhouette rules, smear shapes, directed-action briefs and the initial windup/active scope. Building a repeatable pipeline for these six fighters and future characters is tracked in [the backlog](backlog.md).

## Working visual rules

- Strong silhouettes and distinct body types across the roster.
- Sharp, expressive faces; graphic grouped hair; exaggerated hands, boots, poses, and perspective where useful.
- Coherent volume with crisp two- or three-tone shadow shapes and selective outlines.
- Broad readable clothing and equipment shapes. Simplify repetitive buckles, scratches, and fine texture.
- Clear guild palette accents over recognizable clothing and materials.
- Preserve identifying faces, hair, equipment, and signature garments from supplied references.
- Use miniature sources as the authority for weapon silhouettes where earlier sheets differ.
- Keep effects readable at gameplay distance. Smoke's clouds should expose timing and position without hiding fighters.

Avoid drifting back into parchment illustrations, etched hatching, realistic metal gradients, miniature photography, or generic fantasy redesigns.

## Reference guide contents

Fillet and Shark each have a model page with aligned front/side/back studies, expressions, equipment, palette, ready pose and FX samples, plus a signature-action page with four windup/active pairs. The other four guides retain their hero pose and combat thumbnails. Generated views and proportions still require consistency checks before modeling; some views are closer to three-quarter than strict orthographic.

## Review checklist for the next art pass

- Is the character recognizable from the supplied identity reference?
- Are the original weapon silhouette, grip, proportions, and handedness consistent across views?
- Do body proportions, garment construction, and asymmetrical details remain consistent?
- Are front, side, and back views usable as true modeling references?
- Does the shading suggest solid volume while retaining the intended anime graphic treatment?
- Are the roster's silhouettes and combat poses sufficiently distinct?

Keep superseded images in `art/archive/`; promote changes into `art/characters/` deliberately and update the asset manifest.

Fillet/Shark use their selected Stalker and Shoulder Rest ready sprites and [eight-frame locomotion loops](sprite-production.md#selected-stances-and-locomotion-v1), with [reference 05](fillet-shark-references.md) as the character authority. Older v2 attack/defense art remains pending its next consistency pass. Swing bands across the roster target 3x previous thickness without changing attack reach. Their previous guides are archived. The other four fighters await the same proportion pass.

## Appearance revision 06

Fillet keeps the selected A / Stalker stance, with black swept hair and leaner arms (about 20–25% narrower). The ready, eight-frame walk/run cycles, button windups/active poses, block reactions and signature attacks now use that appearance. Her frame regions, pivots, body scale and combat geometry stay registered to the previous sheets. The HUD portraits also carry her black hair and Shark’s lower-volume long hair and blue sports glasses.

Current references: `art/characters/reference-generation-v6.json` and `exports/FightGuild-Fillet-Shark-References-v6.pdf`. Runtime generation prompts, source hashes and unchanged PNG outputs are recorded in `godot/assets/fighters/appearance-v3/generation.json`. Previous references remain in `art/archive/reference-guides-v5/`; the first run-sheet alpha attempt remains archived. New projectile effect art is available for the authoring pass.
