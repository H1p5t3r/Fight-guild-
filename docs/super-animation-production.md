# Full super animation production

Work proceeds **one super at a time**, finishing and reviewing each before the
next. Preserve the selected fighter designs, approved choreography and current
combat rules. Follow the [attack animation standard](attack-animation-standard.md):
authored anticipation, decisive strike changes, deliberate contact holds,
follow-through and recovery. More drawings must describe motion, not introduce
frame-to-frame costume or size jitter.

## 01 — Anvil / Sky Foundry

[Watch the native 60 FPS review with sound](../exports/FightGuild-Sky-Foundry-2026-11-25.mp4).
The review includes a successful airborne catch, P2/mirrored playback against
Fillet, and a miss against a grounded Shark.

The former three-drawing lift now has **16 original body keys**, six separate
effect drawings, a dedicated face cut-in and four original synthesized sounds.
The approved Bull / High Clamp design, five-digit right grappling hand and
left-arm Shield 1 remain the references. Each source atlas uses one anatomical
scale; airborne roots are registered from the pelvis, grounded roots from the
support. The descent atlas uses separate column gutters to avoid clipping a boot.
The original generated PNG bytes are preserved, including their alpha channels.

| Saved clock | Presentation |
| --- | --- |
| Startup 1–4 | Compact held load under the existing 54-tick torn-screen cut-in |
| First active, frame 5 | Full upward catch; the largest initial reach change |
| Capture 0 / 6 | Supporting palm catches the body, then absorbs its weight |
| Capture 12 / 20 | Leg drive and airborne tuck; rising magma accent |
| Capture 30 / 44 / 58 | Open apex, suspended weight, downward coil |
| Capture 65 / 88 | Tucked fall and leg extension; separate descent accent |
| Capture 100–111 | Grounded compression, victim still held above the palm |
| Actual damage/release | Sit-out slam, ground burst and heavy landing sound |
| Connected recovery 4 / 8 / 15 / 21 | Recoil, floor push, rising guard, High Clamp |

The old art showed the slam before its damage event. The new sequence respects
the existing root landing at capture tick 100 but saves the arm slam for release
at tick 112. Contact art holds through the real 24-tick release hitstop; the
small effect burst opens into a shock ring and fragments during that freeze.
The competing ordinary chest-level impact is suppressed for this finish.

All six receivers retain their own artwork and scale. Their carried torso is
registered to the drawn right palm, with a rigid turn during descent and explicit
front/behind changes. Misses never enter the carry, slam or connected recovery.
The move-specific face is revealed by the existing rip-and-knit shader; other
supers continue to use their existing portrait selection.

`SuperAnimation` selects presentation from saved action age, pair clock and
recovery counters. It never writes to the native simulation or compiled collision
table. Cinematic sounds enter the existing rollback/confirmation history as
audio-only cues; pause, focus changes and repeated confirmation cannot replay
them. Startup, invulnerability, capture eligibility, damage, two-segment cost,
freeze, knockdown and recovery are unchanged.

Sources and reproducibility:

- [Exposure plan](../art/characters/supers-v2/sky-foundry/exposure-plan.json)
- [Original image paths, prompts, references and hashes](../art/characters/supers-v2/sky-foundry/sources.json)
- [Frame registration](../art/characters/supers-v2/sky-foundry/registration.json)

```bash
python scripts/register-sky-foundry.py
python scripts/generate-sky-foundry-audio.py
bash scripts/godot.sh --headless --editor --import
bash scripts/godot.sh --headless --script res://tests/sky_foundry_test.gd -- --test
python scripts/capture-sky-foundry.py --baseline
python scripts/capture-sky-foundry.py
```

The baseline uses the old body animation and portrait, with the same move data
and camera as the new recording. It is retained in `build/sky-foundry-before/`.
Checks cover both owners/facings, all receivers, hand attachment, scale, pause,
rollback, first-active timing, complete pose coverage, grounded/range misses,
confirmed audio, portrait isolation and gameplay fingerprints. The native Anvil,
full super roster, feedback and screen-tear regression suites also run.

## 02 — Anvil / Iron Dominion

