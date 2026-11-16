# Combo, counter-hit, punish and reversal timing

These systems use the same deterministic 60 Hz combat state as attacks and blocking. They do not add a Momentum spend or enable Negative Penalty. Counter tiers, vulnerability masks and bonuses are editable; see [current combat tuning](combat-tuning.md). They do not claim verified GGST parity.

## Contact classification

The engine classifies the defender after both players have acted for the tick, before either hit is applied. This makes simultaneous trades symmetric and recognizes a defender who has already canceled recovery into a new attack.

| Result | Condition on the contact tick | Effect |
| --- | --- | --- |
| Normal hit | Defender is idle, moving, already in hitstun or in a non-counterable startup/active phase | Combo-scaled damage; authored hitstun and hitstop |
| Counter hit | Defender's current attack phase is counter-vulnerable | Normal damage; apply the attacking move's counter freeze, victim slowdown and optional extra stun |
| Punish | Defender is in non-counterable attack recovery or landing recovery | Normal damage, hitstun and hitstop; punish feedback |
| Block | Correct guard while able to block | Existing blockstun, chip, FD and guard-break rules |

An interrupted attack is in recovery when its current tick is at least `startup + active`. Its last recovery tick is still punishable; the following actionable tick is not recovery. A follow-up against an already stunned defender is a normal combo hit, not another counter hit. Blocking never applies counter-hit bonuses. Startup/active trades can produce a counter hit for each player.

