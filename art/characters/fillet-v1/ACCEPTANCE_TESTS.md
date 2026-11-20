# Fillet v1.0 — required acceptance tests

These are implementation requirements, not claims that the new engine has passed. Build the complete character, run these checks, repair failures autonomously, and deliver the playable result with the execution report. Do not stop for per-move or pose approval. `ENGINE_IMPLEMENTATION.md` defines the semantics; the final JSON/geometry files supply exact values. Earlier source probes validate only their stated historical setup.

## 1. Test harness and required records

Use the project's existing native deterministic test harness and Godot/browser smoke-test paths. Add focused cases for the new mechanics; do not substitute the authoring preview API for real input-selection tests. Preview/state setup is appropriate for isolating a clock or geometry boundary, but label it. Input-driven route tests must include the complete preceding actions.

Each gameplay trace must identify final source/build hash, tuning hash, fixture, both characters, facing, stage/corner, initial roots/meter/health, input samples, and relevant state per tick. Record world tick; action ID/absolute frame; advancing/held state; global hitstop; counter slow/phase; resolved pose/hit/hurt/push shapes; root/velocity/carry; reaction/stun/down/wake/landing/grace; accepted jump; contact/group/event/damage; pair type/phase/C/role recovery; bleed owner/duration/growth/grey/snapshot; meter; and checksum. Required reporting can be compact JSONL plus a readable result table.

Use integer units for assertions and display pixels only as derived values. Compare exact coordinates and state, not screenshots alone. Test both player indices and facings for asymmetric mechanics. Use the latest reconciled cast data at `cd8b0cedabfd508b0d82be2841d640e37928ef91` or a documented later integration commit, not the older `a9b3bada...` dataset.

## 2. Data, migration and preservation

| ID | Setup/check | Required result |
|---|---|---|
| D01 | Compile/load final authoring packet | All 26 enabled Fillet actions, 21 disabled historical slots, exact stable IDs, no duplicate/missing definition. |
| D02 | Validate all scalar records | Exactly 138 named current scalars per record; all values within the applicable version's bounds; zero preserved; startup floors respected. The 26 enabled records contain 3,588 scalar values. |
| D03 | Validate all timelines | Strictly increasing keys, valid nonempty rectangles, first key/terminal semantics explicit, hit keys within active duration, hurt/root/animation keys within their absolute action/sequence duration. |
| D04 | Append moves | 45 existing stable IDs preserved; 236D/214D appended, other characters' appended entries disabled. No existing character slot repurposed. |
| D05 | Load a pre-change schema-22 save | All old values/art metadata preserved; new slots default disabled. No unsupported authoring extension silently dropped. |
| D06 | Install this Fillet packet and round-trip through Workshop export/import | Scalars, exact routes, hurt/hit/push timelines, motion, status/pair/animation metadata and gameplay hash remain equivalent. |
| D07 | Compare five other characters with latest pre-change snapshot | Their authored data remain identical, including newly added 2S sweeps and existing 2D. Intentional shared input/tech behavior is reported separately. |
| D08 | Corrupt version, missing required extension, invalid target or out-of-bounds key | Clear validation failure; no partial import, default substitution or crash. |
| D09 | Disable each historical Fillet slot, then try ordinary/motion/held/simplified inputs and routes | No action/contact/meter from disabled definitions. No old conditional 5D cashout, hook, stance, j.D or normal 2D survives. |
| D10 | Compare generated native/Godot/browser tables and hashes | Same move count, slot map, fields, rules and extension tables. Rules/snapshot compatibility version reflects new behavior. |

## 3. Every-action timing, geometry and contact

For every enabled action, run a whiff from a stationary valid starting state through its first actionable tick. Follow-up-only actions require a legal preceding Opening cut in input tests; separate isolated timing fixtures may begin them directly. Air actions need sufficient altitude to avoid early landing. Verify every absolute frame and each key boundary, including the last locked pose. Captures/Wound must also have a separate successful sequence trace.

