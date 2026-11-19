# Shark and Fillet — Drive mechanics

Implemented from the user’s [2026-11-17 batch 2](move-batches/2026-11-17-batch-02.md). The original upload and art briefs remain unchanged. Schema 17 adds explicit, editable gameplay settings; prose notes do not execute as code.

## Current Shark — Set the Line

The current [Shark v2 contract](../art/characters/shark-kit-v2/README.md) replaces this original kit: 5D / j.D attach a timed line; **2D Reel In is the only follow-up**. It ignores guard, applies no new stun, and keeps free opponents actionable. Existing hitstun or blockstun pauses until the pull ends. 6D Chase is retired.

## Archived Shark — Hooked!

`5D` and `2D` attach a tether **on hit**. Their original guard level, damage and knockdown remain authored: `2D` still causes hard knockdown. While a tether exists, either applying input becomes its pull. The pull activates once, aims toward Shark’s position at that moment, and gives the target horizontal/vertical velocity. It has no damage, hitstop or hit counter increment, and cannot be guarded. It can lift the target out of knockdown. Direction does not home after activation; ordinary gravity, pushboxes and walls apply.

Provisional pull values: **10f startup / 1f active / 10f recovery**, **18 px/f speed**, **24f hitstun/travel budget**. The speed uses the dominant axis to keep integer simulation deterministic. One pull is available per attachment. Repeating D after using it performs the pull animation without another drag. There is no tether distance limit or timer in this pass.

Shark being hit clears his tether. Once the pull is used, **any subsequent attack contacting either fighter on hit or block** consumes it, including projectiles and throws. A whiff does not. An unused tether survives knockdown and blocking. Round resets and wall-break travel clear all statuses. This is separate from `214S / j.214S`’s existing special hook/reel behavior (the air slot ID remains `j.214P` in saved data).

## Fillet — Vein Ripper

The submitted `5D` remains an **overhead, soft-knockdown ender**, with **20 / 3 / 26**, 45 damage, and −9 on first-active-frame block. Its hit applies bleed and adds **20 grey life multiplied by that hit’s combo damage scale**. Every **30 action frames**, bleed adds **2 grey life**. Other unblocked hits refresh the bleed timer without reapplying the initial amount or resetting the periodic clock.

Blocked Fillet attacks add **20% of their unscaled on-hit damage**, rounded down, as grey life; this includes Faultless Defense. FD still prevents normal chip damage. Grey life is bookkeeping, **not lost HP**. Its provisional cap is **300**, further limited to current HP minus one. Periodic/block accumulation cannot KO.

While bleeding, `5D` becomes a leaping **ground command grab**: **16 / 6 / 26**, **60 base damage**, **30 px extra throw reach**, **6 px/f forward travel**, **6.5 px/f initial lift**, **24f hitstun**, soft knockdown. It moves during startup/active, retains configured run inertia, uses normal gravity, and continues through landing. It grabs grounded targets while the attacker is at most 80 px above the floor; targets can jump out. It respects ordinary throw immunity, including blockstun and wakeup grace; guard break keeps its existing exception.

A successful grab deals scaled base damage **plus the entire stored grey-life amount unscaled**, then clears bleed. That conversion can KO. Whiffs do not spend bleed. Once selected at startup, the grab keeps its timing even if bleed expires before contact; without a remaining status it receives no grey-life bonus.

Fillet being hit clears her bleed and marker on the opponent. It also clears after **420 action frames without an unblocked hit** (7 seconds at 60 Hz, excluding shared hitstop and wall travel). Blocks do not refresh. Clearing the marker refunds all pending grey-life damage because it never subtracted HP. Round resets and wall-break travel clear it. Trades cannot leave a status attached by an owner who was hit in the same exchange.

## Authoring and presentation

- Browser: **Drive mechanics** tab has 18 new fields, descriptions, ranges and normal undo/export/autosave support. **Drive test** can apply a status, apply then repeat the input, or wait for bleed expiry. The first hit in the latter modes is unguarded; the selected target behavior applies to the follow-up. No contact is forced.
- Godot: **Development → Drive mechanics** exposes the same values. The core owns status clocks, conditional move timing and damage; snapshots include them for rollback.
- Tethers draw between fighters; grey life appears in the health bar, with status text. Both are also visible in the editor’s shared preview.
- Follow-ups inherit the applying move’s phase hurtboxes and existing artwork, damage scaling, hitstop, down/wake durations and pushback. Their base strike timelines/multi-hit settings do not affect the pull or grab. Dedicated follow-up art and separately authored hurtbox profiles remain future work.
- Older move files migrate by adding these defaults while preserving all previous values, notes, reference images, movement profiles and hit/hurtbox edits. Existing local drafts still take precedence over the bundled batch. Use **Load latest workshop batch** in native Development to restore the submitted preset deliberately.

The full [PDF control guide](../exports/FightGuild-Move-Workshop-Guide.pdf) documents all 104 active move controls. Current builds are in `build/FightGuild-Move-Workshop.html` (offline browser editor) and the native Godot project.

## Art direction received

Shark’s `5Hs` brief still calls for an overhead polearm slam, coverage down to the ground and a shoulder-rest flourish. No new attack sprite sheets or pose references are generated by this mechanics pass. The uploaded active-frame-10 key outside that move’s seven active frames remains unchanged for the user to review.