[Watch the native 60 FPS review with sound](../exports/FightGuild-Iron-Dominion-2026-11-25.mp4).
The review separates confirmed hit, mirrored P2 hit, block and out-of-range miss.
Sixteen new full-body drawings replace the reused shield brace: a compressed
opening ram, rising press, downward crush, final shield plant and return to the
High Clamp guard. The left arm retains Shield 1 throughout. Six original magma
effect drawings and four original shield impacts follow those distinct beats.
Iron Dominion has its own face cut-in; Sky Foundry retains its own.

The strike poses begin on the saved capture impacts at ticks 40 and 70. The
final plant starts at actual release/damage, tick 90, holding through its real
22-tick hitstop before the existing 24-tick recovery. Block and whiff withdraw
from the opening ram; they never play the confirmed finish or its sounds. The
18/5/18 move timing, armor, 280 damage, +14 first-active block advantage and
two-segment cost are unchanged. Receiver reactions continue to follow the real
capture path. One anatomical scale is shared across all 16 body drawings.

Presentation profiles now support saved-clock effect tracks and cinematic sound
beats. Their cues use the existing confirmation/rollback history. New body,
effect and cut-in textures join match loading to avoid first-use disk reads.
The original PNG bytes are preserved; registration only supplies atlas regions,
body pivots, shield masks and exposures.

- [Exposure plan](../art/characters/supers-v2/iron-dominion/exposure-plan.json)
- [Image provenance](../art/characters/supers-v2/iron-dominion/sources.json)
- [Registration](../art/characters/supers-v2/iron-dominion/registration.json)

```bash
python scripts/register-iron-dominion.py
python scripts/generate-iron-dominion-audio.py
bash scripts/godot.sh --headless --editor --import
bash scripts/godot.sh --headless --script res://tests/iron_dominion_test.gd -- --test
python scripts/capture-iron-dominion.py --baseline
python scripts/capture-iron-dominion.py
```

Checks cover all six receivers, both owners and facings, the two intermediate
impact exposures, every body key, fixed scale, pause, hit/block/whiff separation,
audio cue counts and unchanged gameplay fingerprints. Sky Foundry and the full
super roster are regression-tested after extending the presentation profiles.
Edited capture lengths of 91, 100 and 120 ticks also retain exact alignment at
the native integer-rounded impact boundaries. On block, the opening force effect
ends at the defender instead of continuing through their guard.

## 03 — Hammer / Freemason

[Watch the native 60 FPS review with sound](../exports/FightGuild-Freemason-2026-11-25.mp4).
The approved Shoulder Drive style now carries through sixteen original body
keys: a compact hip load, horizontal strike, weight brake, rising cross-body
strike, overhead downstroke, final horizontal carry and controlled return.
Six separate blue/ivory hammer effects and four original metal/bass impacts
give each strike its own accent. A new face drawing fills the torn-screen cut-in.

The two intermediate blows follow capture ticks 40 and 70; the final strike
begins at actual release/damage, tick 90. The defender holds the existing strong
upper-body recoil during the real release freeze, then displays the actual hard
knockdown. This replaces the earlier presentation in which the defender was
already prone before the horizontal finishing blow. No simulation position,
collision, damage, stun, invulnerability or recovery value changes. Freemason
remains 12/4/34, 360 base damage and two Momentum segments.

The constant 425-pixel anatomical scale matches Hammer's existing source scale.
Weapon masks preserve the pause treatment. One generated finish sheet had a
translucent white background; it was corrected through image generation before
registration. No script edits any source pixels. The final PNGs and all prompts,
including the transparency correction, retain their provenance.

- [Exposure plan](../art/characters/supers-v2/freemason/exposure-plan.json)
- [Original assets and hashes](../art/characters/supers-v2/freemason/sources.json)
- [Body roots, weapon masks and effects](../art/characters/supers-v2/freemason/layout.json)

```bash
python scripts/register-super-presentation.py freemason
python scripts/generate-freemason-audio.py
bash scripts/godot.sh --headless --editor --import
bash scripts/godot.sh --headless --script res://tests/super_presentation_test.gd -- --test --character 1 --slot 12
python scripts/capture-freemason.py --baseline
python scripts/capture-freemason.py
```

