# Recovery, combo gravity and walls

Fillet (P1) versus Shark (P2) is the first matchup and the default selection, home-screen pairing and editor focus. All six fighters remain selectable. These are editable first-pass mechanics, not measured frame-for-frame parity with a particular Guilty Gear Strive patch.

## Numpad notation

Directions are relative to facing, never keyboard bindings:

| 7 up-back | 8 up | 9 up-forward |
|---|---|---|
| **4 back** | **5 neutral** | **6 forward** |
| **1 down-back** | **2 down** | **3 down-forward** |

`j.` means airborne; `+` means simultaneous buttons; `236P` is a motion followed by P. P/K/S/Hs/D remain button names. The universal sweep is **2D** (also accepted on 1D/3D), and ground throws are **4P+K** / **6P+K**. The exact grounded back+P+K chord now belongs to back throw. FD still uses away + its macro or another pair of P/K/S/Hs. Down-back+P+K and airborne away+P+K still permit FD. The dedicated FD macro wins if also held.

## Move editor

The existing `pushback` JSON field now explicitly means grounded-hit displacement; existing authored values retain their units. The Hit Reactions section exposes:

| Property | Meaning / units |
|---|---|
| Ground knockback | Horizontal displacement on a grounded hit, in pixels, away from the attacker |
| Air knockback | Separate displacement on an airborne hit, in pixels |
| Block pushback | Separate displacement on block, in pixels; FD multiplies this value |
| Ground launch | Upward speed on a grounded hit, pixels per 60 Hz tick; zero leaves normal hits grounded |
| Air launch | New vertical speed on an airborne hit; negative values drive the target downward |
| Knockdown | None, Soft, Hard |
| Down duration | Unfrozen ticks on the ground before wakeup begins |
| Wakeup duration | Protected ticks before control returns |
| Wall damage | Contribution on an unblocked strike; throws do not add wall damage |
| Throw reach | Maximum gap between the two pushboxes, in pixels; only used for throws |

Horizontal knockback is a per-contact displacement, preserving the existing combat model; it is not a continuous velocity. Launch is a velocity and gravity updates it on each unfrozen tick. Strike rectangles remain separately editable; throws use their body-gap range, not the strike rectangle.

A launched or airborne hit enters air reel and cannot block, jump, dash or air-tech until landing. Each later hit replaces its launch speed and pending knockdown settings. A move with no knockdown flag still gives an airborne target a soft landing recovery. Ordinary grounded hits with no launch/knockdown recover from hitstun normally. Grounded knockdowns with zero launch make a minimal drop into ground recovery.

Soft knockdown automatically techs **in place**: down duration, protected wakeup, then control. Hard knockdown uses the longer authored down duration. Neither requires a button; movement during down/wakeup does not choose a tech direction. Both are immune to strikes and throws while down/waking; OTG attacks and manual techs are not implemented. The first actionable tick after wakeup uses the existing buffered reversal check. Reversal eligibility itself adds no invulnerability.

Defaults: soft down **6f + 8f wakeup**; hard down **36f + 8f wakeup**. `5Hs` and `623Hs` are provisional soft launchers. Most other grounded normals cause standing hitstun. All other airborne hits default to soft recovery. Only `2D`, `4P+K` and `6P+K` have hard knockdown in the shipped move set.

## Sweep and throws

Every fighter gains three slots, appended after the original 22 so their IDs remain stable:

- **2D:** low sweep, 12f startup / 3f active / 24f recovery, 65 damage, hard knockdown. Down+D wins over 6D when down-forward is held. This is a normal, so normal special-cancel rules and the universal same-button command route apply.
- **4P+K / 6P+K:** 5f startup / 2f active / 30f recovery, 80 damage, 20px body-gap range, hard knockdown. Back throw exchanges sides at contact while respecting the stage boundaries; forward throw keeps sides. Throws start from neutral, not from a gatling. They use P artwork until dedicated clips exist.

