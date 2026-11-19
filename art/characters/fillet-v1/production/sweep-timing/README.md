# Fillet 2S — timing and impact

The 2026-11-19 review found that the evenly spaced, independently generated
in-betweens produced shape jitter and made the cut feel soft. This pass selects
seven approved body drawings from the original single 2S atlas and changes their
exposure. It preserves the approved Hip Reap motion and generated knife arc.
There is no new painted artwork, interpolation, crossfade or extra gameplay time.

| Action frames | Pose / purpose |
|---|---|
| 1–5 | Low entry, held |
| 6–10 | Loaded preparation, held |
| 11 | One-frame release |
| 12–14 | Strong cut silhouette; first damaging frame is 12 |
| 15–19 | Finish and commitment; frame 15 is the last damaging frame |
| 20–25 | Withdraw the arm |
| 26–32 | Return to guard |
| 33–38 | Settle in the exact entry drawing; recovery is still locked |

The body stays identical across the first three active frames. Separate weapon
cues change the arc at 14 and 15, fade it at 16 and 18, and remove it at 20. There
are 11 total presentation cues, but only seven unique body images. All use the
same body scale. The rear sole is registered at −35 world pixels within 0.125 px
rounding tolerance, and entry/final-settle use identical regions and pivots.

**The move remains 12f startup / 4f active / 23f recovery.** Startup is the first
active-frame convention: frames 1–11 prepare, 12–15 hit, 16–38 recover; the next
neutral tick is 39. On a normal hit, the simulation adds its existing nine
hitstop ticks: 38 action ticks occupy 47 simulation ticks. No extra freeze is
invented for the review. Hitboxes, anatomical hurtboxes, root motion, damage,
cancels and block advantage remain unchanged. Phase-relative keys follow edits
to the move timings, and snapshot replay restores the same exposure.

`timing.json` is the exposure/registration override consumed by
`scripts/register-fillet-ground.py`. `baseline.json` preserves the immediately
preceding 22-key version, including its knife effects, for a fair comparison.
The underlying generated PNG bytes are unchanged. The previous in-between art
remains archived in `ground-twos`; it is no longer part of the live 2S clip.

The browser player `fillet-motion-review.html` starts on 2S at 1×, with Whiff /
On hit, slow playback, frame stepping, facing flip and a hitbox overlay. Its pose,
root, defender and freeze samples all come from the compiled combat simulation.
The self-contained version is `build/Fillet-Attack-Timing.html`.

Run `node scripts/capture-fillet-motion-review.mjs` after a Workshop build to
capture the current player. Outputs are in `build/fillet-sweep-timing-review/`.
The delivered [video](previews/Fillet-Sweep-Timing.mp4) shows three whiff cycles and
three contact cycles at game speed, then one of each at half speed. The GIFs
show [whiff](previews/Fillet-Sweep-whiff.gif) and [contact](previews/Fillet-Sweep-hit.gif)
at half speed for inspection (the MP4/player show exact 60 Hz game speed). Labeled replay pauses are outside the move's duration.
