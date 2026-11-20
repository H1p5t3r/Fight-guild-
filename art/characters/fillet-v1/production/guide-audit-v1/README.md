# Fillet — guide audit v1

Focused refinements to the approved kit: c.S inside-cut reach, j.K atlas/pelvis
registration and 623Hs recovery. See the [audit](../../../../../docs/fillet-animation-audit-2026-11-20.md)
for all 26 findings and remaining work.

- `before.json`: actual pre-audit whiff/hit/guard recordings, captured on dd9b7b2
  before changing sprite registration. No synthetic old art on a new clock.
- `baseline-art.json`, `baseline-collision.json`: registration baseline.
- `sources.json`: original image-generator files, hashes, prompts and calibration.
  The final PNGs are committed unchanged in `godot/assets/fighters/fillet-guide-audit-v1`.
- `exposure-plans.json`: final registered keys for the three affected actions.
- `previews/`: 60fps MP4 and before/after pose sheets. Half-speed sections duplicate
  simulation ticks; they do not interpolate body parts.

Run `python scripts/register-fillet-guide-audit.py`, then regenerate combat data,
rebuild the core/native extension and package the workshop. The canonical
`register-fillet-kit.py` also reapplies this audit after its base registration.
Registration is idempotent and leaves unrelated actions, captures, fighter art
and workshop tuning untouched. Fillet now has 235 action cues and 36 capture cues.

The first c.S generation improved the arm but still fell short; the saved
`cs-reach-correction-prompt.txt` produced the final atlas. Its second and third
columns placed the body 32 source pixels left of the first. Matching pivots
correct that placement without altering, stretching or repainting the PNG.
The j.K source also remains byte-identical: regions and pelvis pivots fix its
cell contamination and registration.

Use `node scripts/capture-fillet-audit.mjs` after building the workshop to recreate
the review video and contact/pose sheets. `--stills` skips video encoding.
