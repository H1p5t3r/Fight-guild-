# Combat rules and prototype defaults

## Confirmed direction

PC and PS5 are target platforms; Godot is the current engine. Begin with sprites and move to 3D models on a 2D plane later. The core must support rollback online play. An in-program editor must allow manual move tuning.

Attack buttons are **P, K, S, Hs, D**; their names do not dictate each character's action. There is a dedicated dash macro. Specials and supers use traditional motions. Simplified execution, its modifier and fighter-select toggles have been removed; legacy shortcut data is ignored.

The current shared gatlings follow Strive's tighter P/K/S/Hs families. Ground P chains into P and command normals; K chains into the dedicated 2S sweep and command normals; c.S opens S/Hs/command routes; f.S and 2S lead to Hs. Hs and command normals have no implicit normal cancel. Air routes have their own tree. Drive remains a special-category action.

The former universal same-button command-normal exception is removed. Named character routes and explicit masks remain editable exceptions. P/K special cancels and K gatlings close after the active frames. [Combo decay and gatlings](combo-decay.md) gives the complete chart, migration behavior and verification.

**Weapons do not extend hurtboxes. Startup floors are 2f for throws, 3f for P normals, and 5f for other attacks.** Each pose uses at most **four hurtboxes**: legs, torso and arms together, head, and one optional extension for an extended limb or complex pose. Separate pushboxes maintain body spacing. See [collision rules](collision-rules.md).

## Provisional implementation choices

These are useful prototype defaults, not additional approved design requirements:

- Gatlings, special cancels, and jump cancels require hit or block contact. A move may explicitly enable whiff cancels.
- A move cannot cancel into itself unless its self-cancel setting is enabled. Different command normals can form cycles when authored to do so; no hidden once-per-combo restriction has been added.
- Command normals have no implicit normal/command routes under current rules. The editor can override normal/command route masks, special cancelability, and jump cancelability.
- Jump cancels require a grounded fighter. Air moves are separate definitions. Attack routes still require the target's ground/air condition.
- Walking, a single jump, grounded runs/step dashes, ground/air blocking, per-fighter pushboxes, hitstop, hitstun, blockstun, health, first-to-two Scrums with a 99-count timer, and reset are present. Momentum and Faultless Defense are present. Launch, automatic soft/hard recovery, throws, combo gravity and walls are present. Damage scaling, cancel windows, prejump, landing recovery, block carryover and post-stun throw protection are present. Dash invulnerability remains deferred. See [current combat tuning](combat-tuning.md).
- Fillet’s rekka finisher and the universal 2S sweep are low attacks; other starter strikes are mids. The editor can assign low/overhead guard levels for later experiments; no universal overhead or anti-air kit has been selected.
- Simplified execution has no damage penalty, and traditional inputs remain available when enabled. Holding the modifier reserves mapped inputs; unmapped modifier chords do not become ordinary attacks. Up with the modifier is a special input direction, not a jump request.
- Default motions: 236P, 236S, 623Hs. Default command normals: 6P, 6K, 6S, 6Hs, 6D. There are standing and crouching P/K/S/Hs, a grounded Drive starter, and five provisional air attacks.
- All six fighters have 25 base slots plus reserved signature slots; Fillet/Shark are the first focused matchup. Anvil is slower and slightly stronger; Hammer advances on specials/Drive. Reach follows each button’s current sprite; Shark/Fillet move faster and their Drive starters advance. Smoke has a stationary Drive attack. See [all preliminary stats](move-stats.md). These are testing values: shield armor, smoke status and bleed remain unimplemented. Fillet’s knife spiral/rekka and Shark’s hook pull/stab have dedicated art and behavior; see [signature moves and movement](signature-moves.md).

## Momentum and defense

Momentum follows the requested Strive-inspired resource direction with FD and two supers per fighter as its spending options. Supers cost two segments; [inputs and rules](supers.md). Negative Penalty is explicitly deferred. The editor controls chip damage, guard break and provisional meter rates. Block reactions distinguish negative/even and positive attacker advantage; guard break overrides them and removes backward dash buffering and blockstun grab immunity. See [Momentum and defense](momentum-defense.md) for exact implemented behavior and remaining parity work.

## Hit timing and combos

