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

## Iron Dominion — complete

[Watch the native 60 FPS review](../exports/FightGuild-Iron-Dominion-V3-2026-11-26.mp4)
(21.03 seconds, sound; hit, mirrored hit, block and miss).

Twenty replacement drawings move Anvil from a back-facing coil into a long
horizontal shield sweep, a rising crescent, an overhead crush and a deep final
plant. The free hand, shoulders, hips, knees, beard and apron follow the turn.
Six magma-orange effects trace the shield path with open centers; the larger
crescents sit behind the fighters so both silhouettes remain readable.

The striking drawings land on the saved impacts at ticks 40 and 70. The final
plant starts on the actual release at tick 90, holds through the 22-frame impact
freeze, then passes through six recovery drawings over the existing 24 frames.
Blocked and missed openings return directly to guard without playing a false
finisher. Damage, armor, frame data and cost remain unchanged.

All twenty drawings share one anatomical scale. The left arm owns the shield,
the tattoo belongs only to the empty right arm, and pause masks exclude the
visible gripping hand. Original generated PNGs remain unmodified.

The dedicated animation and native super suites passed 27,206 checks with no
failures. The [validation record](../art/characters/supers-v3/iron-dominion/validation.json)
records the video hash and checks; the
[fixed-scale sheet](../art/characters/supers-v3/iron-dominion/scale-review.png)
shows every drawing beside the approved idle.

## Freemason — complete

[Watch the native 60 FPS review](../exports/FightGuild-Freemason-V3-2026-11-26.mp4)
(21.03 seconds, sound; hit, mirrored hit, block and miss).

Twenty new drawings restore Hammer's original armor, anatomy, palette and cel
shading. His hips and shoulders lead a horizontal hammer sweep, rising arc,
overhead descent and final horizontal crescent. Scarf and tabard lag behind each
turn, then settle during the six-drawing return to his original guard.

Contact poses stay on ticks 40 and 70, with the final sweep on release at tick
90. The final pose holds through hitstop before the longer overtravel and
regather. Block and miss tracks withdraw the opening swing directly. The move
retains its 360 damage and existing gameplay timings.

All twenty keys use one anatomical scale, checked beside the original idle.
Two handle corrections remove a hand-like detail and a split shaft; the final
art has exactly two hands gripping one continuous hammer handle. Six separate
blue and ivory crescents follow the weapon path behind the body.

The revised strike supers also use the existing receiver reaction drawings
through their captured sequences. Each saved impact starts on strong recoil,
then settles into a sustained stun drawing; airborne receivers use the air
family. This fixes neutral poses between cinematic hits without altering the
receiver's position, stun, collision or capture rules. Iron Dominion uses the
same correction; Sky Foundry retains its authored carry animation.

The targeted Freemason, Iron Dominion and Sky Foundry checks passed 65,976
assertions with no failures. The [validation record](../art/characters/supers-v3/freemason/validation.json)
records the footage hash and checks; the
[scale sheet](../art/characters/supers-v3/freemason/scale-review.png) compares all
twenty poses against the original idle.

## Grand Design — complete

[Watch the native 60 FPS review](../exports/FightGuild-Grand-Design-V3-2026-11-26.mp4)
(hit, mirrored hit, block, miss and an actionable follow-up).

Twelve replacement drawings take Hammer from his original guard through a
rear hip coil, overhead load, sudden ground plant, compressed overtravel and a
measured return. The scarf and tabard follow the torso rotation. The large blue
and ivory crescent stays behind his silhouette; a separate six-drawing stone
wave keeps a consistent collision-readable size throughout its lifetime.

Recovery increases from 10 to 18 frames to fit the weighted landing. Startup,
projectile spawn, damage, cost and wave lifetime remain unchanged. Hammer still
regains control while the wave is traveling and can follow its launch with a
normal attack. All twelve drawings finish within his actual action clock.

The fixed-world comparison checks every pose against the original idle at one
anatomical scale. Cast tests cover both sides, pause, replay, edited timing,
projectile animation and independent caster control. The native roster and C++
super checks also pass; both Windows DLLs and the repair ZIP were rebuilt for
the revised frame data. See the
[validation record](../art/characters/supers-v3/grand-design/validation.json) and
[scale sheet](../art/characters/supers-v3/grand-design/scale-review.png).

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
