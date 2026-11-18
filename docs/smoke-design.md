# Smoke — poison, smoke and ignition normals

Current additions: [approved backhand specials, shared Smoked Obsidian pillar,
eight-key 2Hs and attack entries](smoke-attacks.md). That page identifies the
latest user-authored batch; the source-table notes below describe the initial
normal kit.

The new kit uses the user's saved **Queen Dizzy** normal tables and diagrams.
**Leo's diagrams correct Tapper's attack hitboxes only.** Tapper's frame data,
custom collar Drive, throws and rolling stance remain intact. Fillet and Shark's
uploaded edits are preserved in the new [workshop draft](../godot/data/workshop/2026-11-18-smoke/FightGuild-Smoke-Tapper.json).

## Smoke's normal kit

All values below are startup / active / recovery, in 60 Hz action frames.
Startup includes the first active frame. Damage is the source's **unscaled raw
damage**, before Fight Guild's existing combo scaling. Air advantage depends
on contact height and landing; the source IAD examples are not universal values.

| Input | Visual | Frames | Raw damage | Ground block advantage |
|---|---|---|---|---|
| 5P | Vapor Check: high lime palm puff | 6 / 3 / 10 | 25 | −3 |
| 5K | Caustic Kick: long boot check | 7 / 4 / 12 | 26 | −4 |
| c.S | Chimney Coil: close upward gray curl | 8 / 6 / 12 | 43 | −1 |
| f.S | Fivefold Fume: long poison ribbon | 12 / 2,2,2,2,2 / 19 | 10 × 5 | −7, final hit |
| 5Hs | Flashover: three ignition pulses | 12 / 6,6,6 / 15 | 20 × 3 | −4, final hit |
| 2P | Low Pressure: crouching mid palm | 5 / 3 / 8 | 20 | −1 |
| 2K | Ankle Leak: low boot | 6 / 4 / 11 | 23 | −3 |
| 2S | Soot Ribbon: crouching **mid** cloud | 10 / 6 / 15 | 40 | −7 |
| 2Hs | Backdraft: tall anti-air fire column | 18 / 9 / 28 | 64 | −18 |
| 2D | Floor Spill: low poison sweep | 12 / 6 / 27 | 38 | −16 |
| 6P | Updraft: protected smoke palm | 12 / 6 / 20 | 28 | −12 |
| 6Hs | Smoke Hammer: descending **mid** cloud | 19 / 8 / 20 | 57 | −9 |
| 6[Hs] | Flashpoint Hammer: ignited guard crush | 36 / 8 / 20 | 77 | +12 |
| 5D | Fire Veil: overhead ignition | 20 / 3 / 26 | 50 | −15 |
| 5[D] | Rising Ignition: charged overhead launch | 28 / 3 / 26 | 62 | −10 |
| j.P | Short diagonal lime palm | 6 / 4 / 9 | 18 | varies |
| j.K | Down-forward caustic boot | 7 / 4 / 12 | 23 | varies |
| j.S | Long horizontal vapor lance | 13 / 4 / 23 | 38 | varies |
| j.Hs | Downward cinder/smoke scythe | 12 / 4 / 15 | 53 | varies |
| j.D | Separate drifting ember projectile | 16 / emission / 20 | 36 | varies |

The c.S/f.S selector uses editable proximity. Hold Hs during 6Hs or hold D
during 5D to reach the charged follow-up; release early for the base attack.
The two charged slots are independently editable. Disabling a charged slot
falls back to the uncharged strike. Charging cannot deal damage before release
and remains vulnerable to counter hits. It does not award a second meter gain.

f.S and 5Hs use separate hit groups. Their timeline keys can be edited normally;
turn **Multi-hit** off to let the changing boxes score only one hit. Flashover's
last hit uses 89 frames of choking stun to reproduce the source's +69 timing.
That is a local stun adaptation, not the full Strive Frozen State subsystem.
The palette does not silently introduce poison damage over time.