| Action | S/A/R | Last locked whiff tick | First free tick | Base damage |
|---|---:|---:|---:|---:|
| 5P | 5/3/9 | 16 | 17 | 24 |
| 5K | 7/3/13 | 22 | 23 | 32 |
| c.S | 7/5/12 | 23 | 24 | 44 |
| f.S (`5S`) | 9/3/18 | 29 | 30 | 40 |
| 5Hs | 13/4/22 | 38 | 39 | 60 |
| 2P | 5/2/10 | 16 | 17 | 20 |
| 2K | 6/3/11 | 19 | 20 | 26 |
| 2S | 12/4/23 | 38 | 39 | 42 |
| 2Hs | 14/5/24 | 42 | 43 | 62 |
| 6P | 9/4/20 | 32 | 33 | 34 |
| 6Hs | 18/4/25 | 46 | 47 | 72 |
| j.P | 5/3/10 | 17 | 18 | 22 |
| j.K | 7/4/13 | 23 | 24 | 30 |
| j.S | 10/4/17 | 30 | 31 | 42 |
| j.Hs | 13/5/22 | 39 | 40 | 55 |
| 236P | 12/3/16 | 30 | 31 | 34 |
| 236S | 9/3/18 | 29 | 30 | 28 |
| 236S>6S | 21/3/22 | 45 | 46 | 48 |
| 236S>2S | 16/3/24 | 42 | 43 | 40 |
| 236K | 27/3/24 | 53 | 54 | 36 |
| 623Hs | 11/5/29 | 44 | 45 | 64 |
| 4P+K / 6P+K | 2/2/32 | 35 | 36 | 45 on successful release |
| 5D | 24/2/20 | 45 | 46 | 0 |
| 236D / 214D | 22/2/30 | 53 | 54 | 55 + snapshot on successful release |

**G01 — exact collision:** compare resolved local/world hit, hurt and push rectangles to final `FRAME_GEOMETRY.jsonl` on every action tick, both facings. Apply the 6P mask after selecting the hurt timeline. Validate the active-relative/absolute conversion and last-key hold. Crown/Heel share standing138px push height on1–5; Heel becomes crouching80px from6. Skim push height changes138→52→138 on frames1/6/22, with28px half-width throughout. If the derived file is stale, regenerate it from the authoritative final JSON and document the correction. Do not change gameplay to match an outdated preview.

**G02 — contact and grouping:** for every strike, test normal hit, ordinary block, FD, counter hit, punish hit, whiff and interruption using appropriate ground/air states. Multiple active keys/rectangles may produce only one hit group/contact. Test exact touching-edge versus one-unit overlap under the core's strict strike-AABB rule. Throws use their separate inclusive distance predicate.

**G03 — anatomical fit:** sample standing, crouching, airborne and relevant downed geometry for all six cast members. Verify reachable/missed contact follows actual shapes; do not require every attack to hit every posture. No weapon/trail contributes a hurtbox, and no unlisted vulnerability region comes from old Fillet sprite art.

The final standing reference has legs `[-5400,0,6000,6200]`, torso/arms `[-3600,5200,3500,11800]`, and head `[500,11800,3200,14600]`. Confirm that exact profile appears only where authored. Other profiles retain their distinct shapes. In particular, do not widen the2800-unit push half-width to the6000-unit front foot envelope or replace Skim's low body with the standing reference before frame22.

**G04 — protection boundaries:** 6P frames 2/3/12/13 prove upper protection begins/ends exactly; a strike into remaining legs still hits and a legal throw still captures. Vault low-level contact fails on 6…21 but succeeds when otherwise overlapping on 5/22. Skim's top is exactly 5200 units on 6…21; an overlapping low-reaching mid hits, a rectangle entirely above misses. Skim/Vault capture frames restore standing anatomy and no special evasion. Recovery is strike-vulnerable.

**G05 — scalar semantics:** verify listed damage/chip, hit/block stun, counter freeze/slow/extra stun, ground/air displacement, launch/knockdown, starter proration/scaling and landing recovery. Confirm inactive projectile/armor/guard-point/bounce/crumple/old-mechanic values do not create behavior. `wallDamage` remains inert; wall effects use current collision-speed rules.

## 4. Inputs, routes and pressure timing

