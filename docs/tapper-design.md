# Tapper — playable Leo baseline and rolling stance

Implemented 18 November 2026 in combat schema **18**. The current kit has **31 enabled actions**, dedicated generated windup/active sprites, normal ready and rolling idles, an eight-pose walk, and an eight-pose step dash. The [importable draft](../godot/data/workshop/2026-11-18-tapper/FightGuild-Tapper.json) combines this kit with the user's third move batch. All uploaded non-Tapper move values, movement profiles and existing art briefs remain unchanged. The original upload is retained separately.

## Play the kit

- **5S** selects **c.S** within 95 world pixels of the opponent's root; otherwise it selects far Slash. Both definitions are editable.
- Hold **S** after far Slash or **Hs** after Heavy Slash for the normal-kit guard hold. Press the opposite S/Hs button for Guard Attack. The hold protects against mids/highs, with chip and hitstop but no blockstun; lows and throws beat it. Guard Attack has one hit of mid/high armor on frames 1–9, still takes damage, and loses to lows/throws.
- **5D** is provisionally a blockable mid collar grab → headbutt → rolling stance on hit. Blocking it does not grant stance. **4P+K / 6P+K** outside stance give a collar throw/headbutt, hard knockdown, and stance entry.
- Rolling stance has **no block or Faultless Defense**. **P** is a short check, **K** a low, **S** a fast mid hook, **Hs** an overhead. They cross-cancel on hit/block; S also cancels into itself. Other stance normals do not self-cancel by default.
- **2D in stance** exits immediately into an 11-frame exit action. It has no attack box and can cancel from a stance normal on contact. Outside stance, 2D remains the hard-knockdown sweep.
- **236D in stance** is the user-confirmed running command throw: run → tackle capture → one strong punch → rolling stance. P+K does not substitute for it. Jumping, blockstun and normal post-stun throw immunity defeat its grab attempt; entering the run does not guarantee a throw. Guard break keeps its existing throw-vulnerability exception.
- Grounded forward **66 / dash macro** uses a finite step dash: 16f at 9 px/f. Backstep is 14f at 8 px/f. Walk is 3 px/f forward and 2.5 backward. Air dash/backdash are provisionally enabled. Momentum carries into attacks.
- Getting hit or jumping exits rolling stance. The bobbing idle does not itself give armor or invulnerability. Captured pairs are protected from new strike/projectile contacts during the short grab sequence; the running approach remains vulnerable.

The stance name is not locked. “Last Orders” remains an earlier unconfirmed suggestion.

## Frame data

Frames run at 60 Hz. Startup includes the first active frame; ordinary total is startup − 1 + active + recovery. Block advantage below assumes first-active contact and a fixed grounded duration. Air advantage depends on contact height/landing. Capture time is added on a successful grab before its finish/recovery.

| Input / context | Action | Startup | Active | Recovery | Damage | Base on block |
|---|---|---:|---|---:|---:|---:|
| 5P | 5P | 5 | 5 | 6 | 52 | -1 |
| 5K | 5K | 9 | 4 | 13 | 64 | -3 |
| 5S | Far Slash | 12 | 6 | 21 | 68 | -13 |
| 5Hs | 5Hs | 15 | 5 | 22 | 84 | -10 |
| 2P | 2P | 6 | 4 | 8 | 44 | -2 |
| 2K | 2K | 7 | 6 | 11 | 52 | -5 |
| 2S | 2S | 10 | 3 | 13 | 52 | -2 |
| 2Hs | 2Hs | 12 | 8 | 29 | 88 | -20 |
| 6P | 6P | 10 | 5 | 21 | 76 | -9 |
| 6K | 6K | 14 | 3 | 18 | 60 | -4 |
| 6Hs | 6Hs | 28 | 2 | 30 | 100 | -15 |
| 5D | Collar Break | 18 | 3 | 22 | 65 | -8 |
| j.P | j.P | 5 | 3 | 9 | 48 | Height dependent |
| j.K | j.K | 10 | 7 | 25 | 60 | Height dependent |
| j.S | j.S | 7 | 3 (3 gap) 3 | 17 | 48 | Height dependent |
| j.Hs | j.Hs | 11 | 3 | 19 | 84 | Height dependent |
| j.D | j.D | 22 | Until landing | 15 | 88 | Height dependent |
| 2D | 2D | 12 | 6 | 19 | 80 | -8 |
| 4P+K | Back collar throw | 5 | 3 | 38 | 160 | — |
| 6P+K | Collar throw | 5 | 3 | 38 | 160 | — |
| c.S | Close Slash | 7 | 6 | 10 | 80 | +1 |
| [S/Hs] | Held guard | 5 | While held | 16 | 0 | — |
| [S/Hs]>attack | Guard attack | 10 | 3 | 14 | 84 | +0 |
| st.P | Rolling check | 7 | 4 | 12 | 48 | -2 |
| st.K | Low kick | 8 | 3 | 12 | 48 | -1 |
| st.S | Hook | 5 | 3 | 6 | 48 | +3 |
| st.Hs | Overhand | 18 | 4 | 21 | 85 | -8 |
| st.2D | Stance exit | 5 | 1 | 6 | 0 | — |
| st.236D | Running tackle | 18 | 14 | 28 | 140 | — |
| j.4P+K | Air back throw | 5 | 3 | 38 | 160 | — |
| j.6P+K | Air throw | 5 | 3 | 38 | 160 | — |

