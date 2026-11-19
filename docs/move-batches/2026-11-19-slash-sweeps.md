# Close/far Slash and universal 2S · 19 November 2026

The uploaded `FightGuild-moves-2026-11-19.json` is archived byte-for-byte in
`godot/data/workshop/2026-11-19-user/`. It matches the previous Shark batch's
JSON content. The current workshop preset adds only the requested standing
Slash pair and low 2S sweeps. Other moves, movement, global rules, existing
brief text and all seven pose references are retained. Existing c.S tuning
for Smoke, Tapper and Shark is unchanged.

## Standing Slash

Press S without a directional normal or motion: at or inside the threshold it
selects **c.S**; outside it selects **f.S**. Distance is horizontal root-to-root
spacing, checked when the move executes, including buffered inputs. The rule
works in either facing and through simplified controls. A disabled c.S falls
back to f.S.

| Fighter | Close threshold | c.S startup |
|---|---:|---:|
| Anvil | 95 px | 8f |
| Hammer | 85 px | 7f |
| Smoke | 110 px | 8f |
| Tapper | 95 px | 7f |
| Shark | 85 px | 7f |
| Fillet | 80 px | 6f |

With unified routes, **c.S → f.S** and **c.S → 2S** are now available on hit or
block, alongside the usual Hs, command, special and jump routes. A second
standing S during c.S selects f.S even at close range. This does not allow
f.S → c.S or an automatic c.S self-chain. Contact permissions, cancel windows,
enabled moves, ground/air and stance restrictions still apply. An explicit
custom normal-route mask remains authoritative; the S checkbox includes Slash
normal destinations.

Both editors display f.S while its saved ID remains `5S` (slot 2); c.S remains
slot 32. This retains older art notes, imports and sequence references. No
schema change is needed. The peer compatibility signature includes the new
combat rules, so older executables cannot connect with different gatlings
even if they load identical move data. In the browser editor, select either Slash and use
the paired edit/test buttons in Timing & damage or Inputs & cancels. Edit
**Close-distance range** on f.S to change the threshold. The spacing tests use
real S inputs and leave move data untouched. Sequence tests also resolve the
actual input and warn if spacing selects a different move.

## Dedicated low sweep

Every fighter's grounded **2S** is enabled and hits low, causes hard knockdown
with 36f down time, and has no jump, self or whiff cancel. Wakeup timing remains
authored. Block pushback is 6 px. Launch, guard break, bounce and crumple are
off for this move. Active hitbox keys preserve their timing and horizontal
reach, use one hit group, and cover the bottom 35 px. Existing artwork is
reused; the art briefs request dedicated leg-sweeping poses for the next pass.
Down-back and down-forward S also select the sweep, taking priority over 6S.
Contextual rekka follow-ups keep their existing priority.

| Fighter | Startup / active / recovery | Damage | Block, first active | Block, last active |
|---|---:|---:|---:|---:|
| Anvil | 14 / 4 / 25 | 62 | −12 | −9 |
| Hammer | 12 / 4 / 25 | 56 | −12 | −9 |
| Smoke | 10 / 6 / 20 | 40 | −12 | −7 |
| Tapper | 10 / 3 / 23 | 52 | −12 | −10 |
| Shark | 11 / 2 / 24 | 32 | −12 | −11 |
| Fillet | 10 / 4 / 25 | 50 | −12 | −9 |

These are provisional punish windows for **uncancelled** recovery. A punish
still needs to reach the crouching defender. Special cancels and the normal
gatling rules remain available, as previously requested. Existing 2D/Drive
behaviors and throws are unchanged.

## Delivery and verification

`scripts/build-slash-sweep-data.py` reproduces this preset from the archived
upload and updates starter data. `scripts/generate-combat-data.py` produces
the compiled move table and move-stat reference.

Fresh editor sessions load this batch. Existing browser drafts stay intact:
export any newer edits, then import the hosted `FightGuild-moves.json` to adopt
this preset. In Godot Development, use **Load latest workshop batch**.

Regression coverage checks all six fighters and both facings, exact proximity
boundaries, disabled targets, simplified and buffered inputs, cancel windows,
snapshot replay, real queued c.S → f.S attacks, low guard behavior, hard
knockdown, first/last-active block advantage and a close-range low-kick punish.
Browser checks cover paired controls, fractional thresholds, mobile widths,
the shared sequence preview and JSON roundtrip with unchanged art briefs.
