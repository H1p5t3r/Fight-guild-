# Startup rules · 18 November 2026

| Attack | Minimum startup | Default timing change |
|---|---:|---|
| Standard ground/air throw (throw category, no motion) | 2f | All 14 authored throws now use 2f |
| Command grab (throw category with a motion) | 2f | None |
| Fillet's bleed cash-out grab variant | 2f | None |
| P normal, including command/air/stance normals | 3f | None; edit individual moves to 3f or 4f |
| Other attacks, including P specials and blockable Drive grabs | 5f | None |
| Shark's tether pull variant | 5f | None |

Startup is the first active tick: 2f means one windup tick, then contact may occur on tick 2. Existing throw range, damage, knockdown, recovery, stance transitions, tech/clash behavior, post-stun protection and same-frame strike/throw priority are unchanged.

Schema/core version 20 keeps the existing fields. Imports from older schemas upgrade standard throw startup to 2 while preserving every other authored field, enabled flag, note and pose reference. Subsequent version-20 edits—including a deliberately slower standard throw—round-trip unchanged. Both online peers must run the same core and move data.

The latest workshop batch is `godot/data/workshop/2026-11-18-startup/FightGuild-Startup.json`, derived from the preceding Smoke/Tapper batch. Source batches remain intact. Compiled defaults are generated from `godot/data/starter_moves.json`.