| ID | Scenario | Required result |
|---|---|---|
| I01 | Neutral S at 9000 units and 9001, valid standing targets | c.S at boundary; f.S beyond. Resolve distance at execution, including a buffered request. |
| I02 | c.S contact then S while still inside close range | Exactly f.S starts; no c.S loop or proximity rejection. Reuse the newly implemented upstream bypass. |
| I03 | Each named source/target and each unlisted destination | Listed route succeeds only on its condition/window; every unlisted route fails, including legacy same-button command shortcuts and 2K→2S. |
| I04 | Route at window start−1/start/end/end+1, contact and whiff | Inclusive completed-frame bounds; no implicit whiff cancel. Destination begins frame 1 with no inserted delay. |
| I05 | P-family repeated routes and all other self inputs | Only named 5P/2P/j.P repeats succeed; no accidental f.S, c.S, heavy or special loop. |
| I06 | Opening cut hit/block then 6S/2S during 9…17 | Correct overhead/low branch; outside source/window or on whiff, no branch. Ordinary 2S remains distinct. |
| I07 | Command motions with/without owned bleed, in air, wrong source and wrong cancel time | Valid request starts correct cashout; invalid recognized command is rejected/consumed without falling back to Wound or an old D action. |
| I08 | Ground D with no recognized motion, with and without existing owned bleed | Wound starts only when eligible at entry; no normal 2D or automatic cashout. |
| I09 | Normal throw chord, motion/throw conflicts and simplified mappings | Deterministic priority exactly matches final input contract; both control styles access the complete intended kit without enabling disabled actions. |
| I10 | Five post-contact attacker ticks before a bleed-grab cancel | At four completed subsequent ticks reject; at five permit if inside window. Shared hitstop and actor-held slow ticks do not advance this count. Ordinary-throw destinations stay forbidden. |

**P01 — c.S→f.S:** against stationary crouch-guard Shark at 62px center distance, first-active c.S and immediate f.S should remain a continuous blockstring. Ordinary block roots are 62→68→78px; full FD is 62→80→110px, before other voluntary motion. Repeat at both corners; pair-independent block push transfers to Fillet. Confirm actual current final c.S geometry contacts in that fixture. Also test actual near/tip contact distances derived from final geometry; do not copy the old preview's tip assumption.

**P02 — delayed route:** for first-active c.S contact, cancel after completed frames 7…15 retains blockstun; 16/17 produces one/two actionable ticks. Immediate f.S contacts nine unfrozen ticks later, or 17 world ticks including c.S's eight freeze ticks. Verify a first-free fast button, valid jump, FD and invulnerable response where the current target actually has one; report which succeeds. A gap alone is not proof of an interrupt.

**P03 — hit route and scaling:** ordinary grounded c.S→f.S deals 44+32=76; effective second-hit scale is floor(90×92/100)=82%. Test earliest/latest legal cancel positions. CH c.S still has no damage multiplier; subsequent hit/slow clocks must remain correct. First-active standalone f.S is −4 block/+2 grounded ordinary hit; later active contacts give −3/−2 and +3/+4, before launch/slow/landing exceptions.

**P04 — branch timing:** enumerate all completed Opening cut cancel positions 9…17 into both branches on hit/block. Record actual guardable gaps, combo breaks, high/low guard responses and spacing. The earliest low can be continuous while overhead leaves a gap; do not label every branch a guaranteed combo or unavoidable mixup. Verify standing guard loses to low, crouch guard loses to overhead, and mids obey ordinary guard rules.

**P05 — frame clocks:** for each authored counter profile, count actual shared freeze and held defender ticks. f.S CH: 21 total freeze, 25 slow ticks with 13 held, zero extra explicit stun; nominal uninterrupted grounded advantages +15/+16/+17. Small profiles apply their separate explicit extra stun. Buffer inputs early/late in ordinary and CH freeze: only the most recent five world samples survive.

## 5. Movement, landing and side passage

