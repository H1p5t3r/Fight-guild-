# Combo, counter-hit, punish and reversal timing

These systems use the same deterministic 60 Hz combat state as attacks and blocking. They do not add a Momentum spend or enable Negative Penalty. Counter tiers, vulnerability masks and bonuses are editable; see [current combat tuning](combat-tuning.md). They do not claim verified GGST parity.

The most recent attacker draws in the foreground on hit or block, including throws and projectiles. [Foreground order](foreground-order.md) follows rollback state in both the game and editor preview.

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

The existing button buffer supplies leniency: by default the current press and the previous four input samples are considered. An eligible move buffered four ticks before execution can start as a reversal; five ticks before execution is too early. The button-buffer editor adjusts this window. Motion inputs use this execution test. Simple inputs have been removed; see [supers](supers.md) for double-quarter-circle recognition.

After one actionable tick passes, a later move is not a reversal. Choosing guard, FD, jump or dash uses that opportunity. Completing one's own attack recovery or performing a gatling does not create it. Inputs still age during hitstop, so a very early input can expire before stun ends. Reversal feedback records the actual input age and lasts 60 unfrozen ticks.

Automatic knockdown/wakeup opens the same first-actionable reversal opportunity. Invulnerable reversal moves still need separate design.

## Combo state

A chain continues if the defender began the contact tick in hitstun, air reel, hook reel or wall splat. The final locked tick counts; a gap that gives the defender an actionable tick starts a new chain. A block breaks the chain. Getting hit clears the attacker's prior combo display, including during trades.

The live `combo` count is separate from `comboDisplay`: the latter appears from the second connected hit onward, holds while the chain is active and remains for 60 unfrozen ticks afterward. Starting a new one-hit sequence clears the previous display immediately. `comboAge` tracks time since the latest hit for presentation. Combo and side-notice clocks freeze during shared hitstop and round end. Counter cinematics advance through the impact freeze in simulation ticks so the word and camera can settle; pausing freezes both. Every clock resets with the round.

## Display and practice

From two hits onward, a slanted, outlined number sits in the stage background on the attacker's current side. Its center is raised to 43% of arena height. It starts at about one third of its maximum size at two hits, grows with each hit, and reaches its cap at **10 hits**; later counts keep that height. The cap adapts to the arena, up to 250 logical font pixels. The brief hit pulse tapers as the counter approaches ten so it never reaches full size early. The HITS caption and underline follow the numeral's position and size. Long counts fit horizontally without shrinking their height.

The counter follows side switches rather than a fixed player slot; player colors remain consistent. It fades through its final 18 ticks after the combo ends. Fighters and the main HUD render over it. Small counter and punish callouts share that side. Medium/large counters display an oversized outlined gold COUNTER across the stage; large counters also push the stage camera in by up to 10%. The HUD remains fixed. Reduced motion removes the camera push and temporary text pulse while retaining the count-based size progression and gameplay slowdown. Reversal feedback is independent, so a reversal can also score a counter hit without losing either notification.

The move editor exposes **Counter +stun**, **Counter +stop**, **Counter freeze**, **Counter slowdown** and **Eligible for reversal timing**. All values are saved/exported and locked online. The existing **Buttons** buffer adjusts reversal input leniency.

Select the **Attack loop** dummy to practice interrupting startup or catching Hs recovery. **Guard → reversal** holds down-back, then enters a traditional 236P during the last three blockstun ticks outside hitstop. It is a training aid, not an invulnerable response; pressure can interrupt it. Timing, hitstop and notice clocks can all be inspected with Pause / +1 frame.

The display bundles the unchanged DejaVu Sans Condensed Bold Oblique font with its license to keep numeral shapes consistent across PC platforms. Combat notices, Scrum/fight calls, wall events and character names use the same condensed italic family, with cream/gold contours, a red offset outline and split diagonal accents. Large counter letters use a 24% fill and background combo numerals an 8% fill with a stronger dark outer contour, leaving the stage visible through the word. Entry/wall calls use a more legible 42% fill; small timing notices retain 70% opacity. Character names stay solid inside the health bars for readability. This is an original Strive-inspired treatment using the bundled licensed font. Guild-colored health bars, three-section Momentum and the menu styling remain in place. Counter/punish and reversal lines have separate vertical slots so simultaneous notices remain readable.

## Persistence and verification

Schema/core version **4** originally added the three per-move timing fields and snapshot feedback state. Schema-1/2/3 JSON imports preserve prior move, Momentum, FD and guard-break settings, then add default timing fields; reversal eligibility follows the saved move category. Fingerprints prevent mixed builds/data from playing together. Native network protocol **4** adds synchronized match presentation and per-Scrum generations; input bits remain unchanged.

