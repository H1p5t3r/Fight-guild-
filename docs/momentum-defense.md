# Momentum and defensive reactions

Momentum is Fight Guild's Strive-inspired resource: a 0–100% gauge displayed in **three equal sections**, approach/offense/defense gains, and Faultless Defense (FD). Each section represents one third of the meter; fill and FD drain remain continuous across the gaps. Player 2's gauge fills from the opposite edge. **FD is the only spending mechanic. Negative Penalty is deferred**, including its meter removal and gain reduction. These are editable prototype rates, not a verified reproduction of Strive's numerical formulas. Supers, Roman Cancels, RISC, Positive Bonus and wall-break systems are not implemented.

## Gain and spending

Both players start a round at 0%. Training can reset both gauges to 0%, 50% or 100%; this setting never applies to versus or online matches. Meter cannot exceed 100% or fall below zero. Idle time and retreat do not change it. A finished round freezes it; reset clears it.

| Event | Default Momentum |
| --- | --- |
| Actual voluntary forward movement | +0.02% per pixel |
| Attack hits | +0.08% per point of authored damage |
| Attack is blocked | +0.04% per point of authored damage |
| Take a hit | +0.04% per point of authored damage |
| Ordinary guard | +0.03% per point of incoming authored damage |
| Start a special or Drive | +1%, once per activation, including whiffs |
| Hold FD | −0.10% per simulation tick (6% per second) |
| Block a hit with FD | −1% plus −0.04% per point of incoming authored damage |

A whiffed normal earns nothing. Knockback, move-authored advance, walking into a wall or pushing against a stationary cornered opponent do not farm movement gain. Ordinary air movement toward the opponent can earn meter. Hitstop does not repeat contact gains, but holding FD continues to drain meter during it. FD suppresses the defender's meter gain while active.

Values are integer hundredths of a percent internally. Fractional movement gain carries an integer remainder in the snapshot. The editor exposes these rates under **Momentum & Faultless Defense**. Changes reset the local round, save with the move set and participate in the online compatibility fingerprint.

## Faultless Defense

Hold away plus **Q** (P1), **numpad Enter** (P2), or **right trigger** (gamepad). Holding away plus two of **P/K/S/Hs** also activates it, except grounded **4P+K**, which now performs back throw; Drive does not count toward the two-button chord. Use down-back for lows. Air guard has no high/low distinction in this prototype.

With positive meter, FD uses a teal shield, prevents chip damage/KO and multiplies block pushback by 3. At a corner, displacement that the defender cannot take transfers back to the attacker. FD does not add blockstun. It cannot cancel an attack or escape hitstun. It can be activated while already in blockstun. The chord reserves attack/jump/dash inputs so releasing it does not produce a buffered attack.

If the gauge has any meter at the beginning of a tick, that tick's FD is valid even when its costs empty the gauge. On subsequent empty ticks the held chord becomes ordinary guard. Release FD to stop its drain. Neither macro nor chord guards when holding toward or simultaneous left+right. Grounded FD stops walking; air FD retains the prototype's directional air movement.

Normals/command normals default to zero chip; specials/Drive default to `max(1, damage / 10)` with integer truncation. **Chip damage** is separately editable per move. Normal guarding can lose a round to chip. FD prevents that damage, including during guard break.

## Block reactions and guard break

Each fighter has three two-frame clips. Contact displays first; after four unfrozen blockstun ticks the clip changes to its settle/hold frame. Hitstop freezes that transition. Stable/pressure clips keep the guard closed; guard break opens the guard and exposes the chest. Current clips share standing artwork for crouching/air guarding; stance-specific drawings are backlog work.

| Reaction | Selection | Gameplay |
| --- | --- | --- |
| Stable block | Attacker negative or even on block | Ordinary blockstun and grab protection |
| Pressure block | Attacker strictly positive on block | Ordinary blockstun and grab protection |
| Guard break | Move's **Guard break on block** flag, with nonzero blockstun | No backdash; blockstun grab protection removed |

The selector computes attacker advantage at contact: `blockstun − remaining active/recovery ticks after the contact tick`. It assumes the current attack runs to completion without a subsequent cancel or interruption. A default 5P has 3 active ticks and 10 recovery ticks: 12 blockstun is even on its first active tick and +2 on its third. The HUD shows this signed attacker advantage. Later cancels do not rewrite the reaction to the original contact.

Guard break overrides the advantage-based pose and lasts for the move's authored blockstun. No additional universal duration is imposed. Backdash presses sampled during the broken stun are consumed, including during hitstop, so they cannot execute through the input buffer as it expires. A fresh backdash works after recovery. A new blocked attack replaces the prior reaction; a normal hit clears guard break and uses hitstun. FD does not undo a move's guard-break property.

The throw resolver uses `throwInvulnerable`: ordinary blockstun/hitstun, airborne targets and down/wakeup recovery are protected; guard-broken blockstun is not. Universal **4P+K / 6P+K** ground throws are implemented. Overhead and anti-air design remains deferred. See [recovery and walls](recovery-and-walls.md). No move is automatically made a guard breaker: enable the editor flag on the tool you want to test.

## Data and validation

Schema/core version 3 introduced `chipDamage`, `guardBreak`, ten Momentum rules and deterministic meter/FD/reaction state. Native protocol 2 uses a 12-bit input mask with FD at bit 2048. Old schema-1/2 move JSON preserves existing edits, defaults new defensive fields, derives special/Drive chip from the saved damage and adds default Momentum rules. Invalid imports are atomic. The current schema is 4, which adds counter-hit and reversal timing fields while preserving those defensive edits; see [combo and timing rules](combat-feedback.md). Existing binary snapshots and mismatched online builds are not interchangeable.

Coverage includes gain/cap/reset, no passive penalty, air/high/low FD, empty-meter fallback, input consumption, chip KO, corner push, late contact advantage, guard-break backdash/throw eligibility, replay restoration, native/Godot/WebAssembly parity and two-peer rollback. Godot UI tests drive keyboard input and all 18 block clips through actual contacts, including both frames. Windows/controller hardware validation remains separate from cross-compilation.

Wall breaks grant a provisional Positive Bonus: 150% earned Momentum and 0.05% passive gain per unfrozen tick for 360 ticks. FD suppresses these gains while used. These values are editable; no additional spend or Negative Penalty has been added.
