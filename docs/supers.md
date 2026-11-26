# Supers — native roster

Every fighter has two grounded supers. Each costs **two Momentum segments**
(6667 of 10000 units, rounded up) when it starts, even on block or whiff. Activation
uses the saved **54-tick screen-rip freeze** and displays the move's name. Supers
do not earn activation or contact meter for their owner.

Watch the [native super showcase](../exports/FightGuild-Supers-2026-11-25.mp4).
The [full animation production pass](super-animation-production.md) begins with
[Sky Foundry](../exports/FightGuild-Sky-Foundry-2026-11-25.mp4) and
[Iron Dominion](../exports/FightGuild-Iron-Dominion-2026-11-25.mp4), followed by
[Freemason](../exports/FightGuild-Freemason-2026-11-25.mp4) and
[Grand Design](../exports/FightGuild-Grand-Design-2026-11-25.mp4), then
[Flashpoint](../exports/FightGuild-Flashpoint-2026-11-25.mp4) and
[The Air Is Mine](../exports/FightGuild-The-Air-Is-Mine-2026-11-26.mp4), followed by
[Last Orders](../exports/FightGuild-Last-Orders-2026-11-26.mp4).
These are provisional balance values, captured from the current native build.
Normal combo proration still applies; the video starts each demonstration fresh.
Exsanguinate's demonstration begins with 150 stored grey life.

| Fighter | Super / input | Purpose and limitation |
| --- | --- | --- |
| Anvil | **Sky Foundry — 63214Hs** | Invincible airborne-only command grab, 333 base damage; retains the approved lift/slam. It cannot grab a grounded opponent. |
| Anvil | **Iron Dominion — 63214S** | Advancing shield strike, 280 damage; one upper-body armor hit and +14 on first-active block. Lows and throws bypass the armor. |
| Hammer | **Freemason — 236236S** | 360-damage hammer finisher with strong corner carry. Committed and punishable on block. |
| Hammer | **Grand Design — 214214Hs** | Delayed moving stone wave, 120 base damage. A launch creates a follow-up opportunity; Hammer recovers while the wave remains. Does not refresh Drive. |
| Smoke | **Flashpoint — 236236S** | Invincible close flame backhand, 300 damage and hard knockdown. Short reach and punishable block recovery. |
| Smoke | **The Air Is Mine — 214214Hs** | Stationary gas field with three blockable 50-damage pulses. Hold back/neutral/forward during the cast for near/middle/far placement. Clears if Smoke is hit. |
| Tapper | **Last Orders — 236236S** | Regular-stance invincible uppercut/headbutt, 340 damage. A confirmed hit enters Dempsey stance; unsafe on block. |
| Tapper | **Whiskey Chaser — 214214Hs** | Dempsey-only hook barrage, 260 cinematic damage. Three block pulses, plus pressure and a stance finish; no invulnerability. |
| Shark | **No Safe Harbour — 236236S** | Long horizontal hook, reel and carry, 310 damage. Narrow vertical coverage lets opponents jump over its lane. |
| Shark | **Undertow — 214214Hs** | Invincible close hook sweep, 220 damage. Switches sides and restores spear spacing after confirmation. |
| Fillet | **Bloodletting — 236236S** | Advancing crosscut, 250 damage. Applies/refreshes her owned bleed and ends in hard knockdown. |
| Fillet | **Exsanguinate — 214214Hs** | Close knife finisher, 300 scaled base damage plus up to 150 stored grey life. Consumes that bleed once. |

## Confirmation and control

Ten supers become paired cinematic sequences on an unblocked confirmation. Both
players are locked until the finish; strikes, projectiles, Drive and buffered
cancels cannot interrupt the sequence. Outstanding projectiles clear on capture.
Damage resolves once at the finish, preserving the combo's scaling. The timer and
status clocks pause during the cinematic; KO presentation waits for its finish.
Ordinary throws retain their existing timeout rules.

**The Air Is Mine** and **Grand Design** are the exceptions: they create normal
blockable projectile contacts, and the caster can move or attack after recovering
from the cast. Their purpose requires follow-ups. Neither cast can be canceled.
All other supers also have no outgoing cancels, including on block or whiff.

Ordinary eligible attacks can cancel into a super on contact. Invulnerability and
armor apply only where explicitly authored; spending meter does not make every
super invulnerable. Two simultaneous cinematic strikes clash symmetrically. An
unblocked cinematic strike wins over a simultaneous ordinary strike before capture.

## Motion-only controls and compatibility

The simple-input modifier, per-move shortcuts, character-select toggles and native
editor fields have been removed. Older move JSON still imports, but its shortcut
fields do nothing. Older control presets release the modifier's key/trigger for
remapping. Reserved input/configuration positions remain in the file format so
Faultless Defense and existing authored fields do not shift.

The two double-quarter-circle motions have a ten-tick longer total recognition
window than the ordinary motion window, with the same per-direction gap limit.
Anvil retains half-circle-back inputs. Online protocol 5 and rules revision 8
reject older gameplay builds; both peers need the same native build and move data.
Old binary snapshots are incompatible with the added cinematic state.

## Art and reproduction

All twelve supers use original generated art. Sky Foundry, Iron Dominion, Freemason and Flashpoint
now each have 16-key replacements. The Air Is Mine has twelve caster keys and six independently looping cloud keys. Grand Design has eight caster keys and an
independent six-key stone wave. All five have dedicated faces, separate effects
and original sound passes. Fixed source scale, held anticipation and a first-active snap
follow the established animation process. The largest authored pose change is
at the final-startup/first-active boundary. Saved capture clocks drive impact
holds and recovery; no procedural smear or warped inbetweens are added.
Utility clouds and stone waves use generated effect sheets. Anvil's shield arcs
retain the magma-orange accent.

[Sources, prompts and hashes](../art/characters/supers-v1/sources.json) and the
[timing plan](../art/characters/supers-v1/timing-plan.json) record provenance.
Pixel data remains unchanged; registration uses atlas regions, pivots and
body-only collision metadata, with no more than four hurtboxes per pose.
Other face cut-ins use the existing portrait fallback described in the
[presentation guide](super-freeze-presentation.md).

The authoring batch is `godot/data/workshop/2026-11-25-supers/FightGuild-Supers.json`.
The browser Move Workshop has not been rebuilt or published. Native reproduction:

```bash
python scripts/author-supers.py
python scripts/register-super-art.py
python scripts/generate-combat-data.py --native-only
bash scripts/build-godot.sh
bash scripts/test-godot.sh
python scripts/capture-super-showcase.py
```

The core suite covers inputs in both facings/player slots, meter, freeze,
block/whiff, cinematic ownership, simultaneous attacks, outstanding projectiles,
utility recovery, status payouts, scaling and replay. Native tests restore every
captured tick, verify imported data and confirm presentation never mutates combat.
Windows debug/release DLLs are cross-compiled and included with source downloads;
Windows hardware playtesting remains separate.
