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
| Throw reach | Maximum gap between the two pushboxes, in pixels; only used for throws |

Ground/air strike knockback is an authored distance budget travelled over six unfrozen defender action ticks. Initial horizontal velocity is `ceil(distance / 6)` in the hit direction; the last step uses only the remaining distance. Wall contact, landing into knockdown, hitstun recovery, and a new hit can end or replace the remaining travel. Block pushback and throw placement retain their contact displacement. Launch is a velocity and gravity updates it on each unfrozen tick. Strike rectangles remain separately editable; throws use their body-gap range, not the strike rectangle.

A launched or airborne hit enters air reel and cannot block, jump, dash or air-tech until landing. Each later hit replaces its launch speed and pending knockdown settings. A move with no knockdown flag still gives an airborne target a soft landing recovery. Ordinary grounded hits with no launch/knockdown recover from hitstun normally. Grounded knockdowns with zero launch make a minimal drop into ground recovery.

Soft knockdown automatically techs **in place**: down duration, protected wakeup, then control. Hard knockdown uses the longer authored down duration. Neither requires a button; movement during down/wakeup does not choose a tech direction. Both are immune to strikes and throws while down/waking; OTG attacks and manual techs are not implemented. The first actionable tick after wakeup uses the existing buffered reversal check. Reversal eligibility itself adds no invulnerability.

Defaults: soft down **6f + 8f wakeup**; hard down **36f + 8f wakeup**. `5Hs` and `623Hs` are provisional soft launchers. Most other grounded normals cause standing hitstun. All other airborne hits default to soft recovery. Only `2D`, `4P+K` and `6P+K` have hard knockdown in the shipped move set.

## Sweep and throws

Every fighter gains three slots, appended after the original 22 so their IDs remain stable:

- **2D:** low sweep, 12f startup / 3f active / 24f recovery, 65 damage, hard knockdown. Down+D wins over 6D when down-forward is held. This is a normal, so normal special-cancel rules and the universal same-button command route apply.
- **4P+K / 6P+K:** 2f startup / 2f active / 30f recovery, 80 damage, 20px body-gap range, hard knockdown. Back throw exchanges sides at contact while respecting the stage boundaries; forward throw keeps sides. Throws start from neutral, not from a gatling. They use P artwork until dedicated clips exist.

Throws cannot grab airborne, downed or waking targets, targets in hitstun, or ordinary blockstun. Guard-break blockstun deliberately loses throw immunity. Throws can catch a grounded attack's startup/recovery. If a strike and throw connect on the same tick, the strike wins. Simultaneous connecting throws clash without damage. A manual throw-tech window is not implemented. Throws still have the universal outgoing same-button command route after contact, consistent with the existing all-attacks rule.

Startup minimums are **2f for throws**, **3f for P normals**, and **5f for other attacks**. All standard ground and air throws now start in 2f; command-grab timing remains individually authored. The new sweep uses the existing Drive artwork while dedicated low-sweep art is pending.

## Combo gravity

Only hit reactions use scaled gravity; normal jumps keep base gravity. The first **X hits** have no change. Default X is **5**. Hit six uses 110%, hit seven 120%, up to a 200% cap. All three settings are in **Combo gravity & walls**.

`gravityPercent = min(cap, 100 + max(0, hitsReceived - X) * step)`

Base gravity is 85 world units per tick (0.85 pixels per tick squared). Integer multiplication/division is deterministic. Hitstop freezes launch, gravity and recovery clocks. A true air-reel/splat sequence keeps its hit count even if the numeric hitstun timer expires. Recovery and wall-break neutral reset clear the count; the next combo starts unscaled. Counter hits count as one hit. Separate damage scaling and repeated-move gravity are now implemented; see [current combat tuning](combat-tuning.md).

## Walls

