# Hammer — Break Step

Hammer is a grounded Masons bruiser: long, committed hammer normals become close pressure through one **5D Break Step** per string. The approved art direction is **A / Shoulder Drive**, with compact loads and forceful releases. This is a playable first balance pass.

## Drive rules

- **5D:** 4 frames of load, 12 frames of burst movement, 6 frames of recovery. The editor shows **5 / 12 / 6** because startup names the first active frame.
- Any grounded special can cancel into Drive after its first active frame, including on whiff. Its startup cannot be erased. Normal-to-Drive also follows the shared special-cancel rules.
- During the burst, cancel into any enabled grounded normal or command normal. The chosen attack starts with **100% of the dash velocity**, irrespective of its ordinary inertia percentage; normal attack friction then applies.
- That attack receives **4 extra frames of blockstun**, including per-hit blockstun overrides. This adds four to its ordinary block advantage; an otherwise deeply negative attack can remain negative. Hitstun, damage and startup are unchanged.
- One use is available per combo/pressure sequence. It returns after **12 uninterrupted neutral frames** with both fighters out of attacks, stun, knockdowns, capture, dash/landing/prejump, pull and slowdown states, and no live projectile. Short pressure gaps and hitstop do not refill it. A new round resets it.
- Drive has no strike, projectile, armor or invulnerability. Body pushboxes stop travel at point blank; it does not pass through or push the opponent across the stage.

Automatic distance uses the furthest enabled grounded normal's actual front edge, that move's ordinary block pushback, and both fighters' standing body/pushbox spacing. Hammer's initial reference is **f.S: 240 px reach and 38 px block pushback**. This is a fixed travel budget rather than opponent tracking. Faultless Defense, airborne targets and stage walls can change the final spacing.

In the editor's Drive section, **Drive distance = 0** selects automatic calibration; a positive value overrides it. **Drive advantage** and **Neutral reset** tune the reward and refill rule. Travel is capped at 40 px per active frame and 800 px total. The HUD and preview display READY, SPENT or the current enhanced normal's bonus.

## Provisional kit

Advantage below assumes first-active grounded contact, ordinary guard, and no counter/faultless modifiers. Timings use first-active startup / active / recovery.

| Input | Move | Timing | Damage | On block | Role |
| --- | --- | --- | --- | --- | --- |
| 5P | Knuckle Check | 5 / 3 / 9 | 28 | 0 | Short pressure check; +4 with Drive |
| 2P | Low Check | 5 / 3 / 10 | 24 | -2 | Crouching check |
| 5K | Work Boot | 7 / 3 / 15 | 32 | -3 | Space control |
| 2K | Toe Tap | 6 / 3 / 14 | 28 | -4 | Fast low |
| c.S | Hammer Check | 8 / 4 / 16 | 46 | -1 | Close starter; +3 with Drive |
| f.S | Measuring Blow | 12 / 4 / 23 | 52 | -7 | Longest grounded normal |
| 2S | Foundation Sweep | 10 / 4 / 26 | 48 | -11 | Low, hard knockdown |
| 5Hs | Crossbeam | 15 / 4 / 27 | 68 | -9 | Heavy horizontal confirm |
| 2Hs | Rising Brace | 14 / 5 / 27 | 58 | -11 | Launcher |
| 6P | High Brace | 10 / 4 / 21 | 36 | -8 | Upper-body invulnerability on frames 1–13 |
| 6Hs | Keystone | 22 / 5 / 29 | 82 | -11 | Slow heavy counter-hit tool |
| j.P | Air Check | 6 / 3 / 8 | 22 | Landing-dependent | Quick air check |
| j.K | Air Boot | 8 / 4 / 12 | 30 | Landing-dependent | Air-to-air kick |
| j.S | Hanging Beam | 10 / 5 / 18 | 44 | Landing-dependent | Broad aerial swing |
| j.Hs | Falling Stone | 13 / 6 / 22 | 60 | Landing-dependent | Descending hammer attack |
| 236S | Stonecut | 16 / 4 / 25 | 64 | -7 | Horizontal poke confirm |
| 214Hs | Crown Breaker | 26 / 4 / 30 | 76 | -10 | Reactable overhead special |
| 623Hs | Quarry Lift | 13 / 5 / 31 | 62 | -13 | Rising launcher; no invulnerability |
| 4P+K / 6P+K | Back Cast / Mason Toss | 2 / 2 / 27 | 80 | Throw | Universal ground throws |
| j.4P+K / j.6P+K | Air throws | 2 / 2 / 25 | 72 | Throw | Universal air throws |

The special slots retain their stable JSON IDs, so the former `236P` slot now displays/executes **236S**, and the former `236S` slot displays/executes **214Hs**. Use the editor's displayed input rather than inferring commands from old slot IDs.

## Review and tuning

Open [Hammer's motion review](https://h1p5t3r.github.io/Fight-guild-/hammer-motion-review.html) for full-speed/slow playback, mirroring, collision overlays, frame stepping, and real input-sequence examples. Air-contact clips use a jumping target; c.S whiff uses an explicitly isolated contextual action. Sequence warnings report actual failures rather than forcing a cancel or hit.

The website preserves existing browser-local drafts. **Export your draft before importing the current supplied JSON** to try Hammer's new kit. Importing an older JSON adds the three new schema fields without replacing its Hammer tuning or art notes. The other five fighters' submitted move and movement values are unchanged.

New art covers 23 enabled actions, standing/crouching idle and four throw capture tracks. Attacks hold the load through final startup and snap on first active, with fixed-scale registration and real hitstop. Broad generated hammer effects reach the authored hitbox; weapons/effects never enlarge hurtboxes. Walk/run, block and ordinary hit reactions still use the earlier art and are a separate follow-up.