The common presentation checks cover six defenders, both player sides/facings,
every drawing, weapon/body scale, pause, snapshots and replay, authored sound
counts, edited capture durations and separate block/whiff behavior. The final
receiver hold is also checked against the saved hitstop state.

## 04 — Hammer / Grand Design

[Watch the native 60 FPS review with sound](../exports/FightGuild-Grand-Design-2026-11-25.mp4).
Eight original body keys cover the short cast: low guard, rear coil, overhead load,
ground plant, compression, guiding hand and return to guard. Six separate ground
accents and a six-key stone-wave loop accompany a dedicated face cut-in. The
last-startup to first-active hammer movement measures 257.09 world units, larger
than every other adjacent body-key change. All keys share the same anatomical
scale and original generated PNG bytes.

The wave follows its own saved age, independently of Hammer's cast. Its tall,
narrow drawing fills the existing projectile rectangle, with a stable silhouette
while internal fractures and chips cycle. Real projectile contacts scatter stone
fragments while preserving distinct block feedback. Mirroring now occurs around the
projectile collision center, correcting an inherited one-hitbox-width art shift
for left-facing projectiles. Original plant and stone
sounds follow the actual first-active and projectile-spawn events, including
edited timings. Utility projectile contact audio remains audible after the caster
returns to neutral; it does not use the captured-super sound suppression.

The review includes hit, mirrored hit, crouch block, miss and a real-input run
behind the wave into a Slash follow-up. Crouch blocking is deliberate: holding
standing back walks the dummy out of this slow projectile's range. No positions
are corrected during playback. The cast never captures the opponent or locks
Hammer to the projectile. The 16/1/10 timing, frame-22 spawn, 120 damage, 12 chip,
launch, meter cost and projectile behavior are unchanged.

Sources: [exposure plan](../art/characters/supers-v2/grand-design/exposure-plan.json),
[prompts and hashes](../art/characters/supers-v2/grand-design/sources.json),
[layout](../art/characters/supers-v2/grand-design/layout.json).

```bash
python scripts/register-super-presentation.py grand-design
python scripts/generate-grand-design-audio.py
bash scripts/godot.sh --headless --editor --import
bash scripts/godot.sh --headless --script res://tests/super_cast_test.gd -- --test
python scripts/capture-grand-design.py --stills
python scripts/capture-grand-design.py
```

The cast suite checks both owners/facings, all body/projectile keys, scale, pause,
actual hit/block damage, wave independence, one-time cast/spawn audio, contact
sound preservation, snapshot replay and edited startup/spawn/recovery timing.
The full native super roster also passes. The baseline remains in
`build/grand-design-before/`. The final mirrored case was re-recorded after the
projectile-center correction (`capture-super-animation.py grand-design --case
mirrored`) and replaces that case in the exported reel at the same 60 FPS.

## 05 — Smoke / Flashpoint

[Watch the native 60 FPS review with sound](../exports/FightGuild-Flashpoint-2026-11-25.mp4).
Sixteen original body keys develop the approved empty-hand backhand into a
complete flame sequence: cross-body coil, horizontal cut, drifting follow-through,
upward fire lift, two-handed compression, final ignition and settled idle. Smoke
retains her toe-touch posture, long slim anatomy, hat and cream/olive costume.
The refined opening coil reserves the largest adjacent fingertip displacement
(86.32 world units) for the first active frame. One 480-pixel anatomical scale
is used across every body key. No body warp, physical sword or beam is added.

Six separate flame drawings use ivory heat, orange fire and sculpted charcoal
ribbons. The upward lift follows the actual airborne receiver path; compression
begins at capture tick 65 and the final ignition starts only at release/damage,
tick 84. Four original synthesized fire sounds follow ticks 0, 37, 65 and release.
The receiver uses the stronger existing recoil key on the captured impact beats.
The final chest recoil holds through the existing hitstop before hard knockdown.
Block and miss withdraw from the opening cut and never play the capture finish.
The 8/5/35 timing, invulnerability, 300 damage, two-segment cost and recovery rules
are unchanged. Her new face portrait uses the existing rip-and-knit cut-in.

