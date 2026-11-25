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

## Production order

1. Sky Foundry — full pass and native review.
2. Iron Dominion.
3. Freemason.
4. Grand Design.
5. Flashpoint.
6. The Air Is Mine.
7. Last Orders.
8. Whiskey Chaser.
9. No Safe Harbour.
10. Undertow.
11. Bloodletting.
12. Exsanguinate.

The browser Move Workshop remains frozen throughout this native production pass.
