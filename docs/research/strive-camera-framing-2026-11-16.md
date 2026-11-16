# Strive framing reference

Source: the **1280 × 720 Ky Kiske / Sol Badguy gameplay screenshot supplied by the user in this conversation on 2026-11-16**. This is a measurement of that image, not a claim about a universal Strive camera constant or the current game patch. The screenshot's version is unidentified. Pose, character, spacing and camera state can change the ratio.

Measure from the top of the character's hair to the grounded boot sole and divide by the **whole image height**, including HUD. Exclude weapons, shadows and effects. Approximate visual bounds, with several pixels of uncertainty:

| Character | Top / bottom y | Visible height | Share of 720px frame |
| --- | --- | --- | --- |
| Ky | 240 / 668 | 428px | 59.4% |
| Sol | 237 / 666 | 429px | 59.6% |

The useful target is therefore **about 60% of screen height in standing neutral**, with the two foot positions roughly one third and two thirds across the screen. We do not derive motion, camera limits or gameplay dimensions from this single still.

Live Steam access was blocked by this environment's network policy. The previously supplied Dustloop Mechanics archive contains a cropped guard illustration, which is unsuitable for measuring a full gameplay viewport. The user's full-frame image is the source used for this change; no live website verification is claimed.

## Fight Guild implementation

Before this change, the starting Fillet/Shark matchup occupied about **31%** of the full match window height. It now occupies approximately **59%**, about **1.9×** the previous standing height. With the subsequent compact health-bar layout, their rendered silhouettes are about 481px / 480px tall at the default 1280 × 720 logical viewport / 1440 × 810 window. The 1248 × 642 logical arena is smaller than the viewport because of the surrounding application header and margins.

`ArenaStage.camera` targets a canonical 150-world-pixel body at 66% of arena height, then limits zoom by horizontal separation and available vertical headroom below the HUD. Standing silhouettes differ slightly from that canonical height. Body geometry, attack reach, movement speed and arena collision dimensions remain the existing authored values; presentation applies the same camera projection to sprites, weapons, hit/hurt/push boxes and wall planes.

The camera opens up for large separation and high airborne positions. This is a Fight Guild framing choice to keep both players visible, not a reverse-engineered Strive camera algorithm. Essential tracking also applies in reduced-motion mode. Counter accents and wall-break flight remain optional motion. All camera framing is derived from the current simulation state, so a replay, pause or rollback restores the same view.

Visual review covers starting neutral, a real jump, opposing walls, corner pressure, collision overlays, a rekka, both wall-break routes, their destination stages, reduced motion and the development layout. Regression coverage is in `godot/tests/camera_test.gd` and `godot/tests/stage_test.gd`.
