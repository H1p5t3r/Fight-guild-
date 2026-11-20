# Smoke specials — attack timing and recovery

See the [audit and exposure notes](../../../docs/attack-animation-audit-2026-11-20.md).

The approved Venom Sabre / Furnace Cleaver backhands and P2 Smoked Obsidian
pillars are retained. `sources.json` lists two immutable generated PNGs (eight
recovery drawings), prompts and references. Runtime atlases live in
`godot/assets/fighters/smoke-specials-v3/`.

`baseline-art.json`, `baseline-collision.json`, `baseline-moves.json` and
`before.json` preserve the pre-change state. Registration appends 37 timed cues
after Smoke's original 32 animation entries and replaces only slots 14, 25, 15
and 16. `exposure-plans.json` records the exact default frame of each key.

Repeatable registration:

```sh
python scripts/register-smoke-specials-v3.py
python scripts/generate-combat-data.py
bash scripts/build.sh
bash scripts/build-godot.sh
node scripts/build-workbench.mjs
node scripts/capture-smoke-review.mjs
```

Rebuild/package both Windows DLL targets after compiled animation data changes.
The current workshop JSON remains unchanged; old local drafts retain their
tuning and use these clips when their four art selectors match.
