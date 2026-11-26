# Overhead startup warning

Attacks with `hitLevel: 2` and `air: 0` carry a shared amber/orange tell inspired by Strive's
Dust startup. A cream ignition glint appears near the attacker's upper torso,
an open amber flare rises behind their silhouette, and narrow sparks rise in
front. The shared color and upward shape mean **block high**, regardless of guild.

The warning starts on the first displayed startup frame. The glint falls away
over eight action ticks while the open flare remains throughout startup. On a
whiff, a sparse tail lasts at most the first two active ticks; confirmed contact
removes the warning so the actual hit or block effect owns that moment. Recovery,
interruption, a different action, round reset and stage travel leave no tail.
Held charge uses the native extended startup rather than disappearing at the
uncharged frame count.

Classification reads the current combat configuration, not a list of buttons.
Only overheads that start on the ground qualify. The current roster has five:
Hammer's `236S`, Smoke's `5D` and `5[D]`, Tapper's `st.Hs`, and Fillet's
`236S > 6S`. All 27 airborne high attacks stay unmarked. A ground-start overhead
retains the cue if it lifts off during startup; checking the action's `air` flag
rather than the fighter's current height preserves that distinction.
Throws, command captures, pull/dash actions
and non-striking stances are excluded even if their unused guard-level field is
set to high. Guard behavior is unchanged, including jump attacks still needing
high guard against a grounded defender.

`CombatOverhead` uses the saved action age and charge state. It adds no combat
state, emitter history, wall-clock timer or random particles. Pause and hitstop
hold the drawing; rollback can reproduce it from the restored snapshot. Reduced
motion retains a static amber silhouette and sparks without the ignition flash
or rising movement. The torso glint follows body pose geometry; the rear flare
follows the fighter root through grounded hops, facing changes and camera movement.

The generated atlas remains byte-for-byte original. Frame regions and pivots
are metadata. [Art provenance](../art/effects/overhead-v1/source.json) and the
[production brief](../art/effects/overhead-v1/brief.md) describe the source.

[Native review](../exports/FightGuild-Overhead-Warnings-2026-11-26.mp4) covers all
six fighters, Smoke's held charge, mirrored attacks, unmarked jump attacks,
correct and incorrect guards, and an unmarked low sweep. The review displays each simulation
frame twice for visibility; gameplay timings are unchanged.

Validation and reproduction:

```bash
bash scripts/godot.sh --headless --editor --import --quit
bash scripts/godot.sh --headless --audio-driver Dummy --script res://tests/overhead_test.gd -- --test
bash scripts/godot.sh --headless --audio-driver Dummy --script res://tests/overhead_review.gd -- --test --verify
python scripts/capture-overhead-review.py
```

This is native presentation work. The Move Workshop website remains paused.
