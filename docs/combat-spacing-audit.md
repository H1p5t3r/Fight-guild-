# Native spacing and combo audit — 24 November 2026

The audit found and fixed two engine defects: a pending bounce could relaunch a
fighter after an expired wall splat, and Godot could reject a valid rollback
snapshot containing amplified knockback. Attack timings, damage, hitboxes,
hurtboxes and the latest Workshop batch are unchanged.

## Source and scope

The fixture is exported through `CombatModel.load_file()` and
`FightCore.configuration()` from the current **Collar Fold · longer grab holds**
batch, `godot/data/workshop/2026-11-24-collar-fold/FightGuild-Collar-Fold.json`.
Its SHA-256 is `a1ac5672ee04227fb478ae0b4bce8a9b092883642fd2f9c2a0e4cda72d3ba6b2`.
This uses the actual imported configuration, including Fillet's extended policy,
custom hurtboxes and active hitbox timelines.

The contact sweep runs **134,784 scenarios**: 156 enabled actions against all six
receivers, four starting postures, three body gaps, three stage positions, both
facings and both player assignments. Starting postures are standing, crouching,
rising from 90 px at 6.5 px/tick, and falling from 90 px at 2 px/tick. Body gaps
are 0, 60 and 140 px; positions are midscreen, attacker at the wall, and defender
at the wall. Each scenario advances the real core for 220 ticks.

These are geometry/physics fixtures: the initial action uses `preview_begin`.
They do not claim every follow-up can be entered from neutral, every attack must
hit every posture, or that a target starting airborne stays airborne until
contact. Captures and Fillet's explicitly authored spiral pass-through are
excluded from the body-overlap assertion. Separate combo tests use real inputs.

## Results

| Check | Result |
|---|---|
| Contact sweep | 0 unintended body overlaps; 0 differences in hit count, damage, bounce count or splat outcome across facings/player assignments |
| Basic enabled ground normals at point blank | Every sampled standing receiver can be hit; high attacks can still miss crouching receivers |
| Shark 2Hs | Both hits connect on every grounded receiver at point blank |
| `2K → 2S`, real inputs | 864/864 continuous two-hit hard-knockdown routes |
| `c.S → f.S → 5Hs`, real inputs | 840/864 continuous three-hit routes; 24 documented spacing breaks below |
| Ordinary guard versus FD | 3,168 comparisons: FD creates at least as much distance, prevents chip, consumes meter, preserves blockstun, and neither guard damages a wall |
| Combo endings | 504 checks: all receiver bodies, both walls/player slots, splat expiry, ordinary wall bounce, wall break, neutral reset and replay |
| Amplified velocity snapshots in Godot | 1,120 successful restores with identical resimulation, including 100 px/tick hit velocity and 180 px/tick wall bounces at legal authoring limits |

Both basic routes are tested against standing and crouching starters, every
matchup, both facings/player slots and all three stage positions. After the first
hit the defender holds down-back, so a reset or blocked follow-up cannot pass as
a continuous combo. Inputs cancel at the first opportunity after hitstop.

**Known spacing limitation:** Anvil's provisional `5Hs` is too short to finish
`c.S → f.S → 5Hs` against Tapper away from the defender's corner, or against
Fillet when the starter hit her standing. These 24 mirrored cases lose the third
hit. They remain explicitly tracked for Anvil's dedicated kit/art pass. Increasing
his reach here would also require matching weapon artwork. This is a sampled
route result, not a claim that the matchup has no other combo.

## Fixes

**Wall catches consume pending bounces.** Smoke's `c.S` can queue a ground bounce
on an airborne hit. Previously, if the defender then splatted on an empty wall,
that bounce survived the entire splat and fired on the subsequent landing. A
successful wall splat now clears both pending ground and wall bounces. Letting the
splat expire produces its existing soft recovery. Ordinary wall bounces against a
wall with health still work; a fresh later attack can author a new bounce.

**Snapshot validation accepts combat velocities.** Godot's restore validator
still used the 40 px/tick voluntary-movement limit for knockback and the unscaled
30 px/tick authoring limit for pending wall bounces. Valid combo decay can exceed
both. The validator now accepts the core's bounded reaction range: normal hit
velocity remains capped at 100 px/tick, and a 30 px/tick wall bounce multiplied by
the maximum configurable 600% reaches 180 px/tick. This changes validation, not
the velocity formulas or authored move values.

The snapshot layout and move-save schema remain **27**. The combat rules revision
is **5**, so peers must use the matching updated core. Both Windows DLL variants
and `exports/FightGuild-Windows-Core.zip` have been rebuilt.

Existing native suites also cover diminishing repeat launches, decay counted
once per attack use, projectile identities, signed air momentum, counter
slowdown, wall-health damage and rollback. The Godot recovery suite exercises
delayed/jittered rollback through wall travel. The local ENet smoke test checks
two peers through frame 180; its clean-loopback run did not induce rollbacks.

## Reproduce

Build the native extension with `bash scripts/build-godot.sh`, then run:

```sh
bash scripts/audit-native-combat.sh
bash scripts/audit-native-combat.sh --full
bash scripts/godot.sh --headless --script res://tests/combo_snapshot_test.gd
```

The full audit writes individual outcomes to
`build/combat-spacing-audit/contacts.csv`. The quick audit runs the input-route
and FD checks. `tests/combo_endings_test.cpp` is included in the normal native
test script. The move-editor website remains frozen; this workflow does not
build or publish it.