Throws cannot grab airborne, downed or waking targets, targets in hitstun, or ordinary blockstun. Guard-break blockstun deliberately loses throw immunity. Throws can catch a grounded attack's startup/recovery. If a strike and throw connect on the same tick, the strike wins. Simultaneous connecting throws clash without damage. A manual throw-tech window is not implemented. Throws still have the universal outgoing same-button command route after contact, consistent with the existing all-attacks rule.

All attacks, including throws, retain the **5f minimum startup**. The new sweep uses the existing Drive artwork while dedicated low-sweep art is pending.

## Combo gravity

Only hit reactions use scaled gravity; normal jumps keep base gravity. The first **X hits** have no change. Default X is **5**. Hit six uses 110%, hit seven 120%, up to a 200% cap. All three settings are in **Combo gravity & walls**.

`gravityPercent = min(cap, 100 + max(0, hitsReceived - X) * step)`

Base gravity is 85 world units per tick (0.85 pixels per tick squared). Integer multiplication/division is deterministic. Hitstop freezes launch, gravity and recovery clocks. A true air-reel/splat sequence keeps its hit count even if the numeric hitstun timer expires. Recovery and wall-break neutral reset clear the count; the next combo starts unscaled. Counter hits count as one hit. No damage scaling has been added.

## Walls

1. Unblocked strikes accumulate damage on the defender's wall-damage total. A hit within **160px** of either boundary contributes its full authored amount; farther hits contribute one quarter. Blocks and throws contribute none. Damage begins decaying **60f** after the latest strike, at **20 per tick**. These values and the default **1,000 durability** are editable.
2. A strike reaching durability while within **20px** of the wall pins the defender there for **60 unfrozen ticks**. Hitstop pauses this timer. The defender is vulnerable to strikes and cannot act. Wall cracks and a WALL SPLAT call expose the state.
3. Another strike during the splat breaks the wall. It deals its normal damage plus **50 bonus damage**. A **90-tick** shatter/curtain transition freezes combat, the round timer and meter clocks, and consumes gameplay presses. Positions reset beneath the curtain two-thirds of the way through; both fighters resume standing in neutral on a new ground variant. Health, Momentum and character choices carry through. Combo/knockdown/wall damage reset. A KO from the break is announced after the transition finishes.
4. A splat that expires without a follow-up drops into soft recovery; it clears accumulated wall damage and does not award a break bonus.
5. The attacker receives **Positive Bonus** for **360 unfrozen ticks**: earned Momentum is multiplied by **150%**, plus **0.05% passive Momentum per tick**. FD suppresses both gains while used. Bonus duration, gain multiplier and regeneration are editable. Positive Bonus adds no new meter spending; FD remains the only spend and Negative Penalty remains deferred.

The three ground variants currently share a layout and use different labels/tints. The full stage-travel artwork, dedicated splat/fall/wakeup/throw/sweep animations, super-specific wall-break knockdowns, Strive's exact wall-damage formulas and patch-specific Positive Bonus effects remain future parity/presentation work. Supers are not implemented.

## Persistence and verification

Schema/core **6** adds nine move properties, 13 recovery/wall rules and three move slots. Schema 1–5 files migrate atomically: existing edits stay, previous pushback is copied to all three displacement settings, old grounded moves keep zero launch, and new slots/rules receive defaults. Save locally / JSON export includes the complete set. The archived WASM adapter migrates its previously supported schema 4 and now 5. Online configuration fingerprints include these rules; editing is locked during a match.

All reaction timers, received-hit counts, wall damage/splat timers, break progress, area index and Positive Bonus are integer snapshot state. Core tests cover both throw directions/facings, guard immunity, strike/throw priority, ground/air/block displacement, soft/hard recovery, wakeup reversal, gravity threshold/cap/reset, both walls, missed-splat recovery, break KO ordering and replay. Godot checks actual editor application, migration and live-input wall breaks, plus 1/8/12-frame delayed, jittered rollback through the full transition.