Sources: [exposure plan](../art/characters/supers-v2/flashpoint/exposure-plan.json),
[original PNG provenance](../art/characters/supers-v2/flashpoint/sources.json),
[registration](../art/characters/supers-v2/flashpoint/layout.json).
The load correction is a new image-generator edit; original source bytes remain
in the recorded source path. Runtime registration only defines regions/pivots.

```bash
python scripts/register-super-presentation.py flashpoint
python scripts/generate-flashpoint-audio.py
bash scripts/godot.sh --headless --editor --import
bash scripts/godot.sh --headless --script res://tests/super_presentation_test.gd -- --test --character 2 --slot 12
python scripts/capture-super-animation.py flashpoint --stills
python scripts/capture-super-animation.py flashpoint
```

The common presentation suite checks all six receivers, both sides/facings,
complete key coverage, scale, pause, edited capture durations, exact damage/audio
counts and snapshot replay. Native review separates hit, mirrored hit, block and
miss. The old animation is retained in `build/flashpoint-before/` for comparison.

## 06 — Smoke / The Air Is Mine

[Watch the native 60 FPS review with sound](../exports/FightGuild-The-Air-Is-Mine-2026-11-26.mp4).
Twelve body keys take Smoke from a compact inhaling gesture through a first-active
curtain release, a high/low guiding pose and a gradual return to her toe-touch
idle. A fixed 480-pixel anatomical scale and registered toes prevent size changes.
Six independent charcoal/olive gas keys roll around a transparent center, with
acid-green accents, so the defender remains readable inside the field. Separate
release, contact and dispersal effects never stretch Smoke's body. Her dedicated
portrait uses the existing ripped-screen reveal and reverse closure.

Three original synthesized sounds cover the breath release, cloud bloom and
actual contact pulses. Block, counter and Faultless Defense retain their distinct
contact layers. The cloud runs on the saved projectile age after Smoke recovers;
its opacity is presentation metadata. Near, middle and far placement, three hits,
36-frame rehit, stationary behavior, clearance on Smoke being hit, 24/1/18 timing,
50 damage per hit, meter cost and free action between pulses are unchanged.

Sources: [exposure plan](../art/characters/supers-v2/the-air-is-mine/exposure-plan.json),
[original source records](../art/characters/supers-v2/the-air-is-mine/sources.json),
[layout](../art/characters/supers-v2/the-air-is-mine/layout.json).
The curtain and follow-through corrections were made through image generation;
registration changes metadata only and keeps all selected PNG bytes intact.

```bash
python scripts/register-super-presentation.py the-air-is-mine
python scripts/generate-air-is-mine-audio.py
bash scripts/godot.sh --headless --script res://tests/super_cast_test.gd -- --test --character 2 --slot 31
python scripts/capture-super-animation.py the-air-is-mine --stills
python scripts/capture-super-animation.py the-air-is-mine
```

The cast suite passes 6,735 checks, including both sides/facings, all twelve body
and six cloud keys, exact three-hit damage/chip, replay, edited cast/spawn timings,
all placements and interruption by a real opponent attack. The six-case native
review covers hit, mirrored hit, crouch block, miss, near and far placement.
Grand Design, full-roster supers and combat feedback are also regression checked.

## 07 — Tapper / Last Orders

[Watch the native 60 FPS review with sound](../exports/FightGuild-Last-Orders-2026-11-26.mp4).
Twenty original body keys give the normal-stance super a complete uppercut,
second rising strike, close headbutt, final forehead impact and Dempsey finish.
Four additional withdrawal keys within that total return the staff from his back
to his normal grip on block or miss. The successful sequence keeps the staff
secured behind his back and attacks only with fists and forehead. The same near
arm performs both uppercuts; an image-generator correction fixed arm continuity.

