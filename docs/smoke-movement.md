# Smoke — G3 drift and R4 run

**G3 / Suspended Sway** is the approved walk. Advancing leans her upper body
forward; retreating leans backward while she continues facing her opponent.
Legs stay close, heels lifted, with light toe contact. **R4 / Regal Surge** uses
open low palms, compact alternating leg curls and stronger trailing cloth.
Both keep the olive hood, ivory alchemist coat and dark hair from her A/H idles.

Forward and backward drift each have four generated drawings, registered as
eight playback keys (`0,1,2,3,3,2,1,0`). The run has eight distinct drawings.
Each clip uses one standing-equivalent scale and a stable foot root. The run's
two suspended drawings lift slightly without changing her grounded game state.
Gait follows travelled distance: ten nominal walk ticks or five nominal run
ticks per key. Stopping returns to A. Attacks, blocking, jumping and recovery
retain their existing higher-priority poses.

Eight separate gray/olive vapor keys crossfade behind her body. Retreat reverses
the wake independently of body facing; running uses a wider, quicker wake.
The saved action clock drives the effect, so hitstop and rollback apply to it.
It stays inside the owning fighter's foreground group and hides during attacks.
There are no transition smear frames.

The backward drift appends body pose phase 13; forward walk/run use phases 6/7.
All 24 playback keys have at most four anatomical boxes: legs, torso/arms, head,
and a rear forearm/hand extension. Hair, coat, vials and smoke have no hurtboxes.
Movement speeds, dash types, carry velocity, push dimensions and attack tuning
are unchanged. Schema 22 drafts continue to import without resetting edits.

In the browser editor choose **Smoke → Movement & defense → Preview action →
Walk forward / Walk backward / 66 movement**. The same preview supports playing,
scrubbing, facing left and collision overlays. In Godot, **Development → Sprite
& collision review → Walk / Backward drift / Run / step dash** exposes all keys.

Approved sheets are in `art/characters/smoke-movement-v1/`. Exact generation
prompts, source filenames and unchanged PNGs are in
`godot/assets/fighters/smoke-movement-v1/`. Atlas checksums are in the manifest.
To rebuild registration and compiled collision metadata:

```sh
python scripts/register-smoke-movement-art.py
python scripts/generate-combat-data.py
```
