# Fillet and Shark — reference 03

These remade reference candidates bring the character guides up to the current
sprite and move-authoring requirements. Each fighter has a model page and a
separate signature-action page. They establish the next drawing reference;
the playable v2 atlases, move values and collision data remain as they were.

| Fighter | Model sheet | Windup / active sheet |
| --- | --- | --- |
| Fillet | [Anatomy, costume, knives and palette](../art/characters/fillet.png) | [Knife spiral and rekka](../art/characters/fillet-actions.png) |
| Shark | [Anatomy, costume, hook and short blade](../art/characters/shark.png) | [Ground/air hooks and follow-ups](../art/characters/shark-actions.png) |

[Download the four-page PDF](../exports/FightGuild-Fillet-Shark-References-v3.pdf).
The [six-character reference PDF](../exports/character-reference-guides.pdf)
also contains the updated model pages. Exact prompts, input snapshots, checksums
and correction notes are in [the generation record](../art/characters/reference-generation-v3.json).

## Shared model rules

- Target 7.5–8 anatomical skull-heads in an upright body, excluding projecting
  hair. Keep mature faces, strong shoulders and forearms, long athletic limbs,
  substantial hands and boots. Preserve head size across crouches and aerial poses.
- Use a right-facing side/three-quarter gameplay camera, one neutral upper-left
  light, hard cel shadows, a strong outer contour and finer internal lines.
- Keep costume construction, anatomical shoulder side, grips, weapon length and
  material colors consistent. Front/side/back drawings are visual guides, not
  certified orthographic model plans; resolve small construction differences
  against this specification before modeling or atlas production.
- Preserve the current 150-game-pixel standing normalization and authored
  root/pushbox dimensions when making runtime assets. A larger drawing, wider
  attack or longer weapon does not enlarge the fighter's body or pushbox.
- Use separate body, equipment and FX layers in production. These opaque reference
  boards illustrate those layers; they are not transparent, separated sprite files.

| Character | Shape and costume landmarks | Palette targets |
| --- | --- | --- |
| Fillet | Compact angular gestures; short swept brown hair; crimson **left** shoulder armor; ivory blouse; crimson corset; split ivory apron; charcoal trousers; wrapped forearms; three-buckle boots. | Crimson `#A63242`, ivory `#DDD0B1`, charcoal `#393039`; muted brown leather/hair and silver steel. |
| Shark | Broad swimmer shoulders and lean waist; long grouped white hair; teal eye mask and scale vest; bone jaw on **left** shoulder; rope belt and hip net; split teal sash; gray trousers; wrapped boots. | Teal `#258A99`, slate `#34454D`, bone `#D9D4BD`; muted brown rope/leather and silver steel. |

These hex values are authoring targets. Generated shaded pixels and the printed
swatches have not been quantized to exact material ramps.

## Equipment and directed actions

Fillet carries the longer broad, curved, single-edged butcher knife in her
**right hand**, with the shorter companion in her **left**. Keep the broad
slicing profiles from the equipment studies; do not substitute pointed fantasy
daggers. Her anatomical left shoulder remains armored when a pose turns.

| Fillet input | Windup and active direction |
| --- | --- |
| `236K` | Load a low coil, then travel forward in a knife-led corkscrew. Root travel and rotation must read separately from an ordinary grounded lunge. |
| `236S` | Load the blade low, then slash upward and forward. |
| `236S > 6S` | Chamber the main knife, then stab forward at torso height. |
| `236S > 2S` or `236S > 6S > 2S` | Sink into a low stance, then slice toward shin level. The low finisher is a soft knockdown. |

The action-page headings `6S` and `2S` abbreviate the rekka follow-ups. They do
not define new standalone command normals. The two permitted routes are printed
under the drawings.

Shark carries the long rope-wrapped hooked shaft in his **right hand**, and
the separate short, broad triangular blade in his **left**. The long weapon has
one continuous open metal hook attached to its shaft, with a butt ring. Keep the
short blade distinct; no second spearhead, floating crescent or trident.

| Shark input | Windup and active direction |
| --- | --- |
| `214S` | Grounded coil into a hook cast **45° upward**. Keep a planted foot and readable throwing shoulder. |
| `j.214P` | Airborne coil into a hook cast **45° downward**. Feet remain clear of the ground and anatomical scale stays unchanged. |
| `P` after a grounded hook hit | Chamber, then stab horizontally with the short blade; the hook retracts away from the contact path. |
| `P` after an aerial hook hit | The same short-blade action with a tucked airborne silhouette. |

Both hooks pull the opponent close. Their P follow-ups require a hook **hit**;
block or whiff does not grant the follow-up. The released hook, tether and body
must be separate runtime layers. The diagram arrows illustrate direction; use
the core's exact path and range, not a measurement of a drawn arrow.

## Fillet ready-stance options

[Compare six ready-stance candidates](../art/characters/stance-studies/fillet-01.png).
They explore posture and personality while retaining reference 03's character
design. No stance has been selected or substituted into the playable atlas.

