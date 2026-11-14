# Combat rules and prototype defaults

## Confirmed direction

PC and PS5 are target platforms; Godot is the current engine. Begin with sprites and move to 3D models on a 2D plane later. The core must support rollback online play. An in-program editor must allow manual move tuning.

Attack buttons are **P, K, S, Hs, D**; their names do not dictate each character's action. There is a dedicated dash macro. Traditional motions are supported; simplified execution uses a modifier plus a per-move direction/button mapping. Each player enables or disables simplified controls in fighter select.

| Source normal button | Unified routes |
| --- | --- |
| P | P, K |
| K | Jump, command normals |
| S | Jump, Hs, command normals |
| Hs | Command normals |

All normals, including command normals, are special cancelable by default, with explicit per-move exceptions. Drive occupies the special-move level of the cancel system, with character-specific incoming and outgoing behavior.

**Every attack can cancel into a command normal on the same button.** This includes specials and Drive attacks. It is an additional route, so P gains same-button command normals without gaining every command normal. The implementation preserves this universal rule even when a move has custom cancel masks.

## Provisional implementation choices

These are useful prototype defaults, not additional approved design requirements:

- Gatlings, special cancels, and jump cancels require hit or block contact. A move may explicitly enable whiff cancels.
- A move cannot cancel into itself unless its self-cancel setting is enabled. Different command normals can form cycles when authored to do so; no hidden once-per-combo restriction has been added.
- Command normals use the unified normal rules for their outgoing routes. The editor can override normal/command route masks, special cancelability, and jump cancelability.
- Jump cancels require a grounded fighter. Air moves are separate definitions. Attack routes still require the target's ground/air condition.
- Walking, a single jump, grounded dash, ground/air blocking, simple pushboxes, hitstop, hitstun, blockstun, health, one 99-count round, and reset are present. Momentum and Faultless Defense are present. There is no throw, dash invulnerability, damage scaling or juggle system yet.
- All starter attacks are mid attacks. The editor can assign low/overhead guard levels for later experiments; no universal overhead or anti-air kit has been selected.
- Simplified execution has no damage penalty, and traditional inputs remain available when enabled. Holding the modifier reserves mapped inputs; unmapped modifier chords do not become ordinary attacks. Up with the modifier is a special input direction, not a jump request.
- Default motions: 236P, 236S, 623Hs. Default command normals: 6P, 6K, 6S, 6Hs, 6D. There are standing and crouching P/K/S/Hs, a grounded Drive starter, and five provisional air attacks.
- All six fighters have 22 playable slots. Anvil is slower and slightly stronger; Hammer advances on specials/Drive. Tapper/Shark have slightly longer reach; Shark/Fillet move faster and their Drive starters advance. Smoke uses the shared baseline with a stationary Drive attack. These are testing values: no shield armor, smoke status, hook pull or bleed mechanic is implied by the art.

## Momentum and defense

Momentum follows the requested Strive-inspired resource direction with FD as its only spending option. Negative Penalty is explicitly deferred. The editor controls chip damage, guard break and provisional meter rates. Block reactions distinguish negative/even and positive attacker advantage; guard break overrides them and removes backward dash buffering and blockstun grab immunity. See [Momentum and defense](momentum-defense.md) for exact implemented behavior and remaining parity/throw work.

## Hit timing and combos

Counter hits interrupt startup/active frames and add per-move hitstun/hitstop bonuses (initially +4/+3). Recovery hits are punishes. Eligible moves starting on the first actionable frame after stun are reversals; the existing button buffer supplies timing leniency. No invulnerability is implied. [Combo and timing rules](combat-feedback.md) specify phase boundaries, eligibility, combo lifetime and provisional defaults.

## Input recognition

This is an original implementation intended for tuning toward the requested feel. It does not copy Strive's source or claim an exact match.

Input is sampled once per simulation frame. Horizontal and vertical opposite directions neutralize independently. Directions are stored relative to facing at sampling time; facing is locked during an attack and updated when not attacking. Buttons trigger on press edges, not on held repeats or negative edge.

Default button buffer: **5 frames**. Default motion window: **20 frames**. Maximum gap between matched motion steps (including the last step to the button press): **8 frames**. These settings are editable. Motions match the required ordered direction subsequence; extra directions may occur between required steps. All three required directions must be present. Priority is 623, other motions, command normals, crouching normals, standing normals; simultaneous attack buttons prefer D, Hs, S, K, P within the same category.

Inputs continue to be recorded during hitstop. Their buffer ages in simulation frames, including hitstop; early inputs can expire before the freeze ends. A held attack does not produce repeated presses. Ground/air eligibility is checked when the buffered command executes. Charge inputs, half circles, double motions, negative edge, kara cancels, and cross-up leniency options are future work.

Strive comparison work should collect repeatable input traces for motion shortcuts, reversal buffers, hitstop buffering, button-release behavior, overlapping commands, and facing changes. Those traces can become regression cases before changing these defaults.

## Frame notation and editor

Startup includes the first active frame: startup 5 means the attack becomes active on its fifth simulation tick. Total duration is `startup - 1 + active + recovery`. Hitstop freezes combat progression; input sampling continues. Stun durations apply to subsequent unfrozen ticks.

Positions use hundredths of a pixel. The editor displays hitbox, pushback, and advance values in pixels and converts them to integers. The hitbox is a rectangle from 12 pixels in front of the fighter to its authored reach, with a bottom offset and height. A single hit per move instance is supported.

Move-data changes reset the local simulation. Save locally persists the complete set in Godot's user data directory; JSON export/import is portable. Invalid imports leave the prior set unchanged. Schema-1/2/3 saves migrate old edits, supply new defensive/meter/timing defaults and add any missing fighters. Restore defaults changes the working set; saving afterward replaces the saved set. Online peers require matching data and lock editing during play.