| ID | Required exercise | Expected behavior |
|---|---|---|
| M01 | Walk/run/backwalk at base and bleed | 380/1120/120 become 437/1288/138 for walk/run cap/acceleration; sign and integer rounding correct. No double scaling. |
| M02 | Full-run f.S entry | Initial vx=672; isolated carried steps 672,582,492,402,312,222,132,42, then zero; 2856 units before collisions. c.S→f.S uses remaining velocity, not a new run allowance. |
| M03 | Carry buffer and opposite-facing velocity | Entry consumes carry once, respects the actual five-tick lifetime and signed truncation/clamp; later gatlings cannot restore old run speed. |
| M04 | Backdash interruption boundaries | Ten ticks at 850, or snapshotted 977 with bleed; no attack/jump/guard/FD on committed1–4, legal from5. No invulnerability or low crush. |
| M05 | Forward air dash | Four frozen-motion pause ticks, five 2000/2200 burst ticks; only one use; no air backdash/extra jump. Pause input ages normally. |
| M06 | Attack during burst versus natural exit | Burst cancel inherits actual velocity once. Natural f10 clamps vx/carry to650/715 before input; unrelated run-jump is not clamped. Expiry during coast reclamps650. |
| M07 | Land during each air normal's startup/active/recovery | Landing occurs before same-tick strike contact and terminates that action; locks j.P3, j.K/j.S4, j.Hs6. No last airborne hit materializes on ground. |
| M08 | Empty jump landing | Zero gameplay lock; visual settle is interruptible. Air quotas reset once. |
| M09 | Passing cut | Exactly12×1250 travel on9–20 absent walls; opponent pushbox pass only then; strikes remain valid; one facing update after20; no homing/forced crossing. |
| M10 | Passing cut against retreat, target at wall, and interruption mid-pass | Correct same/crossed side from actual roots; valid push separation after pass; no wall escape, teleport-back or stale side-order correction. |
| M11 | Capture approach | Both commands max15×1200 travel, stop at target push edge without moving target; zero entry inertia. Vault root arc returns0 by21, no extra landing lock. |
| M12 | Every movement/attack/reaction transition and both facings | Deterministic authored pose, collision and foot/knife identity; no idle flash in locked recovery, hidden added startup or animation drift under hitstop/slow. |

## 6. Wound and complete-route eligibility

**W01 — predicate boundaries:** isolate Downed with remaining1/2, Waking, AirReel approaching floor, standing/crouching, WallSplat, Captured, airborne and already-owned-bleed targets. Wound succeeds only if the actual collision stage sees grounded Downed with a positive timer and overlap on one of absolute frames24/25. A Downed1 target that becomes Waking before collision fails. A target landing into Downed before collision can succeed. Outside the rectangle or after active25 fails.

**W02 — success:** verify capture freeze4, C1…C20 once each, zero damage/meter, release gap120px, both unlock same next unfrozen tick, initial bleed420/clock0/grey20, victim's five actionable throw-grace ticks, and complete cleanup of old reaction/slow/velocity/down/wake/combo/wall/pull state. No remaining Wound recovery resumes. Repeat both corners and all six receiver widths.

**W03 — whiff:** action remains locked through45, first free46, no status/meter, no hidden standing strike and no auto-wait for a later landing. User must supply D; no automatic application after a successful branch.

**W04 — complete routes:** test normal and counter sweep; earliest/latest legal high/low branch contacts from Opening cut; branch contact on airborne targets at more than one actual landing height; 2Hs/623Hs air-reel endings; normal throw and both cashout releases; wall-splat/break routes. Use near and actual tip contacts, midscreen and both corners. Log last hit, first free Fillet tick, D request/start, active24/25, target reaction/down timer and overlap.

The standard stationary grounded branch routes must offer a deliberate Wound opportunity; standard grounded 2S must not. The historical isolated Shark fixture had 10/9 Downed ticks at Wound24/25 after high and8/7 after low; ordinary sweep was already Free and CH sweep Waking. These numbers are a diagnostic comparison, **not a blanket pass expectation for full routes or new target geometry**. Preserve natural eligibility—no source whitelist or Waking exception. If a complete intended near-ground branch route fails due to integration error, repair it; do not quietly bypass startup, travel or protection.

## 7. Bleed and resource boundaries