| Option | Direction |
| --- | --- |
| A — Stalker | Low forward pressure; main blade low, offhand close. |
| B — Duelist | Tall, narrow and economical; main knife presented forward. |
| C — Crossed Blades | Compact centered guard; crossed knives frame the torso. |
| D — Coiled | Wide base and weight drawn back; ready to spring forward. |
| E — High Guard | Main knife high, offhand low; open, confident body language. |
| F — Unbothered | Relaxed shoulders and low hands; calm threat. |

These are selection studies, not matched idle-animation frames. C turns farther
toward the viewer, and A explores a downward offhand grip. Once a direction is
chosen, standardize camera, grips and body scale against the model, then develop
the breathing/weight-shift loop and check its silhouette with the current
body-only hurtboxes. [Generation notes](../art/characters/stance-studies/fillet-01.json)
retain the exact prompt, source reference and image checksum.

The user's next preference is **the leg spacing of B and F**. Carry that narrower,
natural stagger into subsequent ready-pose work. This selects the lower-body
spacing, not either complete stance or an upper-body posture.

[The second comparison sheet](../art/characters/stance-studies/fillet-02.png)
uses that base for four upper-body alternatives:

| Option | Upper-body direction |
| --- | --- |
| G — Low Ready | Relaxed low hands, with the offhand near the belt. |
| H — Close Guard | Knives held close to the torso at separate heights. |
| I — High Knife | Main knife beside the head, offhand low. |
| J — Forward Guard | Main blade presented forward, offhand near the face. |

The narrower spacing is an artwork direction, not a pushbox-width change.
Upper-body selection, final grip/weapon cleanup and the idle loop remain open.
[Refinement provenance](../art/characters/stance-studies/fillet-02.json) records
the exact feedback, references, prompt, checksums and remaining drawing checks.

## Using an edited move brief for the next sprite pass

1. Start with the user's latest **Move Workshop JSON**, including `_moveWorkshop`
   notes, embedded pose photos, phase tags and captions. A later Godot-only export
   does not preserve that artwork metadata. Read [the workshop exchange notes](move-workshop.md#preview-and-data-conventions).
2. Check whether the move is enabled. An optional command-normal slot does not
   require finished attack art merely because the data slot exists. Respect its
   input, stance, cancel route and intended action.
3. Read startup, active windows, active hitbox keys, hurtbox profiles, movement,
   inertia and contact properties. Use the editor's distance guides in **game
   pixels** for root travel and reach; sheet pixels are not game coordinates.
4. Record the selected model revision, facing, foot/root anchors, target height,
   weapon grip/path and allowed silhouette deformation. Pose photos supply
   gesture and intent; the model sheet supplies identity and equipment.
5. Generate **windup and active** drawings first. Active hitbox keys can require
   different contact poses over time. Multiple boxes or keys do not automatically
   mean multiple hits: follow the move's multi-hit switch and hit groups.
6. Fit the drawing to the intended motion and authored contact region, then
   review it with the edited geometry in both facings. Do not silently change
   collision values, timings, hit groups or root travel to accommodate art drift.

Keep at most **four body hurtboxes per pose**: legs, torso-and-arms, head, and
one optional extension for a complex pose. Weapons, tether, hair trails and FX
do not extend hurtboxes. Pushboxes remain separate body-separation geometry.
Minimum attack startup remains **5 frames**; a dramatic windup drawing does not
override that rule or the edited duration.

Most fighters, including these two, run forward rather than taking a short
forward dash. Carry the authored run velocity into attacks. Pin a foot only while
the move actually plants it; never fake root travel by sliding a stationary body.

## Effects and remaining animation work

Both pages use the same small effect vocabulary: a tapered crescent with a thin
light inner edge, a narrow directional thrust wedge, and at most two short
trailing pieces. Recolor within the guild palette. Windup has no released smear;
active follows the real blade path. Impact sparks belong to hit/block contact,
not to a reusable whiff drawing.

The four action pairs per fighter are pose-direction studies, not all attacks or
complete animation clips. Dedicated P/K/S/Hs/D variants, command normals, `2D`
sweep and `4P+K` / `6P+K` throws still need their own reviewed move briefs.
Stable block, compressed pressure block and open guard-break reactions retain
their separate body-language requirements for the subsequent defensive pass.

Later clips will cover windup, active, conditional impact, follow-through and
recovery. Keep the last three stages on the backlog until the first two and the
move data are reviewed. Reference-page poses still need adjacent-frame,
game-size, mirrored-facing, palette and weapon/grip checks before runtime use.

## Provenance and reproduction

The previous two model sheets and six-page PDF are preserved in
`art/archive/reference-guides-before-v3/`. Two intermediate generations in
`art/archive/reference-v3-studies/` record the corrected head ruler/shoulder
thumbnail and detached hook diagram. Source PNGs are copied without pixel edits.

Rebuild the two PDFs from the checked-in PNGs with:

```sh
python3 scripts/build-character-references.py
```

This uses Pillow to inspect image dimensions and ReportLab to embed the original
images. It does not regenerate or retouch artwork.
