# Combo showcase · November 20, 2026

This video records the pre-decay build. Its long bounce/gatling loops are superseded by [schema 26 combo rules and replay comparisons](combo-decay.md).

[Watch or download the MP4](../exports/FightGuild-Combo-Showcase.mp4).
[Input traces and frame checksums](../exports/FightGuild-Combo-Routes.json).
These are replay traces for the recording harness, not a Move Workshop import.

Six high-damage routes in a 2:13 video, shown at full speed and then half
speed. The video uses the native Godot stage, HUD, animations and effects. Inputs
highlight when entered; the header tracks actual damage and combo hits. Brackets
mean hold the button: `6[Hs]` and `5[D]` are charged attacks.

| Time | Fighter | Position | Target | Damage | Hits | Route |
| --- | --- | --- | --- | ---: | ---: | --- |
| 0:00 | Fillet | Midscreen | Shark | 255 | 9 | c.S → 5Hs → 6Hs → 236S → 5P → 5K → 6Hs → 236S → 6S |
| 0:19 | Fillet | Corner | Shark | 283 | 5 | c.S → 5Hs → 6Hs → 623Hs → 6Hs |
| 0:38 | Smoke | Midscreen | Fillet | 392 | 8 | 2Hs → 6[Hs] × 6 → 214Hs |
| 1:02 | Smoke | Corner | Fillet | 365 | 7 | 5[D] → 214Hs → 6Hs → 5[D] → 214Hs → 6Hs → 214S |
| 1:26 | Shark | Midscreen | Smoke | 375 | 12 | 6S → 5Hs → 6S → 5Hs → 6S → 5Hs → 6S → 5Hs → 6S → f.S → 5Hs → 6Hs |
| 1:47 | Shark | Corner | Smoke | 443 | 12 | 6S → 6Hs → 6S → 6Hs → 6S → 6Hs → 6S → 5Hs → 6S → 5Hs → 6S → 6S |

All starters are **normal hits**, with zero starting Momentum, fresh walls and
1,000 HP targets. Fillet's and Shark's corner totals include the **50-damage wall
break**. The defender holds down-back after the first hit; blocked follow-ups,
combo resets and routes continuing after a wall break are rejected.

Fillet's midscreen clip continues into **5D / Wound** after the final rekka
knockdown. That segment is labeled **OTG bleed reset**. It adds bleed, with **no
extra combo damage or hit**. The bleed is earned through the actual setup.

These are the highest-damage routes found in a bounded search, not a proof of
absolute maximum damage. The search used a 32-state beam, sampled delays of
0/3/7/12/18 unfrozen ticks, and up to 9 actions for Fillet midscreen and Smoke,
12 for Fillet corner and Shark. The charged Smoke and repeated Shark launch
routes are shown as they currently work; they provide useful balance references.
Different target geometry, starter conditions, run momentum or unsampled timing
can produce other routes. No gameplay values or art were changed for this video.
The recording exposed and fixed a wall-texture tiling freeze during Smoke's
corner juggle; the stage regression test now covers that exact camera position.

## Reproduce

Build the current native extension and WASM core using the normal repository
setup. To search again:

```sh
COMBO_BEAM=32 COMBO_DEPTH=9 node scripts/search-combo-showcase.mjs
COMBO_BEAM=32 COMBO_DEPTH=12 node scripts/search-combo-showcase.mjs fillet-corner shark-midscreen shark-corner
node scripts/prepare-combo-showcase.mjs
```

To render the preserved routes without searching again, run from a graphical
desktop or a virtual display with Godot and FFmpeg available:

```sh
bash scripts/render-combo-showcase.sh "$PWD/exports/FightGuild-Combo-Routes.json"
```

The recording harness checks the workshop file's SHA-256 and every native frame
against the searched core's checksum. Raw inputs, conditions, route timing and
expected damage/hits are retained in the JSON. The slow replays duplicate the
captured frames exactly; no pose interpolation or artificial in-between frames
are introduced. The MP4 contains six chapter markers.
