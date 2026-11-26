# Rhythm combo trials

Open **Combo Trials** from the main menu, or **Combo trials** in native Training / Combat Lab. The first set contains ten routes across all six fighters. This is a playable Godot feature; the browser Move Workshop remains unchanged and unpublished.

The fight appears beside five scrolling **P / K / S / Hs / D** lanes. Press when a note reaches the white line. A long trail means hold the button until its end cap reaches that line. The separate direction track shows scrolling arrows and held-direction trails, including Anvil's charge-back. Rapid motions fan their arrows across the direction lane so they stay readable, while each arrow retains its original timing at the line.

**DIR uses screen directions**: a left arrow means left on your stick/keyboard. Route labels use normal facing-relative numpad notation. Switching to **Face left** mirrors the stage setup, input replay and direction arrows, while `236S` still names the same move. The live arrow at the receptor follows your actual stick/keyboard input; its small hollow circle means neutral.

## Practice

- **Watch / F2** plays real recorded inputs through the current combat simulation. **Try / Retry / F3** resets the setup and gives a four-count lead-in.
- Your Player 1 keyboard/controller bindings apply. Default attacks are **J / K / L / I / O**. **Start** retries from a result, or pauses/resumes during a trial. Keyboard/controller navigation can select the other controls between attempts or while paused.
- **F4** pauses/resumes; **Esc** returns to the previous screen. Focus loss and P1 controller disconnection pause the attempt. Held input must be released before resuming or starting again.
- **100%, 75%, 50% speed** slow the fight and chart together, preserving simulation-frame spacing. The count-in and input guidance are visual, with no metronome clicks. Combat sounds, fighter music and reduced camera motion settings are respected.
- Button presses show **On time**, **Early** or **Late** in 60 Hz input frames. Notes more than ten frames away from a press are marked missed/extra for coaching. This is not a new gameplay input window.
- Begin motion inputs ahead of the button note. Direction markers show the demo's example; they do not require one-frame precision. The game's normal motion buffer accepts earlier/slower motions when they remain within its input window.
- A clear requires the expected moves and contacts in order, with the live combo counter remaining unbroken. Matching note timing with a wrong motion does not pass. Legal earlier/later buffered inputs can still clear, even with a different timing grade.
- The defender crouch-guards after the opening hit. Gaps that permit blocking, an overhead after a counter reset, wrong moves and incomplete routes fail. Damage is measured from the setup's remaining health; Tapper's stance-entry damage is excluded.
- Full-speed clears are saved locally per route and side, scoped to this combat configuration. Slower clears are labeled **Practice clear**; demos never record a clear.

Trials use the shipped fighter kits, not unsaved/saved custom tuning. Opening them preserves the original match, training recording and custom move configuration. If the shipped kit or collision fingerprint changes, the catalog asks for re-verification instead of teaching stale timing.

## Initial catalog

These are verified learning routes, not a claim of maximum possible damage.

| Fighter | Trial | Hits | Damage |
| --- | --- | ---: | ---: |
| Fillet | Midscreen route | 7 | 191 |
| Fillet | Corner break | 7 | 278 |
| Smoke | Charged Drive confirm | 4 | 221 |
| Smoke | Poison Sword finish | 4 | 204 |
| Shark | Shoulder snap links | 3 | 159 |
| Tapper | Front stance confirm | 3 | 215 |
| Tapper | Dempsey stance route | 6 | 265 |
| Hammer | Drive dash extension | 4 | 279 |
| Hammer | Corner break | 5 | 394 |
| Anvil | Charge confirm | 2 | 153 |

The previous showcase's grounded Shark hook extension and Anvil super route with 50% starting Momentum are excluded because they no longer work under the current rules. Shark instead teaches the valid opening links. No combat rules were altered to certify these trials.

## Implementation and verification

`godot/data/combo_trials.json` contains run-length-encoded ordinary inputs, setup-only placement, expected move starts, actual contacts, route labels and the native configuration fingerprint. Tapper's stance is earned by a recorded setup prelude. Once the attempt begins, there are no position/stun/damage edits or forced attacks.

`ComboTrialSession` owns the independent `CombatModel` and validation. Its clock advances on **every input tick**, including hitstop and super freeze, so buffering remains visible. `ComboTrialHighway` draws the chart; `ComboTrialsWindow` handles menus, bindings, sound, speed and local progress. This separation keeps presentation out of combat/rollback state.

Re-certify the selected source recordings, then verify:

```sh
bash scripts/godot.sh --headless --script res://tests/build_combo_trials.gd -- --test
bash scripts/godot.sh --headless --script res://tests/combo_trials_test.gd -- --test
python scripts/capture-combo-trials.py --quick
python scripts/capture-combo-trials.py
```

The tests replay every trial on both sides, including charged moves and stance preludes; reject empty/wrong-direction/early-release/dropped attempts; accept a legal late trace; exercise live keyboard events; check slow/pause/focus behavior; and verify that the original match and tuning survive closing trials. Existing native menu/input smoke checks also pass. Physical controller and display-latency calibration remains a hardware playtest.

Review: [native rhythm-trial video](../exports/FightGuild-Combo-Trials-2026-11-26.mp4).

Follow-ups: shorter beginner drills, per-step practice loops, authored/user-recorded trial import and latency calibration. The broader recording-slot/defensive-dummy training expansion remains deferred per the user's priority change.
