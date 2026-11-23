# Impact effects: direction review

Status: B / Ink Snap selected under the user's delegated choice on 2026-11-23.
Produced for the native Godot game; move-editor website updates remain paused.
The options sheet is not a runtime atlas.
The generated PNG is preserved byte-for-byte; source and hash are in options.json.

Both rows compare cut, blunt, block and counter contacts on a neutral dark board.
Use mature cel-shaded shapes, restrained debris and open negative space, with
ivory/copper hits, ice-blue guard and crimson counter accents. Avoid beams, neon
glow, full-screen flashes and effects that obscure the receiving pose.

- A / Chiseled Impact: straight/angular slash snaps, broad stone chips and a broken
  shield crescent.
- B / Ink Snap: tapered brush hooks, chunky curved bursts and an open ink-ring guard.

Production: transparent generated assets, original files retained,
metadata-only regions/pivots, actual-contact placement and a short held impact that
respects hitstop before clearing. No impact burst on a whiff; weapon trails and
contact effects remain separate. The native review covers hit/block/counter,
Faultless Defense, guard break, multi-hit, airborne and mirrored examples.

The two generated atlases live in `godot/assets/effects/impact-v1/`. Their manifest
records original hashes, regions and contact pivots. See `production-prompts.md`
for the exact generation briefs and `docs/combat-feedback.md` for timing and
verification. Run `python scripts/capture-impact-review.py` for the native review
video; this command does not build or publish the website.