1. The left and right walls each have an independent **hidden health pool**, shared by both fighters. Default health is **1,000 velocity units**; 100 units correspond to 1 pixel per action tick. **Wall health** is editable in **Combo gravity & walls**. Health persists without healing until a new round or arrival in the next arena, when both walls refill.
2. A fighter's pushbox collides with a full-height wallbox at x=0 or x=1000px. An outward collision during actual **hitstun**, with nonzero horizontal velocity, subtracts **the absolute incoming horizontal velocity** from that wall's health, clamped at zero. Both horizontal velocity and the remaining knockback budget are then cleared. The speed at impact counts even if only a small gap remained before contact. Grounded and airborne impacts follow the same rule.
3. The impact that reduces positive wall health to zero **does not splat**. The **next separate hitstun collision** with that empty wall causes a **60-action-tick wall splat**. Resting against the wall with zero velocity cannot retrigger damage or splat. A fresh hit giving outward velocity at the wall counts as a new impact. Walking, running, blockstun (including guard break), missed strikes and hits away from a wall do not damage it. Weapon reach is not wall collision geometry.
4. A strike on the splatted fighter breaks the wall, adding **50 bonus damage** and starting the **150-tick / 2.5-second** directional travel. The round timer and meter clocks freeze, and gameplay presses are consumed. Combat positions reset at two thirds while presentation continues to the matching landing position. Health, Momentum and fighter choices carry through. A break KO is announced after travel finishes.
5. An expired splat falls into soft recovery. It does not repair the wall or award a bonus. The wall remains empty and can splat on a later qualifying impact.
6. The attacker receives **Positive Bonus** for **360 unfrozen ticks**: earned Momentum uses **150%**, plus **0.05% passive Momentum per tick**. FD suppresses both gains while used. These values remain editable; FD is still the only meter spend and Negative Penalty remains deferred.

Wall collision is swept across the entire movement step, at every playable height. Hitstop pauses horizontal travel; counter slowdown advances it only on the affected fighter's action ticks. Wall health, residual travel, velocity and splat state all live in deterministic snapshots.

The three arenas use generated full-height solid wall surfaces that extend from each physical contact plane to the outer viewport edge, including the entire space above and below the fighters. The collision overlay exposes purple **WALL** boxes; match presentation shows no wall health meter or numeric health readout. See [stage art and parallax](stage-art.md).

This collision-driven rule replaces the earlier Strive-inspired per-attack wall-damage/decay system. Dedicated travel/splat/fall/wakeup/throw/sweep animations and super-specific knockdowns remain future work.

## Persistence and verification

Schema/core **6** adds nine move properties, 13 recovery/wall rules and three move slots. Schema 1–5 files migrate atomically: existing edits stay, previous pushback is copied to all three displacement settings, old grounded moves keep zero launch, and new slots/rules receive defaults. Save locally / JSON export includes the complete set. The archived WASM adapter migrates its previously supported schema 4 and now 5. Online configuration fingerprints include these rules; editing is locked during a match.

All reaction timers, received-hit counts, per-wall health, remaining knockback, splat timers, break progress, area index and Positive Bonus are integer snapshot state. Core tests cover both throw directions/facings, guard immunity, strike/throw priority, ground/air/block displacement, soft/hard recovery, wakeup reversal, gravity threshold/cap/reset, both walls, missed-splat recovery, break KO ordering and replay. Godot checks actual editor application, migration and live-input wall breaks, plus 1/8/12-frame delayed, jittered rollback through the full transition.

Schema 8 adds post-stun throw grace, landing recovery, damage scaling, repeated-move gravity and grounded wall priming. [Current tuning rules](combat-tuning.md) supersede the earlier schema-6 behavior where noted.

Schema/core **11** adds captured departure coordinates and the three-area directional route to deterministic snapshots. Schema-10 move saves migrate without changing any authored values, including a saved 90-tick break duration. New configurations use 150 ticks. Online peers must use matching builds.

Schema/core **12** stores independent wall health and remaining hit travel. Authored move distances and wall health/timing values remain intact on migration. The old `wallDamage`, `wallRange`, `wallDecayDelay`, `wallDecay`, `wallMidCap` and `groundedWallPrime` configuration slots are retained only for save compatibility; they have no gameplay effect and are absent from the editor. Online peers need matching builds.
