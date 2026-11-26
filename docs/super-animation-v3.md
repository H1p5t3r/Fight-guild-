# Super animation revisions

The [super-specific direction](super-animation-standard.md) replaces the evenly
paced, smaller movements of the first full pass. Use the approved in-game model,
full-body crescent motion, sudden impact and a longer finish. This pass proceeds
one super at a time. The [v2 production record](super-animation-production.md)
retains the previous drawings, references and reviews.

## Sky Foundry — complete

[Watch the native 60 FPS review](../exports/FightGuild-Sky-Foundry-V3-2026-11-26.mp4)
(16.08 seconds, sound; catch, mirrored catch and grounded miss).

Sixteen replacement body drawings take Anvil through a deep hip coil, a long
upward catch, an airborne arch and tuck, an overhead crescent slam, low overtravel
and a measured return to High Clamp. His empty right hand performs the grab;
the left shield, spine, hips, legs, head, beard and apron counterbalance and
follow the action. Six replacement magma effects outline that path with open
centers so the body remains readable.

The final slam and first overtravel were corrected after review: the far shield
arm now sits low behind the rear hip. This separates its shoulder/forearm from
the near striking arm and removes the extra-arm reading in the original finish.
The [source history](../art/characters/supers-v3/sky-foundry/source-history.json)
retains the superseded drawings and the correction prompts.

The pose exposures changed: the airborne tuck arrives earlier, the compressed
load holds before the final hit, and the low finish lasts longer before the
regather. This fits the current 112-tick capture and 24-tick recovery. The final
slam still starts on the real release/damage frame and holds through hitstop.
Damage, cost, capture eligibility and gameplay timing did not need changing.

The native review checks the actual hand attachment and depth, every body key,
both facings, all six receivers, misses, pause and replay. The combined targeted
run passed 175,453 assertions across ten suites, plus feedback/audio checks.
The [validation record](../art/characters/supers-v3/sky-foundry/validation.json)
records exact results and the video hash. The
[fixed-world-scale comparison](../art/characters/supers-v3/sky-foundry/scale-review.png)
shows every drawing beside the approved idle with effects hidden.

```bash
python scripts/register-super-presentation.py sky-foundry --version v3
bash scripts/godot.sh --headless --editor --import --quit
bash scripts/godot.sh --headless --audio-driver Dummy --script res://tests/sky_foundry_test.gd -- --test
python scripts/capture-super-animation.py sky-foundry --version v3
```

## Size calibration

The first visual comparison covered all 196 v2 super body drawings against their
approved neutral references at a fixed world zoom. Hammer's two supers were
reduced by 7.6%, Tapper's by 7.8%, Shark's by 11.1%, and Fillet's by 20%. Anvil and
Smoke did not need the same blanket correction. These are visual calibrations,
not automated anatomical measurements. Each super uses one body scale through
all poses; no drawing is fitted to its silhouette bounds. New replacement art
is checked again against the same references as it is completed.

The broader source inventory contains 1,110 unique main-manifest body cells,
including legacy drawings; it is not a claim that every cell is used in play.
The motion/style revisions here are restricted to supers. Ordinary attacks,
locomotion and the Move Workshop are unchanged.
