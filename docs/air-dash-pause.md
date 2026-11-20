# Air-dash pause and burst

Every enabled air dash and air backdash now stops existing horizontal, vertical and stored movement velocity, holds the fighter in place, then starts its configured movement. The pause defaults to **4 frames** (about 67 ms at 60 Hz) for all six fighters.

The selected character has two editable values in **Movement & defense → Jumps & air movement**:

- **Air forward pause** (`airDashPauseFrames`): 1–30 frames before a forward air dash.
- **Air backward pause** (`airBackdashPauseFrames`): 1–30 frames before an air backdash.

The same values are available in Godot's movement editor. Burst duration starts after the pause; increasing the pause does not shorten the burst. Run/step/hover air styles apply their configured horizontal speed after the hold. Air teleports relocate on the first frame after the hold and use the remaining burst duration as recovery. **Ground teleport startup** continues to control ground teleports.

The accepted dash keeps its original direction, forward/backward profile and air-action cost if the opponent crosses sides during the pause. Attacks and jumps use the usual input buffer through the hold; an attack accepted afterward inherits the new burst's velocity according to its inertia setting. Pre-dash momentum is never restored. Hitstop freezes the hold, a hit or block interrupts it, and rollback restores the exact remaining pause. Disabled or exhausted air dashes do not stop momentum. Ground runs and dashes retain their existing behavior.

Schema/core **22** adds the two movement fields and the rollback state. Earlier move JSON imports gain the default pauses while preserving existing movement, attacks and workshop art briefs. Current exports preserve customized pauses. Both online peers must use the updated build.
