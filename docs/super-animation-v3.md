# Super animation revisions

All twelve supers have been revised and reviewed individually using the
[super-specific direction](super-animation-standard.md): approved in-game models,
full-body crescent motion, sudden impact and a longer finish. The pass includes
232 body drawings, 72 effect drawings and twelve projectile drawings. The
[v2 production record](super-animation-production.md) retains the previous art.

[Watch all twelve supers](../exports/FightGuild-All-Supers-Animated-V3-2026-11-26.mp4)
at native 60 FPS with sound (63.1 seconds). Chapters identify each fighter and
super; Exsanguinate demonstrates the stored-bleed cash-out. The accompanying
[manifest](../exports/FightGuild-All-Supers-Animated-V3-2026-11-26.json) records
source hashes and exact frame ranges. No footage is retimed for the showcase.

Each animation has a separate native hit/miss review, mirrored coverage,
block coverage where applicable, source provenance and a fixed-world-scale
comparison against the approved idle. The only combat timing change is Grand
Design's recovery from 10 to 18 frames; all other changes in this pass are
presentation changes. The Move Workshop remains paused.

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

## Flashpoint — complete

[Watch the native 60 FPS review](../exports/FightGuild-Flashpoint-V3-2026-11-26.mp4)
(hit, mirrored hit, block and miss).

Twenty new body drawings replace the upright arm-led motion with a reversed
hip-and-spine coil, forward backhand, low gather, rising reach, descending
compression and a wide two-palm ignition. Hair, coat tails, knees and the free
arm counterbalance each turn. Six separate flame crescents and ember drawings
leave the body readable. The model, costume and one anatomical scale follow
Smoke's original almost-weightless idle.

The opening snaps into contact, then the later contact drawings land at ticks
37 and 65, with the final ignition on release at 84. A longer series of recoil
and settling drawings uses the existing recovery clock. Block and miss tracks
withdraw from the opening only. Gameplay timing, damage and cost are unchanged.

The first atlas was rejected for repeating the ordinary attack's motion. The
replacement's missing striking arm was corrected before registration; the
[source history](../art/characters/supers-v3/flashpoint/source-history.json)
retains both decisions. Native checks passed 19,645 assertions with no failures.
See the [validation](../art/characters/supers-v3/flashpoint/validation.json) and
[fixed-scale comparison](../art/characters/supers-v3/flashpoint/scale-review.png).

## The Air Is Mine — complete

[Watch the native 60 FPS review](../exports/FightGuild-The-Air-Is-Mine-V3-2026-11-26.mp4)
(hit, mirrored hit, block, miss, near placement and far placement).

Twelve replacement body drawings wind through a bow, rising torso and crossed
wrists, then open into a broad curtain gesture. The shoulders, pelvis, free
leg, hair and coat continue the turn before settling back to Smoke's original
toe-touch idle. All poses use the same anatomical scale.

The field has six new looping smoke drawings with grey/olive ribbons, acid-lime
edges and transparent gaps. Six separate release/contact effects make the
opening larger and distinguish each real pulse. The stationary field still
uses its own saved clock after Smoke recovers; near/middle/far placement and
clearing on interruption are unchanged.

The cast suite passed 6,735 checks with no failures, covering every body and
field key, actual contact pulses, both sides, block, miss, pause, replay,
placement, interruption and edited timing. See the
[validation](../art/characters/supers-v3/the-air-is-mine/validation.json) and
[fixed-scale comparison](../art/characters/supers-v3/the-air-is-mine/scale-review.png).

## Last Orders — complete

[Watch the native 60 FPS review](../exports/FightGuild-Last-Orders-V3-2026-11-26.mp4)
(hit, mirrored hit, block and miss).

Twenty-four body drawings give Tapper a low hip load, two rising uppercut
crescents, a deep weave and two committed forehead strikes. His pelvis, spine,
shoulders, feet, hair, cape and tankard all participate. The original costume,
anatomy and single stowed staff remain consistent through the action.

Connected hits settle through six follow-through and recovery drawings into
Dempsey guard. Block and miss instead use four dedicated drawings to take the
staff off his back and return to regular guard. Six separate amber/ivory ink
effects accent the saved contact beats at 0, 43, 74 and release at 96. Gameplay
timing, damage and cost remain unchanged.

The native suite passed 20,513 checks with no failures. All 24 body keys were
compared against the approved idle at fixed world scale; the review tool now
expands to show more than twenty keys. See the
[validation](../art/characters/supers-v3/last-orders/validation.json) and
[scale sheet](../art/characters/supers-v3/last-orders/scale-review.png).

## Whiskey Chaser — complete

[Watch the native 60 FPS review](../exports/FightGuild-Whiskey-Chaser-V3-2026-11-26.mp4)
(hit, mirrored hit, block and miss).

Twenty replacement body drawings put each hook through Tapper's hips, spine,
shoulders and pivoting feet. The near/far/near punches use distinct silhouettes,
with a lower body hook and a larger final turn that exposes his back before
unwinding into Dempsey guard. Hair, cape, tankard and tabard follow the rotation.
Six amber/ivory ink crescents remain separate from the body art.

