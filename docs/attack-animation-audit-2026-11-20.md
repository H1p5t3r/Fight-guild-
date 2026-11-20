# Attack animation audit — 20 November 2026

The supplied **How to Animate a Fighting Game: Complete Guide** supports the
held-pose timing process already approved for Fillet: establish readable load,
contact and recovery keys; choose spacing from gameplay timing; layer effects
without hiding the body; validate actual contact in the engine. More drawings
alone do not fix an attack.

Source: [Artemisia College article](https://www.artemisiacollege.com/feeds/blog/fighting-game-animation),
dated 11 August 2026, read from the user's MHTML archive. Its file checksum and
the sections used are in [source.json](../art/characters/smoke-specials-v3/source.json).
This audit uses the article's animation principles, not its unverified claims
about particular studios' production pipelines.

## Findings

Inspected the registered drawings, native pose selection and real-input browser
recordings. The review includes hit, block and whiff at 60 Hz, collision overlays,
silhouette mode and slow/frame-by-frame inspection. `S/A/R` means first-active
frame / active duration / recovery; startup occupies frames 1 through S−1.

| Attack | S/A/R | Evidence and finding | Action |
| --- | --- | --- | --- |
| Fillet 2S | 12/4/23 | Holds the load at f6–11, snaps at f12, crosses/finishes the cut at f14–15, withdraws at f20. Knife-effect reach visibly covers the low attack rectangles. | Retain as a benchmark. |
| Shark 2Hs | 11/5/28 | Loaded f5–10, scoop f11, rise f12, crest f14; brake/withdraw/settle at f16/25/34. Two actual hits are distinct from one visual interpolation. | Retain the approved Low Scoop. |
| Smoke 2Hs | 18/9/28 | Eruption/twist/crest at f18/21/24 follow the three active shapes; f27/34/46 stage the return. The tall opaque fire still competes with her silhouette when fighters overlap. | Timing is sound; record effect occlusion for a later normal/VFX pass. |
| Smoke f.S | 12/10/19 | One contact drawing is held for the changing multi-hit path, followed by an immediate neutral pose at f22. At the review spacing three of its possible hit groups connect. | Prioritize distinct gas pulses and a recovery sequence in the next normal pass. Do not change hit groups to fit art. |
| Smoke 214S | 15/3/24 | Contact correctly began at f15, but the body reset directly to idle at f18. No release of the arm's momentum. | Add held brake, follow-through, withdrawal and drift. |
| Smoke 214Hs | 29/3/36 | Same abrupt f32 reset after f29 contact; its longer recovery had no visual weight. | Give the heavy backhand a longer settle. |
| Smoke 236S | 13/36/2 | Cast pose was held through f48, then reset at f49. The pillar already had its own saved lifetime. | Add a compact coil and release, then collect the hand within the existing cast lock. |
| Smoke 236Hs | 25/36/2 | Cast pose was held through f60, then reset at f61. The persistent pillar could outlive the caster's action. | Add staged wrist lowering and return without tying the projectile to the body's recovery. |

These are focused findings, not approval of every pose in the roster. The two
remaining Smoke normal findings are follow-up work; this pass changes her four
selected special animations only.

## Implemented Smoke exposure plan

| Input | Loaded hold → release | Follow-through | Withdrawal / collection | Settled while locked |
| --- | --- | --- | --- | --- |
| 214S | f7–14 → f15 | f18 residual contact, f20 new follow-through | f26 hand withdraws, f34 collects | f38–41 |
| 214Hs | f14–28 → f29 | f32 residual contact, f34 new follow-through | f44 hand withdraws, f56 collects | f62–67 |
| 236S | f8–12 → f13 | f17 fingers unfurl | f31 collects, f39 lowers | f45–50 |
| 236Hs | f16–24 → f25 | f29 fingers unfurl, f36 wrist lowers | f43 collects, f51 lowers | f57–62 |

The compiled exposure percentages follow edited startup, active and recovery
durations. Very short edited phases intentionally skip intermediate drawings
instead of adding lockout. The pillars currently spawn at first active
(`projectileSpawnFrame = 0`); manually moving projectile spawn to another frame
requires revisiting the cast exposure plan. The review is of the shipped data.

Eight generated recovery drawings supplement the approved keys. One anatomy
scale (480 source pixels per 150 world pixels) is used throughout these ground
specials. Front-foot registration is maintained across contact/follow-through
on the backhands; during withdrawal the feet deliberately collect into Smoke's
weightless posture. The pillar toe anchor stays fixed. Existing entry, active
and idle artwork is reused; no generated in-between sequence, pose blending,
whole-body scaling or limb smears have been added.

The largest attacking-hand displacement stays at the loaded-to-first-active
boundary. Pillars share the far cast's compact loaded hand; the close cast's
former small lift would otherwise be weaker than its recovery movement.
Follow-through is smaller than the strike. Hair/coat lag is in the generated
recovery keys, rather than a separate timer that could drift during hitstop.

Venom and fire remain **empty-hand horizontal backhand arcs**, not physical
swords or beams. The contact effects retain their approved full reach. Residual
arcs are briefly translucent in recovery and then disappear; they add no hitbox.
The two Smoked Obsidian projectiles still use identical art and 100×150 world
pixel dimensions, at the existing 150/300 pixel placements. Their different
authored lifetimes and all combat values remain intact.

New fallback body fits contain at most four anatomical boxes and exclude magic,
hair and coat tails. User-authored phase boxes/masks retain precedence. Move
JSON, notes, photos, hitboxes, pushboxes and combo physics are unchanged.

## Review and reproduction

- [Browser comparison](https://h1p5t3r.github.io/Fight-guild-/smoke-motion-review.html)
- [60fps before/after video](../art/characters/smoke-specials-v3/previews/Smoke-Specials-Before-After-60fps.mp4)
- [Exact exposure keys](../art/characters/smoke-specials-v3/exposure-plans.json)
- [Original generator sources and checksums](../art/characters/smoke-specials-v3/sources.json)

`scripts/register-smoke-specials-v3.py` only updates the four clips and their
anatomical registration. It does not switch the current workshop batch or write
tuning defaults. Re-run it, generate combat data, rebuild native/WASM and package
the workshop normally. `scripts/capture-smoke-review.mjs` captures the browser
review at 60fps. The preserved `before.json` contains actual recordings from
before registration, including hitstop and projectile age/life; it is not a
reconstruction of old art on a new clock.

The review player shows real attack frames and one-tick stepping. Mirror mode
is a visual inspection aid; separate automated playback tests execute both
actual facings. Hit and block recordings freeze the same body and effect with
the simulation. Whiff playback has no fake impact pause.
