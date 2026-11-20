# Fillet v1.0 — engine implementation contract

## 1. Execute the complete implementation

Implement this complete character now, validate it, and deliver the playable result for review. Do not pause for per-move, frame-data, pose, system-design or animation approval. The user has authorized replacing Fillet's saved tuning and has delegated the remaining implementation decisions. Resolve routine implementation details autonomously, retain the stated behavior, and report material deviations with the finished result. Review follows implementation.

This packet is an **authoring specification**, not a directly importable schema-22 Workshop save. Its authoritative inputs are `FILLET_SPEC.json` for actions and mechanics, `MOVEMENT_ANIMATION.json` for locomotion/reaction/pair tracks, `FINAL_MOVE_VALUES.json` for the complete scalar inventory, and `FRAME_GEOMETRY.jsonl` for derived frame geometry. This document resolves engine semantics; `ACCEPTANCE_TESTS.md` defines observable completion. A derived table or viewer must be regenerated when its source changes. Never silently discard an unsupported extension during import.

The reconciled source is branch `feat/godot-combat-lab`, commit **`cd8b0cedabfd508b0d82be2841d640e37928ef91`**, which already implements contextual c.S→f.S and universal hard-knockdown 2S. Core/schema version remains 22, move count 45, field count 138, and rules revision 1. The current Workshop batch is `2026-11-19-slash-sweeps/FightGuild-Slash-Sweeps.json`, SHA-256 `694db863a698510ddbedb8fb2ffc1ac20d7c9809be5994da36b503f2b1801510`. Reconcile subsequent upstream changes before coding without undoing them. Earlier `a9b3bada...` probes are historical, scoped evidence; they are not proof that the new systems already exist.