| ID | Exercise | Required result |
|---|---|---|
| B01 | Wound release, then419/420 unfrozen status ticks with no contacts | Initial20; +3 at30…390; grey59 on419; duration/grey cleared on420 before growth/capture. |
| B02 | Insert global hitstop and defender slow | Hitstop pauses status; individual slow does not. Pair ticks are unfrozen status ticks; no hidden ordinary-throw extension. |
| B03 | Normal hit, ordinary block and FD block | Hit does not refresh/add grey; ordinary block adds floor(rawBaseDamage×.2); FD adds0. Clamp after health/chip changes. |
| B04 | Grey cap/low target health | Never exceed160 or max(0,health−1), including on application, growth, block or later health loss. |
| B05 | Owner hit, owner block, owner/target KO, reset and timeout | Unblocked committed hit/throw clears owned bleed; block does not; end/reset clears everything and pending payout. |
| B06 | Duration1 versus2 on capture tick, and periodic-growth boundary | Expiry runs first. Duration1 fails capture; active duration snapshots after that tick's valid growth/clamp. |
| B07 | Command whiff, strike loss, clash and techable normal throw | No accidental cashout/consume; normal throw never refreshes or consumes its owner's status. A teched throw triggers no throw-caused status cleanup. |
| B08 | Command success at grey0/20/160 | One release health event55/75/215 respectively; snapshot cannot change after capture, no proration continuation or extra grey meter. |
| B09 | Meter fixtures with/without positive bonus and near cap | Raw-base rates exact; normal throw360/180 and command440/220 once; no capture/whiff/tech/Wound reward. Recipient FD settings determine push/cost. |
| B10 | Bleed starts/expires during walk/run/backdash/airdash/coast/attack | Correct target updates/snapshots/clamps; no extra multiplication or speed increase to attack tracks, frame timing, jump height or throw reach. |

## 8. Commands, FD and reliable jump counterplay

Run each of Vault and Skim against ordinary guard, sustained FD, valid jump, crouch/high/low strikes, throw attempts and empty neutral. Verify both entry and capture predicates and actual distance. Use c.S→f.S→grab, c.S→f.S→5Hs→grab, and Opening cut→grab at near and actual reachable-tip starts. At ordinary/full-FD near fixtures with a stationary guarded target, the finite lunge must reach once blockstun/grace have ended. There is no promise to catch a retreating/jumping target or every possible tip string.

| ID | Boundary | Required result |
|---|---|---|
| C01 | Exact push-halfwidth sum +2000 versus +2001 at capture | Inclusive bound succeeds only when all other predicates hold; one unit outside fails. No guide-box fallback. |
| C02 | Capture on22/23 versus21/24 | Only22/23 can capture. No active extension or repeated pursuit after23. |
| C03 | Last blockstun tick; each of five grace ticks; sixth actionable tick | No capture while protected. FD on the later legal tick supplies no throw immunity. |
| C04 | Target ordinary attack startup/active/recovery | Eligible when grounded/unprotected; a simultaneously connecting strike still defeats capture. 6P upper protection alone does not evade it. |
| C05 | Target already airborne/prejump at attempt start | Attempt latches failure even if target lands before active22. |
| C06 | Accepted jump at early approach, final approach, capture tick, or first free post-stun tick | Capture fails; latch persists through landing and remaining active frame. |
| C07 | Fresh Up+FD and buffered Up+FD while otherwise jump-legal | Jump is accepted before grounded FD, clears grounded guard/FD and defeats both grabs. Repeat during final stun ticks and with sufficient/empty meter. |
| C08 | Held FD alone; held Up with no live edge; Up edge expired outside5-world-tick buffer | No invented autojump. Held FD alone loses to a legal in-range capture; stale held Up is not called an accepted jump. |
| C09 | Up during a true action lock or air quota exhausted | Rejected as an illegal jump; do not latch merely from raw Up. A later still-valid buffered edge can be accepted when legal. |
| C10 | Opponent melee or projectile connects on proposed capture tick | Strike wins before pair safety; no capture, consumed bleed or payout. Repeat both player indices. |
| C11 | Normal/normal, normal/command and command/command simultaneous legal captures | Symmetric clash; six freeze,12/12 recovery,120px gap, zero damage/consumption; no player-index bias. |
| C12 | Miss, interrupted lunge, no bleed at entry/capture | Correct complete whiff or hit reaction; no strike fallback, air grab, homing or deferred capture. |

