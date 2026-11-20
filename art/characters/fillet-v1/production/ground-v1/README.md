# Fillet ground normals — production pass 1

The selected ground-normal directions produce **92 pose keys across 11 moves**:
eight per move, with twelve for c.S's authored rising-blade path. The selected
2S is **B / Hip Reap from the second study**. 6P's production drawings correct
the selected study so the short knife follows the red LEFT shoulder/arm.

`*-prompt.txt` and `*-source.json` preserve generation inputs and provenance.
The unchanged PNGs are tracked in
[`godot/assets/fighters/fillet-ground-v1`](../../../../../godot/assets/fighters/fillet-ground-v1).
The corrected 2Hs sheet restores transparent space around the raised knife tip;
its first output is retained in `archive/`. The first 6Hs request failed without
an image; the saved refinement prompt produced the completed solo movement.

`scripts/register-fillet-ground.py` writes atlas regions, sole pivots, virtual
body calibrations and animation keys. It never edits image pixels or changes the
move specification. The current renderer retains its standard mirrored facing
presentation; independently drawn reverse views remain future art work.

This is the first playable raster pass. Exact anatomical/weapon registration,
support-foot entry variants and fully continuous transitions remain refinement
work. Canonical hit/hurt/push geometry remains authoritative; no combat boxes are
resized to fit a drawing. The complete 26-action/pair/locomotion art acceptance
matrix is not claimed by this ground-normal pass.