The two hits of j.S each have base damage 48 before combo scaling. Ground throws capture for 20f, Drive for 20f, and 236D for 24f. The headbutt/punch is the single damaging finish; capture does not add a second damage event. Ground throws use 80f down + 8f wakeup; tackle uses 64f + 8f, and Drive uses soft knockdown with 32f down + 8f wakeup. These durations, launch, block/air/ground push, throw range, gravity scaling and cancellation windows are editable.

## Leo source and deliberate adaptations

Normal startup/active/recovery, grounded block advantage, guard level and main utility come from the [saved Leo page](research/leo-tapper-2026-11-18.md), revision **581554**, captured **18 November 2026**. That report remains the historical source-ingestion assessment. The runtime now includes proximity Slash, timed guard hold/release, startup advancement, two-hit j.S, late low-reaching 5Hs, j.D stall/dive/landing recovery, air throws, crumple and one-use ground/wall bounces.

This is a functional translation into Fight Guild, not verified Strive engine parity:

- Normal damage is provisionally twice the source's damage against Fight Guild's 1000 HP. Physical ranges, movement, hitstop and knockdown durations use local tuning.
- All attacks, including source 2f throws, obey the project's **5f minimum**. Unified normal gatlings remain the baseline; 2D has the source's explicit no-special-cancel exception.
- 6P uses a legs-only hurt mask on move frames 1–14, then restores the body. This first pass combines the source's two early low-profile shapes into one timed mask. It crumples grounded targets and hard-knocks-down an airborne counter-hit target.
- 2D is semi-airborne on frames 5–18 for low-strike/projectile and ground-throw avoidance. This does not convert its input into an air move.
- c.S/6Hs bounce an airborne target off the ground; 5Hs wall-bounces; j.D can use both. Bounces are consumed once per application. Existing velocity damage and depleted-wall splat rules take priority over a wall bounce.
- The custom rolling kit is provisional. S uses 5/3/6 and +3 as a pressure starting point; Hs uses 18/4/21. P/K, tackle, Drive and stance-exit tuning are local choices. The current P additionally uses an editable upper-body protection window.
- Leo's specials are **not assigned**. Extra unused normal/special slots stay disabled. No supers, drinking-resource mechanic or new Momentum spend was added.

## Editing and preview

Open **Stance & behavior** in Move Workshop or **Drive / stance behavior** in Godot Development. New controls cover required/entered/exited stance, proximity selection, held-input guard and follow-up, startup travel, dive velocity, armor, timed hurt masks/low-crush, crumple, contextual knockdown, bounces, capture duration and finisher art. The [Workshop guide](move-workshop.md#stance--behavior-schema-18) explains each field. All values round-trip in schema-18 JSON.

Selecting a stance or contextual action previews it in isolation and says so on screen. Use live play to test the entry route. Choose **Movement & defense → Tapper rolling stance**, **Walk forward**, or **66 / forward macro** to inspect the idle/gait/step. Scrubbing capture shows the capture/finish clock instead of labeling it as windup. Throw/exit actions have no misleading block-advantage summary.

Existing browser drafts are retained. To try this kit when an older draft is already open, first download that draft as a backup, then import **FightGuild-Tapper.json**. Importing an older export migrates its data without silently replacing Tapper's authored moves or activating new slots.

## Artwork and remaining iteration

The new [Tapper v1 atlas set](../godot/assets/fighters/tapper-v1/) has 64 directed windup/active drawings, one normal ready, four rolling-idle poses, eight walk poses and eight step poses. Collar capture/headbutt and running tackle/single punch use distinct drawings. The original generated PNGs are retained, with regions/pivots and body-only collision fits in metadata. Older block-reaction sprites remain in use. Transition smears are absent.

This is the requested windup/active pass, not a finished animation set: impact, follow-through and dedicated recovery drawings are still future work. Playtest stance pressure, throw escape gaps, spacing, bounce routes and movement before treating the provisional balance or art fits as final.
