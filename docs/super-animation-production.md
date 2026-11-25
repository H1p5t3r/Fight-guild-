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

## Production order

1. Sky Foundry — full pass and native review.
2. Iron Dominion — full pass and native review.
3. Freemason — full pass and native review.
4. Grand Design — full pass and native review.
5. Flashpoint.
6. The Air Is Mine.
7. Last Orders.
8. Whiskey Chaser.
9. No Safe Harbour.
10. Undertow.
11. Bloodletting.
12. Exsanguinate.

The browser Move Workshop remains frozen throughout this native production pass.