The three blocked contacts retain poses 1, 6 and 10 on active frames 1, 5 and 9.
The confirmed sequence retains impacts at 43 and 74, then release at 96, with
six additional settling drawings spread through the existing recovery.
Damage, stance behavior, timing and cost are unchanged.

The suite passed 20,553 checks, including all twenty drawings, both players and
facings, all receivers, blocked contact alignment, pause and replay. See the
[validation](../art/characters/supers-v3/whiskey-chaser/validation.json) and
[fixed-scale comparison](../art/characters/supers-v3/whiskey-chaser/scale-review.png).

## No Safe Harbour — complete

[Watch the native 60 FPS review](../exports/FightGuild-No-Safe-Harbour-V3-2026-11-26.mp4)
(hit, mirrored hit, block, distance miss, tip-range hit and airborne miss).

Twenty new drawings give Shark longer lunges, a backward hip reel, a rising
hook crescent and a committed final drive. His legs, pelvis and shoulders carry
the polearm; hair, tabard and netting follow the turn. Both hands share one
continuous shaft until recovery returns it to his shoulder and draws the knife.
The original white hair, blue sports glasses and lean proportions are retained.

Six teal/navy/ivory effects give the reel and finish broad crescent silhouettes.
The opening wake still follows the long horizontal reach and stops at the
guard contact. Block and miss recover from the opening alone. The saved
43/74/96 contact beats, damage and cost remain unchanged.

The native suite passed 20,601 checks with no failures. All twenty poses were
reviewed at fixed scale against the original idle, including the long return.
See the [validation](../art/characters/supers-v3/no-safe-harbour/validation.json)
and [scale sheet](../art/characters/supers-v3/no-safe-harbour/scale-review.png).

## Undertow — complete

[Watch the native 60 FPS review](../exports/FightGuild-Undertow-V3-2026-11-26.mp4)
(hit, mirrored hit, block and miss).

Twenty-four new drawings take the hook from a deep low sweep through an overhead
reel, a planted turn and a left-facing downcut. The follow-through returns Shark
to his shoulder-rest stance facing his new opponent position. Four separate
right-facing recovery drawings handle blocks and misses without playing the
side-switch. Hair, torso, hips, netting and feet participate in the turn.

Six teal/navy/ivory crescents follow the hook path, with the final impact aligned
to the receiver. The 36/62/80 contact beats, damage, cost and gameplay remain
unchanged. All poses retain one anatomical scale and the paired direction is
preserved to avoid mirroring the turn twice.

The native suite passed 23,933 checks with no failures. See the
[validation](../art/characters/supers-v3/undertow/validation.json) and
[fixed-scale comparison](../art/characters/supers-v3/undertow/scale-review.png).

## Bloodletting — complete

[Watch the native 60 FPS review](../exports/FightGuild-Bloodletting-V3-2026-11-26.mp4)
(hit, mirrored hit, block and miss).

Twenty new body drawings give Fillet a deep coiled opening, a hip-led forward
crosscut, a rising crescent, a committed downcut and a crossed-forearm X finish.
The long right-hand knife and short left-hand knife remain distinct, with the
red pauldron on the short-knife arm. The final turn carries through her hips,
shoulders, hair and tabard before settling back into the approved stalker guard.

The twenty keys share one 550-pixel anatomical scale. Six crimson/ivory effects
extend the blade paths without extending her hurtboxes. All contact beats
(34/59/76), bleed application, hard knockdown, damage and cost are unchanged.
Block and miss return from the opening without playing the captured sequence.

The native suite passed 20,153 checks with no failures. See the
[validation](../art/characters/supers-v3/bloodletting/validation.json) and
[fixed-scale comparison](../art/characters/supers-v3/bloodletting/scale-review.png).

## Exsanguinate — complete

[Watch the native 60 FPS review](../exports/FightGuild-Exsanguinate-V3-2026-11-26.mp4)
(hit, mirrored hit, block, miss and stored-bleed cash-out).

Twenty-four replacement drawings take Fillet through a deep overhead coil,
committed opening downcut, grounded tightening, rising scissors, a second
downcut and an explosive crossed-knife finish. Four compression drawings sustain
the longer buildup; four separate return drawings settle her into the original
stalker guard. Her hips, shoulders, legs, hair and tabard follow the blade arcs.

All drawings share the same 550-pixel anatomical scale as Bloodletting. The
right hand owns the long knife and the left pauldron arm owns the short one,
including crossed-arm and back-facing poses. Six crimson/wine/ivory effects
extend the crescents while keeping the body silhouette visible. Corrections
and their exact source references are retained in the production history.

The 48/84/108 contact beats, damage, bleed ownership and one-time cash-out remain
unchanged. Block and miss withdraw from the opening. The native suite passed
21,935 checks with no failures, including both facings and editable capture
timing. The five-case recording passed with 300 damage on ordinary connection,
450 with 150 owned grey life, 8 on block and zero on miss. See the
[validation](../art/characters/supers-v3/exsanguinate/validation.json)
and [fixed-scale comparison](../art/characters/supers-v3/exsanguinate/scale-review.png).

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

The additional reaction, grab and movement catalogs were reviewed separately:
168 drawings across twenty native contact sheets. No additional blanket scale
correction was justified. The [external audit](../art/animation-size-audit/2026-11-26/external/README.md)
records its scope, limitations and reproducible capture command.