j.D emits at frame 16, with one emission tick plus 19 subsequent recovery ticks
in this engine (35 total actor ticks, matching 16−1+20 in the source). Its
independent projectile has one hit and one clash durability. It stalls air
motion briefly, then recoils. Speed, lifetime, recoil and the otherwise
unspecified attack level remain provisional and editable. The source's Roman
Cancel interaction is outside this project's current meter-spending scope.

Fight Guild's unified gatlings, startup floors (2f grabs / 3f P normals / 5f others), body-only vulnerability,
four-hurtbox cap and universal hard-knockdown 2D remain authoritative. 6P exposes
legs only on frames 1–17, then restores the body; this approximates the source's
two low-profile stages. The kit does not add a universal homing jump. Damage
scaling, hitstop, spatial movement, knockback and launch physics continue to use
Fight Guild's systems where the saved table supplies no compatible numeric value.
Unsupported extra 6K/6S/6D normals are disabled. Existing specials remain as
earlier provisional moves, outside this normals pass.

## Hitbox evidence and remaining uncertainty

- [Queen Dizzy source](../references/frame-data/queen-dizzy-2026-11-18/source.json)
  and [traces](../references/frame-data/queen-dizzy-2026-11-18/traces.json):
  22 diagrams covering the full supplied normals, including repeated diagrams
  shared by charged variants. The anticipation-only 6P diagram has no red attack.
- [Leo source](../references/frame-data/leo-whitefang-2026-11-18/source.json)
  and [traces](../references/frame-data/leo-whitefang-2026-11-18/traces.json):
  corrections to Tapper 5P, 5K, c.S, 2P, 2K, 2S, 2Hs, 6K, 6Hs, j.P, j.K,
  both j.S hits, j.Hs and the held-guard attack. Leo 5D is retained as reference
  but does not overwrite Tapper's custom Drive.
- Leo f.S, both 5Hs images, 6P, 2D and j.D were not embedded, so those Tapper
  attack boxes retain their earlier provisional shapes. Held-guard diagrams
  are also absent. No unseen diagram was traced.

Each trace retains source pixel rectangles, source hash, estimated root and
conversion scale. Yellow push rectangles provide crop calibration; their local
normalization widths (42px for Smoke, 45px for Tapper) are **not** replacements
for either character's live gameplay pushbox. Their existing push profiles stay
unchanged. The screenshots do not contain exact numeric engine coordinates.
The unlabeled 2Hs/6Hs geometry stages use estimated active-frame boundaries;
the source's total active time and j.S's explicit hit/gap timing are preserved.

## Art and editing

Smoke adds **40 windup/active drawings**, one per phase of each listed normal,
plus a separate generated ember sprite. The tall launcher has a dedicated
atlas; its earlier study is retained in the paired sheet. Original generated
PNGs stay unchanged. Gutters, pivots and body fits are metadata, with at most
four anatomical hurtboxes per pose. Hair, hood, cloth, vials and gas/fire never
extend hurtboxes. No transition smear frames are added.

Lime gas handles checks and long thin pressure, dense slate smoke handles broad
coverage, and orange/ivory ignition marks heavier attacks. All share Smoke's
olive/ivory costume and mature, slim proportions. Art briefs are included in
the move JSON. Full impact/recovery animations and final silhouette cleanup
remain future work; the current drawings are iteration poses.

Open the rebuilt **FightGuild-Move-Workshop.html** for this kit. Existing browser
saves are not overwritten; if an older local draft opens, download a backup and
import the linked Smoke/Tapper JSON to load the new kit. Select Smoke
or Tapper and turn on hitboxes/hurtboxes to review the traced geometry. Charge
follow-up slots can be previewed in isolation; live tap/hold timing is exercised
by the native/core tests. JSON schema 19 appends two charged slots; importing
schema 18 or older preserves old attacks and keeps the added slots disabled.

Rebuild the authoring data with `scripts/build-reference-hitboxes.py`, then
`scripts/build-smoke-data.py`; register artwork with `scripts/register-smoke-art.py`
and regenerate the compiled data with `scripts/generate-combat-data.py`.