Every key uses Tapper's existing 470-pixel anatomical scale. The largest measured
adjacent fist displacement, 114.54 world units, occurs between the held startup
coil and first active uppercut. Later movements are smaller, with held impacts
and diminishing recovery. Six separate ivory/amber/ink effects follow the actual
0/43/74/release-96 beats. The rising effect begins at the fist, and the final burst
leaves room to read the receiver's recoil. Four original synthesized physical
impacts distinguish the rising punches, forehead crack and final heavy hit.
His new cut-in portrait retains the ripped-screen reveal and reverse closure.

The 7/4/38 timing, invulnerability, 340 damage, meter cost and Dempsey-on-hit rule
are unchanged. Native tests explicitly verify that block/miss retain normal
stance, while confirmed hits enter Dempsey. The common retiming test now stays
inside the existing 120-frame capture limit and counts unsuccessful-branch art.
All receivers, owners/facings, snapshot replay, pause, scale and key coverage pass.
The full super roster, Tapper mechanics and feedback suites also pass.

Sources: [exposure plan](../art/characters/supers-v2/last-orders/exposure-plan.json),
[original image records](../art/characters/supers-v2/last-orders/sources.json),
[layout and pause masks](../art/characters/supers-v2/last-orders/layout.json).

```bash
python scripts/register-super-presentation.py last-orders
python scripts/generate-last-orders-audio.py
bash scripts/godot.sh --headless --script res://tests/super_presentation_test.gd -- --test --character 3 --slot 12
python scripts/capture-super-animation.py last-orders --stills
python scripts/capture-super-animation.py last-orders
```

## 08 — Tapper / Whiskey Chaser

[Watch the native 60 FPS review with sound](../exports/FightGuild-Whiskey-Chaser-2026-11-26.mp4).
Sixteen original body keys develop a low Dempsey roll into alternating near-arm,
far-arm and low body hooks, followed by a committed final hook and settled guard.
The staff stays slung behind Tapper throughout. Every key uses his existing
470-pixel anatomical scale; the largest adjacent punch displacement, 108.48 world
units, is reserved for the last-startup to first-active change. The second hook's
arm staging and elbow bend were corrected through image generation.

The unsuccessful branch also has real choreography: the three blocked pulses
show impact poses 1, 6 and 10 at active frames 1, 5 and 9. Optional active-frame
presentation keys read the saved move age, so hitstop holds the correct punch.
Separate amber/ivory hook trails start near Tapper and stop at the defender's
guard; their drawing width follows the actual separation without changing boxes
or pushback. The confirmed sequence uses the native 0/43/74/release-96 beats.
Six effect keys, four original synthesized punch sounds and a dedicated grinning
cut-in portrait complete the move. Dempsey guard is retained on hit, block or miss.

The 10/9/12 timing, stance requirement, 260 confirmed damage, three 5-chip block
pulses, momentum cost and lack of invulnerability are unchanged. The common suite
passes 17,481 checks, including exact three-contact pose alignment, all body keys,
all receivers and sides, scale, pause, replay and edited capture duration.
Last Orders and the full super roster also pass. The reviewer sets up Dempsey
before the idle lead-in using an ordinary stance normal; no gameplay edits or
mid-sequence corrections are used in the recording.

Sources: [exposure plan](../art/characters/supers-v2/whiskey-chaser/exposure-plan.json),
[original image records](../art/characters/supers-v2/whiskey-chaser/sources.json),
[exposures, effect placement and masks](../art/characters/supers-v2/whiskey-chaser/layout.json).
Two transparency corrections were generated as new images; registration leaves
all selected PNG bytes unchanged.

```bash
python scripts/register-super-presentation.py whiskey-chaser
python scripts/generate-whiskey-chaser-audio.py
bash scripts/godot.sh --headless --script res://tests/super_presentation_test.gd -- --test --character 3 --slot 31
python scripts/capture-super-animation.py whiskey-chaser --stills
python scripts/capture-super-animation.py whiskey-chaser
```

## 09 — Shark / No Safe Harbour

