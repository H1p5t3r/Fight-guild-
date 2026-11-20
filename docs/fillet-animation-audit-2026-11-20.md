# Fillet animation audit — 20 November 2026

Fillet's timing foundation is already working. This pass keeps the approved
choreography and focuses on three visible defects: c.S's disconnected short
knife, j.K's atlas contamination/body shift, and 623Hs's abrupt arm lowering.
It does not replace the full kit or change combat tuning.

The method follows the supplied [Artemisia College animation guide](https://www.artemisiacollege.com/feeds/blog/fighting-game-animation)
and the [approved project animation standard](attack-animation-standard.md):
readable anticipation/contact/recovery keys, deliberate spacing, stable anatomy,
effects that support the weapon path, and validation against actual gameplay.
The uploaded MHTML's provenance is preserved in
[the source record](../art/characters/smoke-specials-v3/source.json).

## Findings across the kit

All 26 enabled actions were inspected through registered poses, contact sheets,
and 60 Hz simulation recordings. Hit, whiff and a guarding target are separate
recordings. The comparison preserves the actual pre-audit timelines, including
roots, hitstop, damage, landing interruptions and capture clocks.

`S/A/R` = first-active frame / active duration / recovery duration. Frame S is
already active; startup occupies 1 through S−1.

| Attack | S/A/R | Finding / disposition |
| --- | --- | --- |
| 5P | 5/3/9 | Compact loaded short-knife check; first-active extension reads. Retain. |
| 2P | 5/2/10 | Low base and compact check distinguish it from 5P. Retain. |
| 5K | 7/3/13 | Knee load, projected boot and partial retraction are distinct. Retain. |
| 2K | 6/3/11 | Low boot contact remains readable without VFX. Retain. |
| c.S | 7/5/12 | Old short blade stopped behind the narrow strike column; a squashed U-shaped trail floated ahead of it. **Refined reach, grip silhouette and first-active trail.** |
| f.S / 5S | 9/3/18 | Hip-led long-right cut has a clear contact snap. Retain; generic crescent shape is a future VFX refinement. |
| 5Hs | 13/4/22 | Asymmetrical crossed blades read as one heavy contact. Retain; broad effect competes with the two-blade silhouette. |
| 2S | 12/4/23 | Held load, low reach, short finish and withdrawal remain the strongest benchmark. Retain unchanged. |
| 2Hs | 14/5/24 | High forward reach and planted base are readable. Retain; later shoulder lowering can use a future dedicated recovery pass. At this review spacing, a retreating guard can escape its narrow column. |
| 6P | 9/4/20 | Compact shoulder/short-knife guard cut; no premature large extension. Retain. |
| 6Hs | 18/4/25 | Long held load and descending commitment are distinct from f.S. Retain. |
| j.P | 5/3/10 | Compact airborne check stays on the real jump path. Retain attack; legacy neutral-air artwork changes the tuck at release. |
| j.K | 7/4/13 | Old crop included red cloth from the next cell; guessed column boundaries also displaced the striking body. **Corrected gutters and pelvis registration.** |
| j.S | 10/4/17 | Down-forward knife path reads; actual landing can interrupt recovery. Retain; share the neutral-air follow-up below. |
| j.Hs | 13/5/22 | Front-to-rear coverage remains one turning attack, not a second hit. Retain; neutral-air/landing silhouettes remain a follow-up. |
| 236P | 12/3/16 | Compact load to projected needle check, then withdrawal. Retain. |
| 236S | 9/3/18 | Opening cut has a branch-ready finish. Retain. |
| 236S > 6S | 21/3/22 | Shared branch entry and high descending commitment are distinct. Retain. |
| 236S > 2S | 16/3/24 | Low branch remains visually distinct from the high branch. Retain. |
| 236K | 27/3/24 | Passing cut follows its real crossing/travel; camera must include its effect extents. Retain artwork; review framing corrected. |
| 623Hs | 11/5/29 | Old high withdrawal jumped directly to the loaded belt position, then an upright reset. **Added checked-high, elbow-lowering, collection and Stalker-settle keys.** |
| 4P+K | 2/2/32 | Two-frame latch and confirmed capture use the pair clock. Retain owner animation; receiver still uses generic hurt art. |
| 6P+K | 2/2/32 | Same timing correctness; forward capture direction remains distinct. Receiver artwork needs its own pass. |
| 5D | 24/2/20 | Downed-target Wound uses the real capture and bleed setup; zero immediate health damage is intentional. Retain. |
| 236D | 22/2/30 | Hop/landing latch joins capture C0 without a new body pose; knife accents precede the real release event. Retain. |
| 214D | 22/2/30 | Low approach and trailing-foot latch remain distinct from Vault. Retain; dedicated receiver poses would strengthen physical contact. |

“Retain” means no change in this focused pass, not final-art approval. The older
airborne neutral pose, generic receiver reactions and broad shared knife arcs
remain visible limitations. They are recorded in the art backlog.

## Implemented changes

**c.S / Inside cut.** Six generated keys keep the red-shouldered anatomical LEFT
arm on the short reverse-grip knife and the long RIGHT blade passive. The source
columns were individually registered to the same support feet, without scaling
the body per frame. The loaded key holds f2–6. The extended blade snaps into the
forward corridor on f7, holds through f8, then has a smaller high finish f9–11.
Withdrawal/collection/settle occur at f14/17/21 within the existing recovery.
The new narrow red/ivory trail appears only on f7 at shipped timing, including
any hitstop holding that frame. It represents the low-to-high swept path. From
f8 onward the low trail disappears, matching the high-only collision keys.
No floating crescent remains during recovery.

**j.K / Descending kick.** The PNG is unchanged. The old guessed second gutter
was at x1000, cutting into the third figure and including its cloth in the
middle figure. Explicit x500/x945 gutters isolate the six drawings. Individual
pelvis anchors remove the unrelated horizontal body jump when the boot extends;
the source origin no longer follows an assumed equal-column location. Real
airborne movement, downward reach and landing remain simulation-owned.

**623Hs / Rising carve.** Keep the approved load and first-active snap at f11.
Retain the high finish and brief fading effect at f15–19. New keys check the arm
at f23, lower the elbow at f29, collect the long knife at f35 and settle into
Stalker at f40. The move remains locked through f44. Four original generated
drawings use a common source scale; support-foot calibration joins them to the
existing atlas. No airborne rise, extra attack, smearing or added delay occurs.

Ten body drawings and one separate weapon-path effect were generated. Other
source pixels are reused unchanged. Registration, source hashes, prompts and
the precise exposure plan live in
[guide-audit-v1](../art/characters/fillet-v1/production/guide-audit-v1/README.md).
The strongest attacking change remains last startup → first active; smaller
recovery changes do not compete with the strike.

The shipped JSON, canonical per-action hit/hurtbox timelines, movement and
capture rules are unchanged. Source-space fallback hurtbox fits are recalibrated
for the new images and still use at most four anatomical boxes, excluding knives
and effects. Clips use the existing percentage-based phase clocks when timing
is edited. Substantial edits to c.S's active duration/path require reviewing its
one-tick swept trail again; the audited low/high correspondence is for the
shipped five-active-frame attack.

## Review and validation

- [Interactive before/after review](https://h1p5t3r.github.io/Fight-guild-/fillet-motion-review.html?move=c.S): all 26 actions, whiff/hit/guard, 1× playback, slow motion, frame stepping, mirroring, hit/hurtboxes, silhouette and independent effects controls.
- [60fps video](https://h1p5t3r.github.io/Fight-guild-/fillet-animation-audit-60fps.mp4): three changed attacks, sweep and Vault benchmarks, followed by explicitly labeled half-speed inspection.
- [Before pose sheet](../art/characters/fillet-v1/production/guide-audit-v1/previews/key-poses-before.png) / [after pose sheet](../art/characters/fillet-v1/production/guide-audit-v1/previews/key-poses-after.png).

Actions start through the engine's isolated-preview entry point, then use real
combat simulation. This avoids pretending a neutral-input recording can execute
a rekka follow-up or a bleed-dependent capture. The ordinary input/cancel path
remains covered by the existing Fillet runtime tests. A guarding scenario is
not a promise of a block: grabs still capture, and spacing can produce a whiff.

The automated review compares all 78 before/after recordings for identical
movement, actual boxes, contact, damage, hitstop, landing and pair clocks.
Native canonical-geometry tests, both-facing exposure/retiming/replay tests,
Godot art import and browser editor rendering check the production paths as well.
The review camera includes weapon-effect and strike extents in both columns so
the art cannot be silently cropped during a passing cut or tall upward attack.