Medium and large defaults use the saved Dustloop [counter-slowdown table](https://www.dustloop.com/w/GGST/Mechanics#Counter_Hit_Slowdown): **21 shared freeze ticks + 25 defender slowdown ticks**, and **31 + 35**, respectively. After the shared freeze, the defender advances on alternate ticks, beginning with a held tick. That gives 13/18 held ticks while the attacker resumes at normal speed. Defender stun, attack age, movement, gravity, hook reel and recovery timers follow that clock. The match and input-sampling clocks remain at 60 Hz. Follow-up hits preserve the remaining slowdown; their shared hitstop pauses its countdown. Small counters retain the existing Fight Guild +4 stun / +3 shared stop; this is not a complete copy of Strive's counter or input-register behavior.

`counterFreezeFrames` is −1 for legacy additive `hitstop + counterHitstop`, or 0–60 for an explicit total freeze. `counterSlowFrames` ranges from 0–120. Optional `counterHitstun` remains 0–60 and `counterHitstop` 0–30; medium/large defaults now use zero additive bonuses to avoid counting the same advantage twice. A tier classifies presentation; direct timing edits remain authoritative. Setting freeze to −1, slow and both bonuses to zero keeps feedback with ordinary hit timing. Counter slowdown does not grant extra damage, invulnerability, forced launch or a special cancel route.

`event` records the most recent contact: 0 none, 1 normal hit, 2 block, 3 counter hit, 4 punish. Counter/punish notices have their own 60-tick clocks, so ordinary combo follow-ups do not erase the opening callout.

## Reversal execution

A reversal is an eligible move **starting on the first actionable tick after hitstun or blockstun**, including guard break. Eligibility defaults to specials and Drive; `reversalEligible` can opt any move in or out. A correctly timed reversal is recognized even when it whiffs, is blocked or is immediately interrupted. Timing does not grant invulnerability.

The existing button buffer supplies leniency: by default the current press and the previous four input samples are considered. An eligible move buffered four ticks before execution can start as a reversal; five ticks before execution is too early. The button-buffer editor adjusts this window. Traditional motions and enabled simplified inputs use the same execution test. Motion windows and facing rules remain unchanged.

After one actionable tick passes, a later move is not a reversal. Choosing guard, FD, jump or dash uses that opportunity. Completing one's own attack recovery or performing a gatling does not create it. Inputs still age during hitstop, so a very early input can expire before stun ends. Reversal feedback records the actual input age and lasts 60 unfrozen ticks.

Automatic knockdown/wakeup opens the same first-actionable reversal opportunity. Invulnerable reversal moves still need separate design.

## Combo state

A chain continues if the defender began the contact tick in hitstun, air reel, hook reel or wall splat. The final locked tick counts; a gap that gives the defender an actionable tick starts a new chain. A block breaks the chain. Getting hit clears the attacker's prior combo display, including during trades.

The live `combo` count is separate from `comboDisplay`: the latter appears from the second connected hit onward, holds while the chain is active and remains for 60 unfrozen ticks afterward. Starting a new one-hit sequence clears the previous display immediately. `comboAge` tracks time since the latest hit for presentation. Combo and side-notice clocks freeze during shared hitstop and round end. Counter cinematics advance through the impact freeze in simulation ticks so the word and camera can settle; pausing freezes both. Every clock resets with the round.

## Display and practice

From two hits onward, a slanted, outlined number sits in the stage background on the attacker's current side. Its center is raised to 47% of arena height. It starts at about one third of its maximum size at two hits, grows with each hit, and reaches its cap at **10 hits**; later counts keep that height. The cap adapts to the arena, up to 250 logical font pixels. The brief hit pulse tapers as the counter approaches ten so it never reaches full size early. The HITS caption and underline follow the numeral's position and size. Long counts fit horizontally without shrinking their height.

The counter follows side switches rather than a fixed player slot; player colors remain consistent. It fades through its final 18 ticks after the combo ends. Fighters and the main HUD render over it. Small counter and punish callouts share that side. Medium/large counters display an oversized outlined gold COUNTER across the stage; large counters also push the stage camera in by up to 10%. The HUD remains fixed. Reduced motion removes the camera push and temporary text pulse while retaining the count-based size progression and gameplay slowdown. Reversal feedback is independent, so a reversal can also score a counter hit without losing either notification.

The move editor exposes **Counter +stun**, **Counter +stop**, **Counter freeze**, **Counter slowdown** and **Eligible for reversal timing**. All values are saved/exported and locked online. The existing **Buttons** buffer adjusts reversal input leniency.

Select the **Attack loop** dummy to practice interrupting startup or catching Hs recovery. **Guard → reversal** holds down-back, then enters a traditional 236P during the last three blockstun ticks outside hitstop. It is a training aid, not an invulnerable response; pressure can interrupt it. Timing, hitstop and notice clocks can all be inspected with Pause / +1 frame.

The display bundles the unchanged DejaVu Sans Condensed Bold Oblique font with its license to keep numeral shapes consistent across PC platforms. Combat notices, Scrum/fight calls, wall events and character names use the same condensed italic family, with cream/gold contours, a red offset outline and split diagonal accents. Large counter letters use a 24% fill and background combo numerals a 12% fill, leaving the stage visible through the word. Entry/wall calls use a more legible 42% fill; small timing notices retain 70% opacity. Character names stay solid inside the health bars for readability. This is an original Strive-inspired treatment using the bundled licensed font. Guild-colored health bars, three-section Momentum and the menu styling remain in place. Counter/punish and reversal lines have separate vertical slots so simultaneous notices remain readable.

## Persistence and verification

Schema/core version **4** originally added the three per-move timing fields and snapshot feedback state. Schema-1/2/3 JSON imports preserve prior move, Momentum, FD and guard-break settings, then add default timing fields; reversal eligibility follows the saved move category. Fingerprints prevent mixed builds/data from playing together. Native network protocol **4** adds synchronized match presentation and per-Scrum generations; input bits remain unchanged.

Regression tests cover startup/active/recovery edges, trade symmetry, recovery cancels, zero/max bonuses, counter-hit follow-ups, blocked contacts, both players' reversal timing, traditional/simple execution, expired buffers/hitstop, late inputs, opt-in normals, interruption of a timed reversal, combo continuity and deterministic restoration. Native, Godot and WebAssembly traces must still agree frame by frame.

Schema/core **10** appends two move fields and integer slowdown/cinematic snapshot state. Schema 1–9 imports keep existing authored counter bonuses, disable new slowdown and use legacy additive freeze until edited or restored to defaults. Counter tests cover alternate-tick clocks, airborne gravity, follow-up hitstop, trade symmetry, old-save migration, reduced-motion presentation and odd-phase snapshot replay.