[Watch the native 60 FPS review with sound](../exports/FightGuild-No-Safe-Harbour-2026-11-26.mp4).
Twenty original body keys turn the long hook thrust into a reel, rising jerk,
advancing drive and heavy finish. Four added overhead recovery poses bring the
hook back to the approved shoulder rest without a snap. Anatomical scale stays
at Shark's existing 480 pixels. The largest adjacent hook displacement is
102.16 world units, at last startup → first active; recovery steps remain smaller.

Six teal/ivory effect keys, a dedicated blue-glasses cut-in and four original
synthesized hook/metal impacts follow native beats 0/43/74/release-96. The long
opening wake reaches along the original narrow horizontal attack lane on a miss
and ends at the actual defender on contact, including during capture. This is
presentation metadata only. The 12/4/30 timing, 310 damage, 400-unit reach,
8 chip and two-segment cost are unchanged.

The common suite passes 17,529 checks across all receivers and both sides,
including scale, all 20 exposures, pause, snapshot replay, block/miss branches
and edited capture durations. The native review includes close hit, mirrored hit,
block, distance miss, a 380-unit long-range hit and a jump above the attack lane.
The full super and Shark Drive regression suites also pass. The older Drive test
now recognizes the super occupying the retired Chase slot; its legacy migration
and actionable-pull checks remain intact.

Sources: [exposure plan](../art/characters/supers-v2/no-safe-harbour/exposure-plan.json),
[original image records](../art/characters/supers-v2/no-safe-harbour/sources.json),
[landmarks and effect placement](../art/characters/supers-v2/no-safe-harbour/layout.json).

```bash
python scripts/register-super-presentation.py no-safe-harbour
python scripts/generate-no-safe-harbour-audio.py
bash scripts/godot.sh --headless --script res://tests/super_presentation_test.gd -- --test --character 4 --slot 12
python scripts/capture-super-animation.py no-safe-harbour
```

## 10 — Shark / Undertow

[Watch the native 60 FPS review with sound](../exports/FightGuild-Undertow-2026-11-26.mp4).
Twenty body keys give Undertow a low committed sweep, overhead reel, visible
hip-led turn and left-facing finish after the opponent crosses behind Shark.
Four separate right-facing recovery keys handle block and miss. The opening
was regenerated to read as a low sweep rather than another chest thrust.
Fixed 480-pixel anatomical registration preserves Shark's size. The largest
adjacent hook displacement, 235.29 world units, occurs at first active.

Six teal/ivory effects trace the low sweep, overhead crossing and reverse finish;
four original synthesized impacts follow native beats 0/36/62/release-80.
A dedicated portrait uses the existing rip-and-knit freeze. Optional
`connected_flip` presentation metadata keeps the authored left-facing ending
in the original pair orientation after gameplay turns toward the displaced
opponent. It changes neither facing logic nor collision data.

The 7/5/32 timing, invulnerability, side switch, 220 damage, 8 chip and cost are
unchanged. The animation suite passes 21,245 checks, including all receivers,
both sides, explicit side-switch/finish orientation, scale, pause, every drawing,
snapshot replay and edited duration. The full super suite passes 8,302 checks.
The complete native review confirms hit, mirrored hit, block and miss.

Sources: [exposure plan](../art/characters/supers-v2/undertow/exposure-plan.json),
[originals and correction records](../art/characters/supers-v2/undertow/sources.json),
[landmarks and exposure metadata](../art/characters/supers-v2/undertow/layout.json).

```bash
python scripts/register-super-presentation.py undertow
python scripts/generate-undertow-audio.py
bash scripts/godot.sh --headless --script res://tests/super_presentation_test.gd -- --test --character 4 --slot 14
python scripts/capture-super-animation.py undertow
```

## Production order

1. Sky Foundry — full pass and native review.
2. Iron Dominion — full pass and native review.
3. Freemason — full pass and native review.
4. Grand Design — full pass and native review.
5. Flashpoint — full pass and native review.
6. The Air Is Mine — full pass and native review.
7. Last Orders — full pass and native review.
8. Whiskey Chaser — full pass and native review.
9. No Safe Harbour — full pass and native review.
10. Undertow — full pass and native review.
11. Bloodletting.
12. Exsanguinate.

The browser Move Workshop remains frozen throughout this native production pass.
