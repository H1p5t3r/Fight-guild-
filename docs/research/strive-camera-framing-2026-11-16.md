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

The original starting matchup occupied about **31%** of the full match window. The current fullscreen Fillet/Shark neutral view measures about **60.6% / 60.4%** (roughly 491px / 489px in a 1440 × 810 window). Their foot line is **92.5%** of the arena height, near the reference's approximately 93%. Local/online versus no longer reserve an application header or outside margins. Practice/editor layouts still reserve space for their tools and scale the scene within their arena.

`ArenaStage.camera` targets a canonical 150-world-unit body at 60% of arena height, then limits zoom by horizontal separation and vertical headroom below the HUD. Body geometry, attack reach, movement speed and collision dimensions are unchanged. Sprites, weapons, collision boxes, walls and the painted floor share the world projection. Scenic image pixels have a fixed world size, with a new y=810 floor baseline; the old independently clamped scenery zoom and overscan-driven pan were removed. Architecture and sky retain horizontal parallax.

The camera opens for one airborne fighter above a grounded opponent. When both fighters are airborne, it follows their shared height so the empty ground need not remain visible. These are Fight Guild framing choices, not a reverse-engineered Strive camera algorithm. Essential tracking applies in reduced-motion mode; counter accents and wall-break flight remain optional. Framing is derived from simulation state, so replay, pause and rollback reproduce it without stale easing state.

Visual review covers starting neutral, single and simultaneous jumps, opposing walls, corner pressure, collision overlays, a rekka, both wall-break routes and destination stages, reduced motion and development. Regression tests in `tests/camera_test.gd` check floor landmarks against combat coordinates across zoom and pan; `tests/stage_test.gd` checks departure and landing continuity.