Counter hits use the interrupted move’s vulnerability mask (normally startup/active); recovery is normally punishable. Per-move counter tiers and editable hitstun/hitstop bonuses distinguish light and heavy attacks. Eligible moves starting on the first actionable frame after stun are reversals; the existing button buffer supplies timing leniency. No invulnerability is implied. [Combo and timing rules](combat-feedback.md) specify phase boundaries, eligibility, combo lifetime and provisional defaults.

## Input recognition

This is an original implementation intended for tuning toward the requested feel. It does not copy Strive's source or claim an exact match.

Input is sampled once per simulation frame. Horizontal and vertical opposite directions neutralize independently. Directions are stored relative to facing at sampling time; facing is locked during an attack and updated when not attacking. Buttons trigger on press edges, not on held repeats or negative edge.

Default button buffer: **5 frames**. Default motion window: **20 frames**. Maximum gap between matched motion steps (including the last step to the button press): **8 frames**. These settings are editable. Motions match the required ordered direction subsequence; extra directions may occur between required steps. All three required directions must be present. Eligible contextual follow-ups take priority, then 623, other motions, command normals, crouching normals, standing normals; simultaneous attack buttons prefer D, Hs, S, K, P within the same category.

Inputs continue to be recorded during hitstop. Their buffer ages in simulation frames, including hitstop; early inputs can expire before the freeze ends. A held attack does not produce repeated presses. Ground/air eligibility is checked when the buffered command executes. Charge inputs, half circles, double motions, negative edge, kara cancels, and cross-up leniency options are future work.

Strive comparison work should collect repeatable input traces for motion shortcuts, reversal buffers, hitstop buffering, button-release behavior, overlapping commands, and facing changes. Those traces can become regression cases before changing these defaults.

## Frame notation and editor

Startup includes the first active frame: startup 5 means the attack becomes active on its fifth simulation tick. Total duration is `startup - 1 + active + recovery`. Hitstop freezes combat progression; input sampling continues. Stun durations apply to subsequent unfrozen ticks.

Positions use hundredths of a pixel. The editor displays hitbox, pushback, and advance values in pixels and converts them to integers. Ordinary hitboxes are rectangles between authored back/front offsets, with a bottom offset and height. Hook hitboxes are eight narrow rectangles along a moving diagonal weapon; the rope does not hit. Defaults follow the current active artwork; weapons never add hurt area. Active-frame hitbox keys can author shape changes and optional separate hits.

Move-data changes reset the local simulation. Save locally persists the complete set in Godot's user data directory; JSON export/import is portable. Invalid imports leave the prior set unchanged. Schema-1/2/3/4/5 saves migrate old edits, retain their previous 12px hitbox origin, supply new defensive/meter/timing defaults and add any missing fighters. Schema 6 also adds recovery/wall settings and the three universal move slots while retaining previous pushback values. Schema 7 adds signature slots, contextual follow-ups, motion carry and per-character movement profiles while preserving schema 1–6 tuning. Schema 8 adds cancel windows, damage scaling, landing recovery, counter profiles and defensive/wall tuning. Schema 9 adds editable prejump and empty-jump landing recovery while preserving old jump behavior; [migration details](combat-tuning.md#persistence-and-verification) distinguish preserved saves from the new default balance. Imports below the conditional startup floors are rejected. Restore defaults changes the working set; saving afterward replaces the saved set. Online peers require matching data and lock editing during play.

## Recovery and walls

Move definitions use facing-relative numpad notation. **2S** is the universal low hard-knockdown sweep with punishable uncancelled block recovery; **4P+K / 6P+K** are back/forward hard-knockdown throws. Other knockdowns normally auto-tech in place. [Recovery and walls](recovery-and-walls.md) defines the editable ground/air/block displacement, launch, knockdown timings, combo decay and repeated-attack gravity and Strive-style splat/break/Positive Bonus sequence.

Standing S chooses **c.S** inside the fighter’s editable root-distance threshold and **f.S** beyond it. A second S after c.S contact gatlings into f.S even at close range. Existing 2D/Drive behavior is retained. See [Slash and sweep tuning](move-batches/2026-11-19-slash-sweeps.md) for all six thresholds, sweep block disadvantage and data compatibility.
