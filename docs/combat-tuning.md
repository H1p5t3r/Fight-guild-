# Combat tuning: schema 9

This implements the approved priorities from the [saved Dustloop review](research/strive-dustloop-2026-11-15.md). Values are editable Fight Guild defaults, not a claim of exact Strive parity. The user clarified that block carryover and post-stun throw protection are wanted; **Just Guard / Instant Block timing mechanics are not**.

## Cancel windows

Each move now has separate opening/closing frames for **normal/command**, **special/Drive**, **jump**, and **contextual follow-up** cancels. Bounds are inclusive and refer to the source frame just completed. A close frame of zero means through the end of the move. A valid cancel replaces the following tick. Hitstop freezes the source frame; input sampling and the existing input-buffer aging continue.

`cancelOn` selects eligible events: hit = 1, block = 2, whiff = 4; add the values for combinations. Ordinary whiff cancels also require the existing whiff-cancel setting. Contextual whiff follow-ups retain their separate post-active rule. Shark's stab still requires an unblocked hook hit. Timing never grants a route that the unified gatlings do not allow, and every attack retains its same-button command-normal route within its normal-cancel window.

Default P/K special windows close on their last active frame. K normal/command cancels and enabled K/S jump cancels do likewise. Other ordinary windows remain open through recovery. Fillet's starter and middle rekka follow-up windows close 12 frames after their final active frame. Shark's hook follow-ups close 16 frames after their final active frame. These settings allow immediate and delayed routes without granting a follow-up throughout every recovery frame.

The frame lab reports which windows are open, the age of the executed attack input, actual contact advantage, and gaps. **Use selected timing presets** changes fields in the editor; **Apply move** commits them to the working simulation.

## Damage and repeated moves

Each move has **Starter %**, **Scaling cost %**, and **Minimum damage %**. The opening hit deals its authored damage. Later hits use the starter's percentage and the remaining combo scale:

`effectivePercent = max(thisMove.minimumDamage, starterPercent * remainingScale / 100)`

`damage = max(1, baseDamage * effectivePercent / 100)`

Integer divisions truncate. A move with zero base damage still deals zero. The remaining scale begins at 100 and loses each move's scaling cost after that hit, with a floor of zero. Chip is separate and is not combo-scaled. Combo damage scaling resets when the defender leaves the combo, including the wall-break neutral reset. Air reel, hook reel and splat preserve it even if the numeric hitstun timer expires.

Defaults give P starters 70%, K starters 80%, and most other normals 100%; authored special cases can differ. Most moves cost 8 percentage points. Shark's hooks start at 70% and cost 12 points. Most moves have a 10% damage floor.

| Default route | Damage against the current 1,000 HP fighters |
| --- | --- |
| Fillet `236S > 6S > 2S` | 35 + 23 + 31 = **89** |
| Fillet `236S > 2S` | 35 + 35 = **70** |
| Shark `214S > P` or `j.214P > P` | 25 + 27 = **52** |

Gravity remains a separate system. The first X hits are unchanged (default five). After that threshold, each use of a move from its third use onward adds another 15 percentage points of gravity, on top of the existing per-hit increment, bounded by the existing gravity cap. Repeat threshold and increment are editable; zero disables the relevant repeat penalty. Normal jumps are unaffected. The frame lab shows last-hit base/final damage, effective percentage and current gravity.

## Blocking and throw protection

Ordinary blockstun carries guard through uninterrupted strikes, even if back is released while entering a reversal. Low attacks still require a downward input; overheads still require standing guard. Carryover ends with the first gap. There is no timed-block bonus, parry, Just Guard or Instant Block action.

Normal blockstun, hitstun and completed knockdown recovery grant **five unfrozen ticks of throw protection** after control returns. The timer freezes in hitstop. It is editable from zero to thirty frames. It protects against throws only, not strikes.

Guard break continues to require an actual guard direction, forbids buffered backward dash and allows throws **during** the state. It bypasses throw grace and does not grant grace on recovery. It retains correct high/low guarding and FD. This intentionally differs from the saved Strive guard-crush rule.

## Jump startup and landing recovery

Jumps begin with **four grounded startup ticks** before takeoff, editable from zero to thirty frames. These ticks are vulnerable to strikes and immune to throws; blocking, FD and attacks cannot interrupt them. Input buffering continues, run/step inertia carries through takeoff, and hitstop freezes the startup timer. The frame lab labels this state **PREJUMP**. Its current art reuses the crouching pose.

