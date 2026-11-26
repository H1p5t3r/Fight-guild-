# Bleeding and tethered presentation

Bleeding has a persistent crimson wound mark and falling droplets on the
affected fighter. Its small pulse follows the native bleed clock. The HUD shows
the droplet emblem, `BLEED` and the stored grey life available for cash-out.
Droplets fade at the stage floor during knockdown instead of passing beneath it.

Tethering has a thicker braided teal/ivory line and a clear hook seal. Attached
lines sag slightly; active pulls tighten the line and send chevrons toward the
owner, while the HUD changes from `TETHERED` to `REELING`. The consumed attachment
can have a zero source field during the pull, so the effect also reads the saved
`linePullTime` and stays visible until that displacement ends.

The cord sits behind fighters, with target marks above their sprites and below
hit effects, collision diagnostics and the HUD. Torso placement uses unmasked
body pose geometry, so disabling upper hurtboxes for invulnerability does not
move the mark onto the legs. Native sprite positions supply the final root,
including air movement, camera zoom and paired presentation.

`CombatStatusEffects.describe()` derives all visuals from the current snapshot;
there are no emitters or wall-clock timers to accumulate stale particles.
Repainting is inert, pause/hitstop hold the same drawing, and rollback restores
the correct status. Cash-out, expiry, range breaks, interruptions and reset clear
effects immediately. Reduced motion retains the information with static marks,
drops and directional chevrons. Concurrent statuses do not hide one another.

This changes native presentation only. Damage, bleed accumulation, tether
duration, pull actionability and combat data are unchanged. The browser Move
Workshop is still paused.

[Watch the native review](../exports/FightGuild-Bleed-and-Tether-2026-11-26.mp4):
bleed through crouching/jumping and cash-out, a grounded wound through get-up,
tether expiry, a mirrored actionable pull, and both statuses in the same matchup.

Reproduction:

```bash
bash scripts/godot.sh --headless --editor --import --quit
bash scripts/godot.sh --headless --audio-driver Dummy --script res://tests/status_effects_test.gd -- --test
bash scripts/godot.sh --headless --audio-driver Dummy --script res://tests/status_effects_review.gd -- --test --verify
bash scripts/godot.sh --headless --audio-driver Dummy --script res://tests/impacts_test.gd -- --test
python scripts/capture-status-effects.py
```

Generated artwork and provenance: [production brief](../art/effects/status-v1/brief.md),
[prompt](../art/effects/status-v1/production-prompt.txt),
[source](../art/effects/status-v1/source.json).