Regression tests cover startup/active/recovery edges, trade symmetry, recovery cancels, zero/max bonuses, counter-hit follow-ups, blocked contacts, both players' reversal timing, traditional/simple execution, expired buffers/hitstop, late inputs, opt-in normals, interruption of a timed reversal, combo continuity and deterministic restoration. Native, Godot and WebAssembly traces must still agree frame by frame.

Schema/core **10** appends two move fields and integer slowdown/cinematic snapshot state. Schema 1–9 imports keep existing authored counter bonuses, disable new slowdown and use legacy additive freeze until edited or restored to defaults. Counter tests cover alternate-tick clocks, airborne gravity, follow-up hitstop, trade symmetry, old-save migration, reduced-motion presentation and odd-phase snapshot replay.
## Contact audio and effect events (2026-11-23)

The core emits a bounded per-step presentation event list after resolving contacts.
It distinguishes hit, block, counter, punish, guard break, Faultless Defense,
armor/guard point, attack release, landing, wall impact, wall break and projectile
clash. Events carry the real source move/attack identity and receiving body position,
including projectiles whose owner has already started another move. Capture poses,
bleed ticks and utility pulls/dashes do not manufacture strike impacts. Paired throw
impacts occur at the damaging release.

Events are outside `State`, move data and checksums. The schema stays at 27 and
combat timing, damage, pushback and hitstop are unchanged. Godot keeps 360 input
frames of cosmetic history; resimulation replaces the predicted future. Visual cue
ages hold during shared hitstop. Online audio consumes only jointly confirmed input
frames, accepting a short confirmation delay rather than sounding a predicted hit
that becomes a block. Repaints do not replay audio. Round resets, menus, muted
playback and long stalls cannot burst old sounds on resume.

Godot's **Sound** control in the home/pause menus offers mute, volume and an impact
preview. The unpublished Workshop source has **View & playback → Sound: Off/On**.
Website updates and both publishing jobs are paused at the user's request; these
source changes have not been deployed. That control starts off, unlocks
only on a user click, loads the sound bank on demand, and plays only while the recorded exchange advances. Scrubbing
is silent; half-speed playback spaces the cues without pitching the samples down.

The 23 short WAVs are original synthesized placeholders, generated reproducibly by
`scripts/generate-combat-audio.py` with no external recordings. Cuts, spear strikes,
blunt body hits, hammer, gas, fire and stone have separate contact/release families;
counter bass layers under the weapon impact. Defense and wall sounds are separate.
Both frontends limit simultaneous voices and the output mix. These are an initial
sound-design pass; they can be replaced without changing combat logic.

## Native Ink Snap impacts

The user delegated the impact choice; **B / Ink Snap** is installed in Godot.
Two original generated atlases supply cut, blunt, pierce, fire, poison, block,
Faultless Defense and counter families. Guard breaks enlarge the block burst;
armor/clashes use pierce fragments and wall contacts use blunt fragments. These
effects sit above fighters and below collision diagnostics and the HUD. Existing
weapon trails stay separate. Wall-travel cinematics retain their own presentation.

Each family has three drawings, with metadata contact pivots and mirrored facing.
The contact drawing holds through shared hitstop and action ages 0–1; the release
plays at ages 2–4 and fragments at 5–9, then clears. There is no image interpolation
or pose warping. A follow-up replaces the prior body burst on that receiver so a
rapid multi-hit cannot stack frozen opaque impacts; trades and wall contacts stay
independent, and every contact retains its audio event. Opacity starts at 88%, then
76%, with fragments fading from 60%.
A small camera impulse and two-action-frame warm receiver tint replace the
previous red tint throughout hitstun. Reduced motion disables the impulse.

Contact placement prefers the overlapping hurt region nearest the strike's
vertical center, preventing tall mid attacks from always sparkling at the first
listed leg box. Projectiles use their contact location; throws use the torso.
Weapons never contribute hurt regions. This placement change is cosmetic and
does not alter hitboxes, damage, timing or rollback checksums.

`godot/assets/effects/impact-v1/manifest.json` preserves source hashes, regions and
pivots; PNG bytes are unchanged from generation. Exact prompts are retained in
`art/effects/impact-v1/production-prompts.md`.

Verification: native feedback assertions for low/mid/high contacts in both facings,
Godot feedback/history/audio tests,
the native impact rendering tests, and 11 review scenarios using the current
authored move data. Scenarios cover all eight families, guard break, a two-hit
Shark scoop and an airborne Fillet contact, including mirrored facing. The review
checks expected contact kinds and both hits before recording. The Windows core
repair ZIP and both DLLs match the updated native source manifest.

Run `python scripts/capture-impact-review.py` to record
`exports/FightGuild-Impact-Review.mp4` with actual gameplay timing and audio.
Use `bash scripts/godot.sh --headless --script res://tests/impacts_preview.gd --
--test --verify` for the same contact scenarios without rendering. Neither command
updates or publishes the move-editor website.