Landing during an aerial attack clears the attack and enters its authored landing recovery. Shark's air hook defaults to **12f**, its air stab to **10f**, and other air attacks to **3f**. If an aerial attack has already recovered before landing, the global recovered-air-action landing duration applies (default **3f**). Empty-jump landing recovery is separately editable and defaults to **0f**, retaining immediate empty-jump recovery.

During landing recovery the fighter cannot attack, move, block or FD. A strike can score a punish. Inputs can buffer into the first free tick. Landing is not knockdown/wakeup and does not create reversal eligibility or throw immunity. Dedicated recovery artwork remains part of the sprite pipeline.

## FD and corner spacing

Default FD holding drain is **0.25% per grounded tick** and **0.50% per airborne tick**. A full gauge lasts 400/200 ticks before contact costs. Ground/air drain are independently editable. Contact cost is:

`fdBlockCost + baseDamage * fdDamageCost + max(0, attackLevel) * fdLevelCost`

Defaults are 250 units + 50 units per attack level, where 100 units = 1% Momentum; the base-damage coefficient defaults to zero. Holding drain applies in addition, including during hitstop. FD still prevents chip, uses 300% block displacement, and falls back to ordinary guard when empty.

Ordinary block pushback now transfers the displacement blocked by a corner to the attacker, as FD already did. This gives FD a consistent spacing baseline in the corner. No attack hurtboxes or pushbox sizes were enlarged. Momentum still has three visual sections, FD is its only spend, and Negative Penalty remains deferred.

## Counter and attack presets

Attack level 0–4 selects the per-level FD cost and can populate hitstop/hitstun/blockstun from the source's standard table. The editable timing values remain authoritative. Level −1 uses custom timing and no extra per-level FD charge.

Counter tiers set presentation strength and can populate these Fight Guild bonus presets:

| Tier | Extra hitstun | Extra shared hitstop |
| --- | --- | --- |
| 0: minimal | 0 | 0 |
| 1: small | 4 | 3 |
| 2: medium | 8 | 6 |
| 3: large | 12 | 10 |

Tier −1 retains custom values and the original notice size. Heavy counters have larger callouts; rekka and hook follow-up families use minimal effects by default. Button names do not enforce a preset; each move can be edited individually.

Counter vulnerability is a separate mask on the interrupted move: startup = 1, active = 2, recovery = 4. Most moves default to startup + active; throw whiffs also permit recovery counter hits. A non-counterable startup/active interruption is an ordinary hit, while recovery remains punishable. Throws do not inflict counter hits. Persistent victim-only slowdown is not approximated by these shared hitstop bonuses.

## Wall priming

Far hits still contribute one quarter wall damage but now stop accumulating at **50% of wall durability**. Existing higher wall damage is retained when moving away, without further far-range growth. The percentage is editable. Near-wall hits can build to full durability.

A grounded strike that fills the wall primes it; a subsequent grounded hit can splat. An airborne target or a hit that launches can splat when the threshold is reached. The grounded-priming rule is editable. Splat expiry, follow-up break, stage transition and the existing Momentum Positive Bonus remain in place. Their balance is still provisional and the break adds no new resource spend.

## Persistence and verification

Schema/core 9 has 67 move fields, nine movement fields per fighter and 38 global rules. New per-fighter timers, combo factors, move-use counts and diagnostic values are integer rollback state. Online fingerprints include all tuning; editing is locked online.

Schema 1–7 saves preserve authored damage, counter bonuses, movement and existing global rates. Existing moves migrate with unrestricted legacy windows, unscaled legacy combo damage and zero authored landing recovery. Their saved FD holding/contact costs and original combo-gravity increment are preserved. New defensive carryover, throw grace and wall rules are supplied as editable defaults. Schema 8 tuning is preserved when moving to schema 9. All pre-schema-9 saves retain immediate jump takeoff and zero empty-jump landing recovery. **Restore default move set** opts into the complete new starter balance; export existing edits first if you want to keep both versions.

Verification includes inclusive cancel-window boundaries and buffered entry, hit/block conditions, same-button routes, proration/floors/reset, repetition after X, prejump duration/strike vulnerability/throw immunity/inertia, landing input lock/buffering, high/low carryover and gaps, five-frame throw grace, guard-break exceptions, ground/air FD costs, ordinary corner transfer, both wall states, counter masks, old-save migration, editor application and delayed-input rollback.
