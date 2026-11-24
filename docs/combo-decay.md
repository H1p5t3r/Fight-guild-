# Combo decay and velocity knockback — schema 26

This pass replaces the default six-frame knockback budget and blanket same-button command-normal cancels. It follows the behavior documented in the user's saved Dustloop **GGST Damage** and **Mechanics** pages. The November 20 instruction gives Strive-style combo behavior priority over earlier gatling and delayed-gravity requirements.

## Source and scope

- [Dustloop: GGST Damage](https://www.dustloop.com/w/GGST/Damage#Combo_Decay), saved November 15, revision 576973: separate combo decay, usually +5 once per attack use, horizontal/vertical scaling, repeated-attack gravity, and incoming air momentum.
- [Dustloop: GGST Mechanics](https://www.dustloop.com/w/GGST/Mechanics#Gatling_Combination), saved November 15, revision 582457: ground/air gatlings and active-frame P/K restrictions.
- The supplied Queen Dizzy archive lists an extra 20 starter decay for 2H; Smoke's 2Hs now uses that value.

These archives establish the behavior. They do not supply all the numerical physics formulas. The coefficients below are editable Fight Guild tuning, **not a claim of exact Strive parity**. Existing damage proration remains separate. Drive, Fillet's Wound/bleed, Tapper's stance, and the collision-driven wall-health system remain character/project rules.

## Implemented physics

Each successful attack use contributes `comboDecay` once (default 5), even if it has multiple hit groups or a projectile that re-hits after another attack. `starterDecay` adds initial decay only when starting a combo. Blocked attacks do not add decay. Attack identities, repeat counts and pending bounce speeds are serialized in rollback snapshots.

Let `d` be decay before the current attack's cost, including any starter penalty:

- Horizontal multiplier: `min(350, 100 + d × 6)` percent.
- Upward launch and ground-bounce multiplier: `max(25, 100 − d × 2)` percent.
- Air hit velocity adds 20% of the target's incoming horizontal and vertical velocity. Falling momentum can keep a target falling despite an upward move value.
- Downward spikes retain their authored speed, plus the incoming-momentum contribution. Only positive launch speed is reduced.
- Ground hit velocity retains 85% per defender action frame, or 80% if the grounded combo started on a crouching target. Air hit velocity retains 98%.
- Gravity: `min(gravityCap, 100 + max(0, totalDecay − 30) × 2 + repeatGravity)` percent. Normal jumps keep their character's base gravity.
- The third and later uses of a move each add 15 percentage points of repeat gravity. Multi-hit attacks count once. This is independent of the old “first X hits” threshold.

Ground bounces consume their pending bounce on landing. A later move can grant another bounce, but its speed is reduced by decay and the target retains combo/repeat gravity. There is **no invented universal one-bounce cap**.

A wall splat consumes pending ground/wall bounces. If the splat expires, the
defender falls into the existing soft recovery rather than firing an old bounce
on landing. This was fixed in rules revision 5; see the
[native spacing and combo audit](combat-spacing-audit.md), which also corrects
Godot snapshot validation for amplified knockback.

Hitstop freezes travel and gravity. Counter slowdown advances them on the defender's slower clock. Air reel remains untechable until landing; it still qualifies for a wall impact after its numeric stun timer expires. Wall collisions use the incoming velocity before drag and reset horizontal movement, except an authored wall bounce.

## Default gatlings

The chart applies to the ordinary shared route policy; explicit editor masks, follow-up sources and named character routes are exceptions. All routes require contact unless whiff cancel is authored. Self-cancels also require the self-cancel flag.

| Source | Normal/command destinations |
|---|---|
| Ground P | Ground P, command normals |
| Ground K | Dedicated sweep (2S), normal-category D attacks, command normals |
| c.S | S normals, Hs normals, normal-category D attacks, command normals |
| f.S / 2S | Hs normals |
| Hs / command normal | No implicit normal or command route |
| j.P | Itself |
| j.K | Normal-category j.D |
| j.S | j.Hs, normal-category j.D |
| j.Hs | Normal-category j.D |

Fight Guild keeps its dedicated sweep on **2S**. Drive retains its special category rather than becoming Dust. Normal/command moves can special/Drive cancel when enabled; ordinary specials no longer implicitly chain into other specials. Named rekkas and hook follow-ups retain their authored routes. Jump-cancel flags remain per move.

P/K special cancels and K normal cancels must occur within the active frames, including when an author specifies a longer cancel window. Stance, rekka and bleed-specific routes use their authored windows. The old blanket “any attack → same-button command normal” rule no longer overrides these rules.

Fillet's named normal routes now follow the tighter tree, including 5K/2K → 2S. Her explicit sweep/rekka-finisher → Wound routes remain. Tapper's rolling-stance chains remain character exceptions.

## Editor and migration

- **Timing & damage → Combo physics:** per-move decay cost and extra starter decay.
- **Timing & damage → Shared combo physics:** global mode, velocity/launch scaling, drag, carry, decay gravity, repeat-use threshold and gravity cap. Search finds the shared rules.
- **Hitboxes & impact:** grounded and airborne hit speed in px/frame. Block pushback retains its distance control. Legacy distance fields also remain the placement controls for throws.
- The live preview result includes target decay and launch multiplier. Godot exposes the same move values, shared controls and simulation state.

Schema 25 and earlier imports preserve authored moves, named routes, notes and references, and add the new fields. Initial hit speed is `ceil(old distance / 6)` in hundredths of a pixel per frame. Old hit-count gravity values remain saved but are inactive in the default mode. The optional legacy mode exists for archived behavior comparisons.

Use the new current workshop batch to get the updated Fillet route policy and Smoke starter penalty. Existing personal browser drafts migrate without replacing their authored route lists. Every current online peer needs the same core, move data and rule configuration; schema 26 snapshots are incompatible with schema 25.

## Verification

The native physics suite covers multi-hit/projectile identity, signed momentum carry, friction, weakening bounces, repeat gravity without a hit-count gate, combo reset, both walls, hitstop/counter slowdown, explicit cancel exceptions and rollback. The browser suite checks desktop/mobile controls, search, invalid inputs, persistence and plain-JS preview. Migration tests preserve old art metadata and reject invalid configurations atomically.

`node scripts/verify-combo-decay.mjs` replays the exact six previously filmed input traces under both rule modes, including a restored snapshot in each replay. The old six-bounce Smoke route and 12-hit Shark loop no longer connect. Those are identical-input comparisons, not optimized new combos. A separate bounded input search found fresh legal routes; it does not prove maximum damage.

| Identical filmed inputs | Previous damage / hits / bounces | New opening combo damage / hits / bounces |
|---|---|---|
| fillet-midscreen | 255 / 9 / 0 | 93 / 2 / 0 |
| fillet-corner | 283 / 5 / 0 | 93 / 2 / 0 |
| smoke-midscreen | 392 / 8 / 6 | 64 / 1 / 0 |
| smoke-corner | 365 / 7 / 0 | 62 / 1 / 0 |
| shark-midscreen | 375 / 12 / 0 | 66 / 1 / 0 |
| shark-corner | 443 / 12 / 0 | 66 / 1 / 0 |

Fresh bounded searches (8 candidates per depth, up to 6 moves, real inputs with the defender guarding after the starter):

- **fillet-midscreen:** 180 damage / 5 hits — c.S → 6Hs → 236S → 2K → 623Hs.
- **fillet-corner:** 268 damage / 6 hits — c.S → 6Hs → 236S → 2K → 623Hs → 6Hs.
- **smoke-midscreen:** 131 damage / 2 hits — 6[Hs] → 214S.
- **shark-midscreen:** 251 damage / 6 hits — 6S → c.S → 6S → 5K → 6S → j.5Hs.
