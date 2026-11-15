# Combo, counter-hit, punish and reversal timing

These systems use the same deterministic 60 Hz combat state as attacks and blocking. They do not add a Momentum spend or enable Negative Penalty. The initial counter-hit bonuses are provisional tuning, not verified GGST parity.

## Contact classification

The engine classifies the defender after both players have acted for the tick, before either hit is applied. This makes simultaneous trades symmetric and recognizes a defender who has already canceled recovery into a new attack.

| Result | Condition on the contact tick | Effect |
| --- | --- | --- |
| Normal hit | Defender is idle, moving or already in hitstun | Authored damage, hitstun and hitstop |
| Counter hit | Defender's attack is in startup or active frames | Normal damage; add this attacking move's counter-hit hitstun and hitstop |
| Punish | Defender's attack is in recovery | Normal damage, hitstun and hitstop; punish feedback |
| Block | Correct guard while able to block | Existing blockstun, chip, FD and guard-break rules |

An interrupted attack is in recovery when its current tick is at least `startup + active`. Its last recovery tick is still punishable; the following actionable tick is not recovery. A follow-up against an already stunned defender is a normal combo hit, not another counter hit. Blocking never applies counter-hit bonuses. Startup/active trades can produce a counter hit for each player.

Per move, `counterHitstun` defaults to **4** extra unfrozen ticks (range 0–60), and `counterHitstop` defaults to **3** extra ticks of shared hitstop (range 0–30). Setting both to zero keeps classification/feedback without affecting timing. The combined maxima are 240 hitstun and 60 hitstop; snapshots validate those extended ranges. No damage bonus, slowdown, forced launch or special counter-only cancel route is implied.

`event` records the most recent contact: 0 none, 1 normal hit, 2 block, 3 counter hit, 4 punish. Counter/punish notices have their own 60-tick clocks, so ordinary combo follow-ups do not erase the opening callout.

## Reversal execution

A reversal is an eligible move **starting on the first actionable tick after hitstun or blockstun**, including guard break. Eligibility defaults to specials and Drive; `reversalEligible` can opt any move in or out. A correctly timed reversal is recognized even when it whiffs, is blocked or is immediately interrupted. Timing does not grant invulnerability.

The existing button buffer supplies leniency: by default the current press and the previous four input samples are considered. An eligible move buffered four ticks before execution can start as a reversal; five ticks before execution is too early. The button-buffer editor adjusts this window. Traditional motions and enabled simplified inputs use the same execution test. Motion windows and facing rules remain unchanged.

After one actionable tick passes, a later move is not a reversal. Choosing guard, FD, jump or dash uses that opportunity. Completing one's own attack recovery or performing a gatling does not create it. Inputs still age during hitstop, so a very early input can expire before stun ends. Reversal feedback records the actual input age and lasts 60 unfrozen ticks.

This prototype has no knockdown/wakeup or invulnerable reversal move yet. A future wakeup state should open the same first-actionable opportunity when it completes, and move invulnerability needs separate design.

## Combo state

A chain continues only if the defender was still in hitstun at the beginning of the contact tick. The final locked tick counts; a gap that gives the defender an actionable tick starts a new chain. A block breaks the chain. Getting hit clears the attacker's prior combo display, including during trades.

The live `combo` count is separate from `comboDisplay`: the latter appears from the second connected hit onward, holds while the chain is active and remains for 60 unfrozen ticks afterward. Starting a new one-hit sequence clears the previous display immediately. `comboAge` tracks time since the latest hit for presentation. All feedback clocks freeze during hitstop, pause and round end, and reset with the round.

## Display and practice

From two hits onward, a large slanted, outlined number sits in the stage background on the attacker's current side. It follows side switches rather than a fixed player slot; player colors remain consistent. It briefly expands on each hit and fades through its final 18 ticks after the combo ends. Fighters and the main HUD render over it. Counter and punish callouts share that side. Reversal feedback is independent, so a reversal can also score a counter hit without losing either notification.

The move editor exposes **Counter +stun**, **Counter +stop** and **Eligible for reversal timing**. All values are saved/exported and locked online. The existing **Buttons** buffer adjusts reversal input leniency.

Select the **Attack loop** dummy to practice interrupting startup or catching Hs recovery. **Guard → reversal** holds down-back, then enters a traditional 236P during the last three blockstun ticks outside hitstop. It is a training aid, not an invulnerable response; pressure can interrupt it. Timing, hitstop and notice clocks can all be inspected with Pause / +1 frame.

The display bundles the unchanged DejaVu Sans Condensed Bold Oblique font with its license to keep numeral shapes consistent across PC platforms. Notices use the shared Barlow Condensed headline stamp, brass/teal player colors, chamfered plates and diagonal accents from the [match HUD](menu-style.md#match-hud). Counter/punish and reversal lines have separate vertical slots so simultaneous notices remain readable.

## Persistence and verification

Schema/core version **4** adds the three per-move timing fields and snapshot feedback state. Schema-1/2/3 JSON imports preserve prior move, Momentum, FD and guard-break settings, then add default timing fields; reversal eligibility follows the saved move category. Fingerprints prevent mixed builds/data from playing together. Native network protocol **4** adds synchronized match presentation and per-Scrum generations; input bits remain unchanged.

Regression tests cover startup/active/recovery edges, trade symmetry, recovery cancels, zero/max bonuses, counter-hit follow-ups, blocked contacts, both players' reversal timing, traditional/simple execution, expired buffers/hitstop, late inputs, opt-in normals, interruption of a timed reversal, combo continuity and deterministic restoration. Native, Godot and WebAssembly traces must still agree frame by frame.
