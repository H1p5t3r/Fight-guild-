# Training frame lab

Training and Development now offer **Record**, **Stop**, **Replay** and **Frame lab** beside the starting Momentum selector.

Record captures both players for up to 1,800 simulation ticks (30 seconds), starting with a snapshot of position, health, resources and buffered inputs. Recordings last for the current session. Choose **Player 2 controls** in the dummy menu to author the dummy's actions with the second keyboard/controller controls. Existing dummy behaviors can also be recorded.

**Replay** restores the starting snapshot and reproduces both input streams, then compares the final combat checksum. **Replay P2 dummy**, inside Frame lab, restores the same starting state while leaving P1 under live control. Changed move data invalidates a recording rather than silently applying it to different rules. Reset stops capture/playback but retains the recording.

**Frame lab** pauses the simulation and shows the last 180 ticks for both players. Hover over a tick to inspect move phase, numpad/button input, stun, spacing, contact advantage, cancel windows, input age, last-hit damage scaling and gravity. White markers indicate contacts, dim cells indicate hitstop, and a gap readout measures actionable ticks between guard contacts. **+1 tick** advances the paused simulation; **Resume** closes the inspector and resumes play. Merely closing the inspector leaves the game paused.

This tool extends the existing input history, collision display, pause and frame-step controls. It is confined to offline practice; recordings never change online inputs or simulation state.

Counter slowdown is shown as **½ SPEED** with remaining ticks. Yellow diagonal marks identify held defender ticks on the timeline; shared hitstop remains separate. This distinguishes real defender-only slowdown from extra stun or a longer shared freeze.
