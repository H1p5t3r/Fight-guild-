# Hammer kit v1 — A / Shoulder Drive

The user selected **A — Shoulder Drive: compact and forceful** from `direction-options.png`. `approval.json`, `prompts.json` and `sources.json` retain the decision, generation prompts and source SHA-256 values.

Eleven generated body atlases contain load / strike / withdrawal studies, idle/crouch and throw material. A separate effect atlas contains horizontal, rising and descending hammer arcs plus burst dust. Runtime PNGs are copied without pixel editing. Registration changes only crops, anatomical landmarks, pivots and fixed per-atlas scale.

`timing-plan.json` places 142 action/capture cues across 23 enabled actions and four paired throw tracks; eight additional idle keys reuse subtle held drawings. These numbers describe registered cues, not unique drawings. The last startup frame retains the loaded pose; the largest release occurs on the first active frame. Active poses hold through contact and hitstop. Recovery removes the separate strike effect, then brakes, withdraws and settles. No interpolation, crossfade, automatic body smears or per-frame zoom is used.

`registration.json` records the counts and policy. The collision atlas uses legs, torso/arms, head and at most one anatomical extension. Hammer heads, shafts, scarf, tabard and effects do not extend hurtboxes. The attack overlay ends at the authored hitbox reach.

Reproduce:

```sh
python scripts/author-hammer-kit.py
python scripts/register-hammer-kit.py
python scripts/generate-combat-data.py
bash scripts/build.sh
bash scripts/build-godot.sh
node scripts/build-workbench.mjs
./build/hammer-drive-tests
node tests/workbench-hammer.mjs
node tests/workbench-hammer-browser.mjs
bash scripts/godot.sh --headless --script res://tests/hammer_test.gd
```

Review: `hammer-motion-review.html` in the hosted/portable workshop. It records the shared combat engine, including real positions, guard, hitstop, Drive resource and velocity. [Kit specification](../../../docs/hammer-kit.md) describes the provisional balance values and remaining legacy movement/reaction art.