## 9. Paired sequences, throw tech and release

**Q01 — exact clocks:** run Wound, forward/back normal throw, Vault and Skim. Check C0, declared capture freeze, each C1…CN, release event, release freeze and each role's locked recovery tick. Wound is4/20/0 with0/0 recovery; normal throw6/24/8 with12/14; cashout6/28/8 with16/18. First actionability differences are exactly0/+2/+2. No counter-slow residue changes either role's clock. Successful pairs do not resume old active/recovery frames.

**Q02 — placement:** every pair track sample and release in both facings/corners matches the JSON after common wall translation. Gaps remain120/170px, not shortened independently by wall clamps. Back throw swaps once; others do not. Test all six receiver push widths. Physical body roots and visible grip alignment agree; socket normalization never alters geometry/range.

**Q03 — independent safety:** incoming projectiles can defeat capture before C0 confirmation. After confirmation, independent hits/throws cannot damage either pair participant; projectile lifetime still advances. On release recovery, strikes can hit and interrupt each role independently; throws cannot bypass the role lock/grace. Round timeout/KO/reset clears pending events; no double/late payout.

**Q04 — late tech:** Fillet forward/back normal throws accept a valid P+K edge on each C1…C6, reject C7, reject old held P+K, and accept only still-live buffered edges from capture freeze. Test either direction/neutral, split P/K press timing, forbidden S/Hs/D mixture, and FD macro alone. Tech applies no health/meter/throw-caused status event and uses6 shared freeze,12/12 recovery,120px gap, no side swap, and five grace ticks for both on unlock.

**Q05 — universal adapter:** repeat late-tech success/failure for all other characters' ordinary ground throws. On no tech, their six-tick gate commits on C6; each original damage/reach/side-swap/launch/knockdown/post-contact recovery matches the latest baseline, with authored hitstop paid once. Do not replace them with Fillet's standing throw. Air throws, command/stance captures and Wound remain outside late-tech scope. Report the six-unfrozen-tick timing addition as intentional.

**Q06 — release fairness:** neutral normal throw/Wound releases are outside Fillet's ordinary throw reach. Test the selected medium poke and retreat/guard responses at120px using actual target geometry; label matchup-specific results. Cashout170px is a modest+2 neutral release, not a guaranteed follow-up. Ordinary throw/cashout cannot earn Wound from a merely visual tumble; the released state is standing.

## 10. Determinism, integration and playable delivery

**R01 — rollback:** save/restore before and after every important boundary: hitstop start/end, alternating slow, input-buffer expiry, named cancel, Passing cut side update, dash/coast transition, status expiry/growth, Wound contact, command jump latch, capture arbitration, tech C6, final pair tick, release freeze, role unlock, wall transfer and KO. Replay identical input and compare all state, geometry/pose IDs, resources and checksums exactly. Include rollback across a failed grab that later observes the target land.

**R02 — parity:** replay the same golden input/state fixtures in native and shipped Godot/browser builds. Verify matching gameplay hashes/contact events. Training frame stepping must show the same boxes/pose as actual collision and no duplicate/extra terminal active tick. Workshop editing and reloading must not erase extensions.

**R03 — complete presentation:** inspect all26 attack clips, all24 locomotion/reaction clips, each paired success, whiff, tech and interruption path in both facings. Confirm short LEFT c.S→long RIGHT f.S continuity, stable blade identities, coherent support feet, exact active reach, real exposed anatomy, full recovery and no frozen T-pose/idle fallback. Fill in missing sockets/in-betweens autonomously.

**R04 — ordinary play:** complete a training session and local match with Fillet on each side, both control schemes, each opponent and stage. Exercise the full base-pressure→branch knockdown→Wound→enhanced movement→cashout loop plus its defensive failures. No crash, stuck capture, unreset status, inaccessible action, broken menu/import or accidental old move is acceptable.

**R05 — delivered report:** include final commit/build/tuning hashes, schema/core versions, exact commands, executed case IDs and results, preserved-data diff, playable entry point and remaining external blockers if any. Separate historical tests, newly executed tests and reasoned expectations. Repair behavioral failures before delivery; do not mark a required case passed from a static authoring preview or planned future test.
