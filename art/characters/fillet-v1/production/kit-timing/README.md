# Fillet — full-kit attack timing

The user approved the sweep timing process, directed its use across the rest of
Fillet's kit, and chose the supplied implementation-pack choreography for all
remaining air attacks, specials, throws and Drive moves. The additional rule is
that the largest attacking movement occurs from the final startup pose into
first active. Follow [the shared standard](../../../../../docs/attack-animation-standard.md).

This directory records per-action exposure plans, generated missing artwork,
provenance and whole-kit motion reviews. Gameplay data remain authoritative.

## Installed pass

All 26 actions now use the shared exposure standard: 234 action/FX cues and
34 capture cues, for 268 registered entries. Eleven approved ground attacks
reuse their original consistent drawings. Eighteen new source atlases cover
the remaining fifteen actions and four owner capture sequences; forward/back
throw attempts share one atlas and the two command captures share their finish.
One generated effects atlas extends blade motion to the canonical active
corridors. The approved 2S effect remains in use.

`generated-sources.json` records original source paths, checksums, calibration
and correction prompts. PNGs under `godot/assets/fighters/fillet-kit-v1/` are
byte-identical to those recorded outputs. No painted limb smears, blended
inbetweens or procedural character drawings are added.

`exposure-plans.json` selects the held load and first-active redraw. j.Hs uses a
coiled rear turn before contact, then smaller steps through its rear arc. 623Hs
lowers the elbow before settling to avoid a large late recovery jump. Rekka
branches share their first five ticks and reveal their branch at tick six.
2S omits its old almost-extended pre-contact drawing, retaining six body poses.

Successful capture tracks follow the saved pair clock; Wound's receiver rises
through existing knockdown/get-up art. Other receivers keep their existing
reaction art. No extra capture time, invulnerability or damage is introduced.
Actual landing, interruption, cancel, hitstop and facing decisions take priority
over the drawings. Edited phase lengths scale their existing exposure keys.

## Rebuild and review

1. `python3 scripts/register-fillet-kit.py`
2. `python3 scripts/generate-combat-data.py`
3. `bash scripts/build.sh` and `bash scripts/build-godot.sh`
4. `node scripts/build-workbench.mjs`
5. `node scripts/capture-fillet-kit-review.mjs`

The existing `register-fillet-ground.py` entry point delegates to the full-kit
registrar. `fillet-motion-review.html` includes all 26 attacks, whiff/contact
selection, before/after, facing, hitboxes and frame stepping. The primary MP4
plays at 60 fps and 1× game speed. The detail MP4 is explicitly half speed.

Finished review recordings are saved with this pass:

- [Full kit at game speed](previews/Fillet-Full-Kit-60fps.mp4): all 26 actions,
  before/after, on whiff and on contact or capture.
- [Motion details at half speed](previews/Fillet-Motion-Details-Half-Speed.mp4):
  2S, j.K, j.Hs, the low rekka branch, 623Hs, 236D and back throw.
- [Capture manifest](previews/capture.json): simulation-frame counts for each
  clip. The videos preserve real hitstop and capture clocks; the slow version
  duplicates frames instead of generating interpolated poses.

The older `capture-fillet-motion-review.mjs` remains a sweep-only entry point
and resolves 2S by action ID so roster order cannot select another move.

This remains a first playable raster pass. Separate reverse-view drawings,
bespoke receiver art for every matchup and further pose/hurtbox refinement
remain future art work; rendering still uses the established facing mirror.