Reuse the implemented [contextual selection and cancel logic](https://github.com/H1p5t3r/Fight-guild-/blob/cd8b0cedabfd508b0d82be2841d640e37928ef91/core/fight.cpp) and [stable IDs/version declarations](https://github.com/H1p5t3r/Fight-guild-/blob/cd8b0cedabfd508b0d82be2841d640e37928ef91/core/fight.h). Extend them with the exact allowlists below; do not build a second competing c.S/f.S dispatcher.

### Scope of changes

Replace Fillet's tuning, collision, locomotion, attacks and presentation with this packet. Preserve the latest authored data for Anvil, Hammer, Smoke, Tapper and Shark. In particular, their newly implemented 2S sweeps remain as they are; do not revert them to the older baseline or remove their existing 2D definitions. Fillet alone uses the specified slot-6 sweep and disables its old slot-22 normal 2D.

The intentional shared changes are: versioned support for the new data/state; two appended disabled-by-default stable slots; valid fresh/buffered jump priority over grounded FD; normal ground-throw late tech; and consistent capture arbitration, including same-tick projectiles. Other characters retain their authored damage, reach, timings, hitboxes, movement and legacy cancel rules except where those declared shared systems apply. New named-route, authored-anatomy, root-track, coast and facing policies opt in through Fillet's data; they must not silently replace another character's policies.

## 2. Stable action inventory

Keep all existing IDs. Append `236D` at slot 45 and `214D` at slot 46; new move count is 47. The other characters receive disabled records at those slots, never copies of Fillet's attacks. If upstream has already allocated these numbers, migrate by stable string ID and use the next free indices without renaming or overwriting an existing action.

| Group | Active stable IDs and current indices |
|---|---|
| Standing normals | `5P:0`, `5K:1`, `c.S:32`, `5S:2` (f.S), `5Hs:3` |
| Crouching normals | `2P:4`, `2K:5`, `2S:6` (sweep), `2Hs:7` |
| Command normals | `6P:8`, `6Hs:11` |
| Air normals | `j.P:17`, `j.K:18`, `j.S:19`, `j.Hs:20` |
| Specials | `236P:14`, `236S:15`, `236S>6S:26`, `236S>2S:27`, `236K:25`, `623Hs:16` |
| Ordinary throws | `4P+K:23`, `6P+K:24` |
| Drive actions | `5D:13` (Wound), `236D:45` (Vault), `214D:46` (Skim) |

This is 15 normals plus 6 specials, 2 ordinary throws and 3 Drive actions: **26 enabled actions**. Disable Fillet's other 21 existing slots: `6K`, `6S`, `6D`, `j.D`, `2D`, `214S`, `j.214P`, `214S>P`, `j.214P>P`, `[S/Hs]`, `[S/Hs]>attack`, `st.P`, `st.K`, `st.S`, `st.Hs`, `st.2D`, `st.236D`, `j.4P+K`, `j.6P+K`, `6[Hs]`, `5[D]`. A disabled definition contributes no selectable action, route, collision, meter or hidden hold follow-up. Retaining its historical metadata is acceptable.

D is Drive. No Fillet normal 2D and no implicit 2K→2S gatling are enabled. No super or Roman Cancel is required or enabled by this implementation.

## 3. Data model, migration and parity

Implement an explicit versioned loader/compiler for this authoring format. All 138 scalar values are present per action; zero is an authored value. Preserve the documented inactive compatibility values (`wallDamage` and smear fields) as metadata without inventing runtime effects. The current scalar field layout can remain stable while extension tables carry exact routes, timelines and behaviors.

Add fixed-size, deterministic representations for: named destination sets and inclusive windows; absolute hurtbox and pushbox keys; root segments and vertical keys; explicit contact kind (`strike`, `normal_capture`, `command_capture`, `wound`); action-entry gates; fixed-duration owned bleed; command-attempt jump failure; post-contact action age; paired state and deferred release events; facing locks; locomotion/animation phase; dash speed snapshot/coast flags; and the shared tech gate. Do not encode a command grab as an ordinary strike with a cosmetic animation or an old conditional 5D variant.

Bump the combat/save/snapshot compatibility version for the changed layout and rules. Starting from the reconciled version 22, use version 23 and advance `RULES_REVISION` from1 to2, or the next unused compatible versions if upstream has since advanced. Migrate old 45-slot saves by stable ID, add two disabled slots for untouched characters, and preserve all old records and art metadata. An old save without Fillet's extension tables remains a valid legacy save; installing this packet is an explicit complete Fillet override. Do not accidentally combine its new scalars with legacy hitboxes or old conditional bleed behavior.

Extend tuning/collision hashes to include every authoritative table and relevant policy. Include new state in snapshots, restore, reset and checksums. Native C++, its Godot bridge/model, browser/WASM bindings, training previews, Workshop import/export and save validation must agree. Use existing code-generation paths where available; update constants and array bounds in every consumer. Unknown schema/features must produce actionable errors, not partial success.

`legacyHurtPhaseFallback` is compatibility/reference data. For final Fillet runtime, the absolute timeline is authoritative; the three-phase fallback must never replace it. Export the new timelines and named routes faithfully so an edit/export/reimport does not change gameplay.

## 4. Coordinate and clock definitions

The simulation runs at 60 world ticks/second. Distances are integer hundredths of a pixel. Rectangles are root-local `[left,bottom,right,top]`, facing right, positive Y upward. Left-facing mirroring is `[-right,bottom,-left,top]` followed by root translation. A blade or effect has no hurt region. Maintain separate legs, torso/arms, head and optional extension anatomy.

Action frame 1 is the tick on which input is accepted. Startup `S` names the first active tick. Windup is 1…S−1; active is S…S+A−1; recovery is S+A…S+A+R−1. Total locked duration is S−1+A+R; input may execute on the following tick. Cancel bounds use **completed** source action frames. A cancel after completed frame q begins destination frame 1 on the next advancing actor tick, without finishing the old animation.

Hitbox keys use active-relative frames. Hurtbox, pushbox, mask, root, low-crush and animation keys use absolute action frames. A key holds until its successor. A missing extension region means no extension; it does not inherit the prior key's extension. All ordinary strike tracks in this kit use one hit group: several boxes/keys are still one contact per action serial. Capture guide boxes are visual aids, not strike hitboxes or the true throw-range predicate.

Separate these clocks explicitly:

| Clock | Advances when | Owns |
|---|---|---|
| World/input | Every step, including hitstop | Input history and five-world-tick buffer |
| Unfrozen combat | No global hitstop/stage transition; round active | Bleed duration/growth, round time, projectiles, paired sequence |
| Actor action | Unfrozen and this actor not held by counter slow | Action age, movement, ordinary stun/recovery, locomotion keys |
| Paired sequence | Unfrozen shared counter | C1…CN body tracks, tech window and release |
| Presentation | Reads resolved simulation state | Body pose/geometry; impact camera may use its separate existing clock |

Counter freeze is **total shared freeze** when the explicit field is nonnegative; it replaces base hitstop. Counter slow alternates defender held/advancing ticks, starting held. Twenty-five slow ticks contain 13 held ticks; 35 contain 18. Slow does not slow the opponent, bleed, projectiles or the round timer. Extra counter hitstun is a separate value. Shared hitstop freezes physical roots, poses, attack keys, pair phase and actor clocks; inputs continue sampling and aging.

Preserve the current FD payment-on-world-ticks behavior during hitstop and actor-held ticks when FD is genuinely active. Reserve FD attack/dash chords, but **never consume Up solely because FD was requested**. On a legal advancing tick, resolve an available fresh/buffered Up request before grounded FD activation/early-return. A successful jump clears grounded FD/guard before collision and cannot block during prejump; suppress the grounded FD payment for that accepted-jump tick. Air FD may begin when airborne and otherwise legal. This does not add held-Up autojump: only an unconsumed fresh edge in the existing five-world-tick window can be accepted. Locks, zero extra air-jump quota and invalid cancels still reject jumping.

## 5. Deterministic tick and contact ordering

Retain existing non-capture strike behavior unless explicitly changed here. Refactor only as needed to make the following ordering observable and rollback-safe:

1. Sample input using the applicable saved facing. Preserve pressed/held/consumed history. Update permitted FD state/payment with the jump-priority exception above. A shared-freeze tick returns without advancing combat status, roots, actions or pairs.
2. On an unfrozen combat tick, decrement active bleed duration first. Expiry clears bleed/grey before periodic growth or a new capture. Otherwise advance growth, then clamp grey. Advance the round and projectile clocks under their existing policies.
3. Resolve already-confirmed pair ticks/tech separately from ordinary actor control. Clear pre-existing individual slow on pair entry; a pair cannot desynchronize because one actor was counter-slowed. Existing projectiles continue their lifetimes while the pair is untargetable.
4. For independent actors, determine advance/held status, preserve prior stun/landing/grace needed for boundary tests, process valid controls, integrate motion and landing, and resolve the declared pushbox policy. Any accepted target jump updates an in-flight command attempt's failure latch before capture tests.
5. Resolve the exact current collision/pose record. Collect strike, projectile, normal-capture, command-capture and Wound candidates before committing pair safety. Use the resulting current geometry and both the prior/current protection state where needed to protect a final locked tick.
6. A strike/projectile that legally connects with either prospective pair participant on that tick defeats entry to that pair. Apply the ordinary strike result; do not consume bleed or begin capture. This includes an opponent projectile reaching Fillet on the proposed capture tick. Preserve existing guard/armor validity when deciding whether a strike truly connects. Independent strike resolution must not be hidden by setting `Captured` too early.
7. Two simultaneous legal ground-capture candidates clash, including normal/command combinations. Route them to the symmetric break outcome below; no damage or bleed consumption. Wound is not a normal throw or command capture and is not techable. A surviving single valid capture/Wound enters its pair exactly once.
8. Resolve remaining ordinary contacts and resources, then commit action ages/end transitions. A hit group or capture attempt cannot fire twice. Preserve the resolved last-locked-tick pose for the renderer/debugger even when the next state becomes neutral; never show idle one tick early.
9. Check KO/timeout after this tick's committed health event. End/reset clears pending pair events and all bleed. Nothing may deal delayed damage after round resolution. Timeout during a pair uses health already committed, not an uncommitted future release.

For a Fillet capture, the target must be grounded, in a free reaction, and outside hitstun, blockstun, valid prejump, landing lock, throw grace, paired recovery, knockdown/wake and another pair. The source must be grounded on the capture tick. Ordinary attack startup/active/recovery is throwable unless an independent protection applies. **FD alone is not throw immunity**; blockstun and post-stun grace are. Do not throw on a timer's final protected tick merely because control decremented it to zero before collision.

The core's other existing character-specific captures retain their authored eligibility unless they participate in the intentional shared arbitration/normal-tech changes. A low-crush or upper-hurtbox mask is not automatically a throw-invulnerability flag.

## 6. Exact collision, movement and presentation

The finalized standing reference envelope is legs `[-5400,0,6000,6200]`, torso/arms `[-3600,5200,3500,11800]`, and head `[500,11800,3200,14600]`, in raw root-local units. It replaces the old generic standing body wherever the final data explicitly uses that reference, including ready and restored standing capture/recovery keys. Do not apply this replacement to crouch, air, low-profile, reaction or other separately authored anatomy. The wide planted-foot hurt envelope is not the pushbox: ordinary standing push half-width remains2800 and height13800. Load the exact final per-frame boxes rather than reconstructing them from a single generic silhouette.

Evaluate the authored hurt timeline before the phase/window hurt mask. Thus 6P retains only its legs during absolute frames 3–12 (`hurtWindowMask=1`); all regions return on frame 13. Do not interpret that as unconditional immunity to every mid: an overlapping remaining leg hurtbox can still be hit. Do not grant throw immunity to 6P.

Evaluate `pushboxTimeline` on the same absolute-frame hold semantics as hurt anatomy; a single fixed per-action shape is insufficient. Crown/Heel share standing body load and a 138px-high pushbox on frames1–5; Heel changes to its crouch anatomy and 80px-high pushbox from frame6. Skim has standing push height138 on1–5, low height52 on6–21, and standing height138 from22. Their horizontal half-width remains28px. Use the resolved push shape for overlap, movement blocking, stage constraints and capture-width queries. A change in push height cannot itself create a hidden dash, strike, immunity or target displacement.

Skim uses its authored 52px-high body on frames 6–21. On frame 22 restore the ordinary standing body and its authored reaching arm; frame 24 restores standing recovery anatomy without the reach extension. Vault likewise restores ordinary grounded standing capture anatomy on 22–23. Neither has special evasion during capture or recovery. For Vault, explicit low-crush ignores incoming low-level strikes on 6–21; other attacks still use geometric overlap. For Skim, avoidance is geometry only: a mid whose rectangle reaches below 52px can hit it. All masks, boxes and roots remain visible in the training overlay.

Apply current/carry velocity once at attack entry, then move inertia once, truncating signed division toward zero and clamping to the core's ±4000 units. Consume carry. Each advancing attack tick translates by current velocity plus declared root travel and then subtracts 90 units of horizontal friction toward zero, including airborne attacks. Never reapply bleed or fresh run speed on each gatling. Wound, Passing cut, normal throws and cashouts have zero inherited inertia.

Passing cut travels 1250 units on each absolute frame 9–20: exactly 150px before walls. During those frames only, ignore the opponent pushbox; keep strike hurtboxes and stage-wall limits. After frame 20, determine actual side order from current roots, resolve any remaining overlap to valid push separation in that order, and update facing once toward the opponent. Exact-root ties retain the entry order/facing. Lock again through recovery. Do not reuse the old entry-side anti-tunneling order to undo a successful crossing, and do not force a side swap if it never crossed. Active starts on frame 27; there is no homing or invulnerability.

Both cashouts travel 1200 units on frames 6–20: 15×12px = 180px maximum. Clamp their proposed horizontal root against the opponent's current push edge instead of pushing the opponent along or passing through. The move keeps its entry-facing travel direction; no chase/reversal. Vault follows its authored vertical root keys with integer linear interpolation, grounded-special semantics, and no added landing lock. It reaches root Y=0 by frame 21. If interrupted during the arc, transfer its current physical root to the appropriate ordinary hit/air-reel reaction; never snap it to the floor to save the animation.

Fillet's forward run cap is 1120, acceleration 120, walk/backwalk 380, attack friction 90, prejump 4, jump speed 1450 and gravity 85. Backdash is 10 ticks at 850, committed on 1–4, allowing legal attack/jump/FD/guard from 5; no invulnerability. Forward air dash is four locked pause ticks followed by five burst ticks at 2000; one use per airtime, no air backdash or extra jump. The first natural post-burst tick clamps current/carry horizontal speed to 650 before buffered inputs. An attack cancel during burst instead inherits the actual burst velocity once. The coast clamp does not apply to unrelated run jumps.

Air attack landing cancels an impending same-tick attack contact and applies at least the global three-tick air-action landing lock: j.P 3, j.K/j.S 4, j.Hs 6. Empty landing has no gameplay lock. Grounding resets air quotas once. All locomotion, block/reel/down/wake and paired clips use the authored deterministic phase tables. Opt in Fillet's facing policy; keep others' existing facing behavior unless a shared capture requires a lock.

Follow `ANIMATION_AND_ART.md` and the Fillet pose/staging references, including short LEFT c.S and long RIGHT f.S, and create all required in-betweens without a new approval pass. Where a final raster frame does not exist, implement the complete deterministic procedural pose/clip path specified there; do not leave an idle fallback or block the gameplay implementation waiting for external art. Longer blade remains in anatomical RIGHT, shorter blade in LEFT in both facings. Physical root, exact collision and action duration take precedence over decorative trails. Body settle is internal drawing deformation bounded by the specified 4px envelope; it adds neither movement nor startup. Author hand/knife/contact sockets with the resulting art; sockets cannot resize gameplay boxes or capture range. Legal cancels/interruption replace the animation immediately. Keep the final recovery pose while locked.

## 7. Inputs and exact routes

Within a contextual source, valid explicit follow-ups take priority. Otherwise Fillet resolves recognized motion actions before the normal-throw chord, then directional command normals, then c.S/f.S proximity/ordinary normals. Preserve simplified mappings explicitly. A recognized unavailable cashout motion consumes/rejects that command; it does not become Wound or another D action. Wound is grounded D without a recognized cashout motion and is unavailable while the target already has Fillet-owned bleed.

Neutral 5S selects c.S at center distance ≤9000 units and f.S beyond it. The finalized c.S front tip is72px; proximity selection and root-local reach are distinct quantities. During c.S's allowed route, 5S explicitly selects f.S regardless of distance, reusing the newly implemented bypass. Directional 2S remains the sweep. The exact target allowlists replace broad normal/command bit masks and the legacy same-button command exception **for Fillet**. Empty list means no such route. A named same-action light repeat is allowed; do not invent self-cancels for other moves.

| Source | Normal destinations |
|---|---|
| 5P / 2P | 5P, 2P, 5K, 2K, 6P |
| 5K / 2K | 6P, 6Hs |
| c.S | 5S, 5Hs, 2Hs, 6Hs, 2S |
| 5S | 5Hs, 2Hs, 6Hs |
| 5Hs | 6Hs |
| j.P | j.P, j.K |
| j.K | j.S |
| j.S | j.Hs |
| All other actions | None |

Ground lights, c.S, f.S, 5Hs, 2Hs, 6P and 6Hs have exactly the special targets listed in the JSON: 236P, 236S, 236K, 623Hs. 2S has none. Only c.S and the listed air light/medium sources have their authored hit/block jump-cancel permission, subject to actual jump/dash quota. No ground dash-cancel or general whiff cancel is added.

Opening cut 236S can follow to its overhead `236S>6S` or low `236S>2S` after an actual hit/block, during completed source frames 9–17 inclusive. Neither branch can start standalone or on whiff. The normal 2S and branch 2S are distinct stable actions. Low startup 16 and overhead startup 21 are deliberate; late branches are not all guaranteed combos or an unfuzzyable mixup.

The separate bleed-grab destinations are 236D/214D from 5K, 2K, c.S, f.S, 5Hs, 6Hs and Opening cut, only in their listed window and while owned bleed exists. They bypass the legacy Throw-destination rejection and, for this explicit route only, the source special-cancel flag. They never authorize ordinary-throw cancels. The source must have actual contact and **five subsequent completed attacker action ticks** since its most recent contact. Contact is zero; freeze/slow-held ticks do not count. After those five ticks the destination begins on the following action tick. Reset this counter on every new source contact; save it in rollback state.

## 8. Wound and natural OTG access

Wound is 24/2/20, with no cancel entry and zero inertia. Only its authored active rectangles can contact a target that is **currently Downed with a positive remaining Downed timer**, grounded and overlapping. A target landing into Downed before that tick's collision can qualify. A target that changed to Waking cannot. Reject standing/crouching, AirReel, WallSplat, Captured and already-owned-bleed targets; do not wait beyond the two active ticks for a future landing. Ordinary strikes keep their existing Downed/Waking exclusion.

On success, replace the rest of the move with four shared capture-freeze ticks and 20 shared pair ticks. At the final pair tick place centers 12000 units apart, clear old knockdown/down/wake, stun, knockback, velocity, counter slow, combo/gravity/repeat-use and wall/pull/capture residue, and apply bleed. There is no release freeze and no post-release recovery. Both actors first act on the same next unfrozen tick: +0. Give the victim five throw-protected actionable ticks beginning at unlock. Wound deals no health damage and awards no start/contact/release meter; explicitly suppress generic Drive-start gain.

Whiff uses the complete 45 locked ticks and is counter-vulnerable as specified. The attack never automatically activates from a knockdown. The low/high branches' 56 Downed ticks and their own recovery are the intended access routes. Fillet 2S has 32 Downed ticks and 23 recovery and is deliberately too short in the standard grounded route. **Do not implement a source-move whitelist.** Counter slow, late active hits, airborne landing time, movement and corners can change timing/overlap; record the actual window. Keep the authored numbers rather than inserting a special sweep exception.

## 9. Bleed, meter and scaling

Owned bleed is attached to the opponent and identifies its owner. It starts at Wound release with duration 420 unfrozen combat ticks, growth clock zero, and 20 grey life. Each 30 elapsed status ticks adds 3 grey while the duration remains positive. An ordinary block adds `floor(rawBaseDamage×20/100)`; FD adds zero. Ordinary hits do not refresh duration or add grey. Grey does not subtract health until cashout and is always clamped to `min(160,max(0,targetHealth−1))`, including after chip or hit damage.

On a status tick, decrement duration first; if zero, clear before growth or capture. Otherwise advance growth and clamp. A newly released Wound does not immediately lose a tick because the status stage for that tick has already passed. With no interactions, grey is 59 on tick 419 and disappears on tick 420; no growth occurs on the expiry tick.

While owned bleed exists, positive voluntary ground speed/acceleration fields are `floor(base×115/100)`: walk/backwalk 437, run cap 1288, acceleration 138, backdash 977. Air dash/coast are 110%: 2200/715. Apply direction after positive scaling. Walk/run targets update on movement ticks; clamp a running speed to the reduced cap on expiry without multiplying velocity on activation. Backdash/airdash snapshot their effective speed on entry. Natural coast reclamps to 650 on expiry. Run-jump carries existing velocity normally. Never scale authored attack travel, inertia percentage, friction, jump height/gravity, stun, damage, throw reach or frame timing.

Clear a fighter's owned bleed when that owner suffers an unblocked hit or committed throw, either participant KOs, the round resets/ends, duration expires, or its cashout succeeds. Blocking does not clear it. An ordinary throw by the bleed owner does not consume/refresh/cash out that owner's bleed; its pending status clock continues through unfrozen pair ticks. A teched normal throw does not trigger the owner-hit cleanup event. Successful command capture snapshots the post-status-update grey and consumes that owned status immediately; no later growth or expiry changes the stored payout.

Use existing raw-base-damage meter rates and cap/positive-bonus rules: attacker hit ×8, defender hit ×4, attacker block ×4, ordinary guard ×3. FD defender gains zero; contact cost uses the **recipient's** FD base/multiplier plus attack-level cost. Continuous FD drain is separate. Non-Wound ordinary specials retain their 100-unit entry gain. Normal throw pays 360/180 and command throw 440/220 once at successful damage release, using base 45/55 only; grey adds no meter. Wound, tech, failed capture and throw whiff pay no throw reward.

Normal strikes retain starter proration, combo scaling, minimum damage, launch/air launch, gravity and wall-speed rules exactly as authored/current. `wallDamage` is inert. Counter hits add only their explicit freeze/slow/extra-stun values, not a damage multiplier. A paired release is not a combo continuation; clear its old combo/proration state. Pair damage is unscaled base plus its captured grey exactly once. No attack in this Fillet kit gains an unlisted projectile, armor, guard point, bounce, crumple or invulnerable reversal from retained inactive scalar values.

## 10. Command attempts and paired success

Vault/Skim are 22/2/30, with capture only on absolute frames 22–23. Require owned bleed at action entry and again at capture. The target must be in front and within `attackerPushHalfWidth + targetPushHalfWidth + 2000` center distance. Read actual active push profiles; do not substitute the visual 48px guide box or a universal target width.

At attempt acceptance, latch failure if the target is already airborne or in valid prejump. From that point through the last capture tick, latch failure on any accepted target jump/prejump/airborne transition. Once latched, that serial can never capture, even if the target lands before frame 23. The action continues its finite travel and whiff recovery. An invalid Up press during a lock is not an accepted jump; a valid buffered request on the first actionable tick is. No air capture, strike fallback, late recapture, direction reversal or target homing is permitted.

After a surviving capture, replace the entire remaining attack with the shared pair. Pair entry clears both independent movement/carry/dash/prejump, individual slow, old combo and incompatible reaction state; it retains health, meter and unrelated valid round state. Consume pre-capture attack edges so the initiating command cannot re-fire. Continue sampling new input; ordinary still-buffered edges near unlock may execute then. During the confirmed pair both participants are untargetable by independent strikes/throws; projectiles may continue lifetime/travel but cannot contribute hidden damage. Reject conflicting pair entry; a new pair cannot replace an existing pair.

| Successful sequence | Capture freeze | C ticks | Release freeze | Owner / victim recovery | Center gap | Damage event |
|---|---:|---:|---:|---:|---:|---|
| Wound | 4 | 20 | 0 | 0 / 0 | 120px | None; bleed on release |
| Fillet normal throw | 6 | 24 | 8 | 12 / 14 | 120px | 45 on release |
| Either command cashout | 6 | 28 | 8 | 16 / 18 | 170px | 55 + snapshot on release |

C0 is confirmed capture and starts freeze; it is not C1. After freeze, each unfrozen tick advances C exactly once. At the end of CN, commit the release placement/damage/status once, then start release freeze. Independent role-recovery counters begin on the next unfrozen tick after that freeze. A counter of R consumes exactly R locked ticks; the actor first acts on R+1. Thus ordinary/cashout release is +2 and Wound is +0. Post-release recovery is strike-vulnerable and cannot guard/act, but is explicitly throw-protected. After its recovery, the victim has five protected actionable ticks; decrement after each protected tick, not before collision. Clear the pair relation when scripted pairing ends; later hits can interrupt each role's recovery independently.

Use the exact pair root tracks in `MOVEMENT_ANIMATION.json`. Convert their pixel coordinates, including half-pixels, to integer units before interpolation. Preserve captured entry root/facing and interpolate with signed truncation toward zero. Correct a wall-bound pair by translating **both roots together** by the minimal amount that places both push extents inside the stage. This preserves 120/170px separation and intended side order. Temporarily allow their internal scripted overlap while paired; independent push resolution cannot distort the pair. Forward throw keeps sides; back throw swaps only by its authored track/release. Restore opponent-facing on release. Normalize receiver grip sockets for body presentation without changing capture range, collision or root spacing.

## 11. Shared normal-throw tech and legacy adapter

This is an intentional **universal ordinary ground-throw** dependency. It applies to normal back/forward ground throws for all characters. It does not make air throws, command grabs, stance captures or Wound late-techable.

During Fillet's normal pair, check for a valid tech at the beginning of each shared C1…C6 tick, before advancing its body track or any irreversible throw effect. Valid tech is P+K held, with at least one fresh unconsumed P/K edge in the ordinary five-world-tick history, and no S/Hs/D attack button in that chord. Either direction or neutral is accepted. An FD macro by itself is not tech. Old held P+K without an edge does not auto-tech. Last-five-frame edges from capture freeze can survive into C1; earlier expired inputs do not. Consume the accepted chord. C7 is too late.

For other characters' existing normal ground throws, add a six-unfrozen-tick **pre-commit gate**: at C0 preserve their effective move/contact snapshot and suspend both participants; pay that throw's existing authored hitstop once. After it ends, check C1…C6. If no tech, commit their existing damage, meter, push/back-throw swap, launch/knockdown and other original contact effects at the end of C6, without a second contact hitstop. Restore the owner's original remaining action timeline and the victim's authored reaction from this commit. Do not substitute Fillet's 45 damage, standing release or 120px successful-throw gap for another character. The shared gate adds six protected unfrozen ticks to those legacy successful throws; their authored post-contact behavior remains intact. Capture presentation must remain coherent during the gate. Defer irreversible status cleanup until the unteched commit so tech needs no health/status rollback.

A valid late tech, or two simultaneous legal ground captures at C0, uses the symmetric break outcome: no damage, meter reward, bleed apply/refresh/consume/cashout or side switch; preserve current side order, place centers 12000 units apart around their current midpoint using whole-pair wall correction, zero movement/carry, apply six shared freeze ticks, then 12 locked recovery ticks to each. Both unlock together and each receives five throw-protected actionable ticks. Bleed still ages on unfrozen recovery ticks; “no status change” means no throw-caused mutation, not a paused duration. A normal-versus-command clash also uses this outcome, even though command grabs cannot be late-teched.

## 12. Completion and evidence

Implement mechanics, exact data, complete playable animation clips, training/Workshop visibility, migration, and the required tests in one integrated change. Use the existing project build/test commands and add focused native/replay tests for the new state transitions. Run the acceptance suite, repair failures, and produce a short implementation report identifying the final commit, schema/core versions, hashes, commands run, passed cases, and any external blocker. Preserve a snapshot of the latest pre-change data and a clear diff for the five untouched characters.

Provide a playable build or the repository's normal review entry point with Fillet selectable, an accurate move list, hit/hurt/push overlays, exact frame stepping, both control styles and all new states inspectable. Do not report the authoring viewer as a completed playable implementation. Do not stop after a technical scaffold, static pose sheet or untested import. Complete the gameplay implementation first; the user will review the full character afterward.
