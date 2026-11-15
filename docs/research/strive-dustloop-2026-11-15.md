# Dustloop study: priorities for the Fillet/Shark build

Research date: 2026-11-15. Implementation compared: `ad103f8` on `feat/godot-combat-lab`.

The three user-supplied MHTML archives are readable sources. This review uses their saved article text and tables; it does not claim a live website search or verification against a running Strive build. Recommendations below are proposals, not new combat rules or implemented features.

## Sources and limits

| Saved file | Article and saved revision link | Page footer: last edited | Archive capture, UTC |
| --- | --- | --- | --- |
| `GGST - Damage.mht` | [Damage, revision 576973](https://www.dustloop.com/wiki/index.php?title=GGST/Damage&oldid=576973) | 2026-09-06 05:12 | 2026-11-15 22:15:15 |
| `GGST - Mechanics.mht` | [Mechanics, revision 582457](https://www.dustloop.com/wiki/index.php?title=GGST/Mechanics&oldid=582457) | 2026-11-03 02:06 | 2026-11-15 22:15:10 |
| `GGST_Frame Data - Dustloop Wiki.mht` | [Frame Data, revision 563708](https://www.dustloop.com/wiki/index.php?title=GGST/Frame_Data&oldid=563708) | 2026-05-09 02:00 | 2026-11-15 22:14:49 |

Revision links come from each saved page's permalink. They have not been fetched independently. Page revision dates do not identify a single tested game patch. Section links below identify the passages in these saved copies; the live articles can change.

The Frame Data archive exposes only the first ten rows of several paginated character-comparison tables. Character-specific pages behind its links were not supplied. The archives also do not establish complete motion recognition, reversal-buffer, or hitstop-buffer rules; our current 5-frame button buffer, 20-frame motion window and 8-frame step gap remain provisional.

There is an internal source disagreement: Damage's **The Wall** section says wall stick restores one sixth of Burst, while **Hit Effects → Wall Stick** says 25%. Do not turn this into an exact implementation claim. Fight Guild has no Burst system, so it does not block the recommendations here.

## Recommended order

1. Extend the existing training tools with a two-player frame timeline and reproducible dummy recordings. Add editable cancel windows alongside it.
2. Introduce separate combo damage scaling, keeping the existing gravity threshold intact.
3. Specify normal block carryover, post-stun throw protection, prejump and landing recovery; preserve the user's guard-break exception.
4. Tune ordinary corner pushback, FD cost/spacing, and per-move counter-hit effects using recorded Fillet/Shark situations.
5. Refine wall accumulation and Positive Bonus after measuring the matchup's corner pressure and resource flow.

## 1. Make pressure measurable and cancels deliberate

**Source:** [Mechanics: Gatling Combination](https://www.dustloop.com/w/GGST/Mechanics#Gatling_Combination) and [Cancels](https://www.dustloop.com/w/GGST/Mechanics#Cancels) distinguish route eligibility from timing. The saved text describes delayed gatlings as frame traps, K gatlings restricted to active frames, and P/K special cancels restricted to active frames while other normals can allow recovery cancels. Frame Data's column definitions assume first-active-frame contact when listing advantage.

**Current build:** `cancel_allowed`, `Simulation::control` and `Simulation::can_cancel` in [the core](../../core/fight.cpp) implement the agreed route graph. Once contact is recorded, eligible ordinary cancels can remain available through recovery. Fillet's rekka allows a fresh follow-up after contact, or after the active frames finish on whiff, through remaining recovery. There are no separately authored open/close windows. Actual contact advantage is already calculated for the block pose and HUD. Training already has pause, frame step, hitboxes, input history and scripted dummies in [main.gd](../../godot/scripts/main.gd).

**Recommendation:** add move-specific windows for normal, special, jump and contextual follow-up cancels, with hit/block/whiff conditions. Keep the user's unified gatlings and same-button command-normal routes; windows should describe when those routes work. Do not import Strive's different route chart.

Expand the existing tools with both fighters' startup/active/recovery/stun timelines, contact frame, cancel window, gap duration, spacing, and input age at execution. Add record/replay of player inputs from a saved starting state. These tooling suggestions follow from the timing distinctions; they are not claims that these articles specify a training-mode UI.

For Fillet, compare immediate and delayed `236S > 6S > 2S`, the `236S > 2S` shortcut, and stopping after the starter. Decide which delays maintain a combo, leave an interruptible gap, or catch a button. The upward slash is currently a **mid**: the route is not an overhead/low mix-up. Test first and late contact on `236K` separately because later contact can improve advantage.

## 2. Separate damage reduction from combo gravity

**Source:** [Damage: Combo Decay](https://www.dustloop.com/w/GGST/Damage#Combo_Decay), [Gravity and Launch Speed](https://www.dustloop.com/w/GGST/Damage#Gravity_and_Launch_Speed), [Proration](https://www.dustloop.com/w/GGST/Damage#Proration) and [Negative R.I.S.C.](https://www.dustloop.com/w/GGST/Damage#Negative_R.I.S.C._and_Combo_Damage_Scaling) describe different mechanisms:

- Starter proration reduces later hits according to the opening move; the first hit is excluded.
- Per-move scaling contributions reduce damage as the combo continues. The saved article separates this from visible positive R.I.S.C.
- Combo decay affects launch, gravity and resource gain independently of damage scaling.
- Repeated use of the same move can add gravity; the saved description says most moves begin doing this on their third use, with exceptions.

**Current build:** unblocked attacks subtract authored damage directly. Gravity remains unchanged for the first X hits, then increases per hit to a cap. Each new hit replaces launch speed. There is no starter proration, progressive damage reduction or repeated-move history. See [recovery rules](../recovery-and-walls.md) and `gravity_percent`/contact resolution in the core.

**Recommendation:** add starter proration, per-move scaling contribution and a minimum-damage rule as editor fields, with current unscaled behavior preserved for migrated data. Keep gravity separate and preserve the explicit **no gravity scaling before X hits** rule. Any repetition-based gravity extension should respect that threshold too. A visible R.I.S.C. gauge is a separate design decision, not a prerequisite for damage scaling.

This lets a fast low or jab lead to useful pressure without automatically matching the reward of a committed slash starter. Shark's long-range pull can provide reliable positioning while its later damage is tuned independently. Test whether repeated hooks or same-button command-normal cycles remain sustainable; neither a loop nor an infinite has been demonstrated by this document.

Expose base damage, final damage, starter modifier, accumulated scaling and gravity in the development readout. Define integer rounding and combo-reset boundaries before implementation, then include the new state in rollback snapshots.

## 3. Clarify normal defense and preserve our guard-break identity

**Source:** [Mechanics: Guard](https://www.dustloop.com/w/GGST/Mechanics#Guard) describes block carryover: during a continuous blockstring, releasing back does not stop guarding, although low/high defense must still be correct. Carryover ends at a gap. [Throw Invulnerability](https://www.dustloop.com/w/GGST/Mechanics#Throw_Invulnerability) lists five protected frames after normal blockstun, hitstun and knockdown.

The saved [Guard Crush](https://www.dustloop.com/w/GGST/Mechanics#Guard_Crush) section explicitly says the defender is throw-immune **during** that state but loses the usual protection **after** it. It also requires an actual guard direction because guard crush has no block carryover.

**Current build:** `Simulation::blocks` requires away on every contact, including continuous normal blockstun. `throw_invulnerable` protects hitstun, normal blockstun and down/wakeup states, but there is no separately tracked post-recovery grace timer. Guard break deliberately allows throws during its stun and consumes backward-dash presses, as the user requested.

**Recommendation:** consider normal block carryover and an explicit, editable post-recovery throw-protection timer. Carryover would let a defender prepare a reversal motion during a true blockstring without being hit merely for releasing back. It must still enforce guard height and end when a gap opens. Test guard break separately and preserve its existing throw vulnerability and backdash restriction.

Do not copy Strive's 2-frame throws: Fight Guild's attacks, including `4P+K` and `6P+K`, retain the 5-frame startup floor. The prototype's strike-wins simultaneous strike/throw rule also differs from the saved Strive description; changing that priority is a distinct design choice.

## 4. Give aerial commitment a defined cost

**Source:** [Mechanics: Prejump](https://www.dustloop.com/w/GGST/Mechanics#Prejump) describes a vulnerable-to-strikes, throw-immune grounded startup before becoming airborne. [Landing Recovery](https://www.dustloop.com/w/GGST/Mechanics#Landing_Recovery) distinguishes empty jumps, aerial actions and moves with their own landing recovery. [Running](https://www.dustloop.com/w/GGST/Mechanics#Running) describes inertia during run skid and FD braking.

**Current build:** a jump immediately sets the fighter airborne. `Simulation::land` clears the current move without an authored landing-recovery state. Runs carry velocity into attacks and jumps, including a short carry window while entering motions; releasing a run returns to walking/still movement without a dedicated skid state.

**Recommendation:** prioritize move-specific landing recovery for Shark's `j.214P` and air stab, then define prejump and empty-jump behavior. Check low, medium and high jump heights: landing should not accidentally erase the intended whiff commitment. Do not add the same recovery to every aerial action without testing.

A visible run skid could later make existing inertia easier to read. Preserve forward runs for most fighters, character-specific step dashes and attack velocity carry. Normal jump physics must remain independent of combo gravity.

## 5. Tune spacing and FD together

**Source:** [Mechanics: Guard](https://www.dustloop.com/w/GGST/Mechanics#Guard) transfers ordinary strike block pushback to the attacker at the corner. [Faultless Defense](https://www.dustloop.com/w/GGST/Mechanics#Faultless_Defense) describes extra spacing as a central benefit: FD can make a later attack miss. Its additional pushback depends on attack level; projectiles are an exception. [Frame Data: Faultless Defense](https://www.dustloop.com/w/GGST/Frame_Data#Faultless_Defense) supplies gauge costs.

| Comparison | Saved Dustloop values | Fight Guild default |
| --- | --- | --- |
| Gauge capacity | 10,000 units | 10,000 units, displayed in three sections |
| Holding FD, ground | 400 frames to empty a full gauge | 1,000 ticks to empty, absent contact |
| Holding FD, air | 200 frames to empty a full gauge | Same drain as ground |
| FD contact cost | Strike costs 250–450 units by attack level, plus holding drain | 100 units + 4 × incoming base damage, plus holding drain |
| Block displacement | Ordinary strike corner transfer; FD adds extra pushback | Corner transfer implemented for FD; ordinary displacement clamps at the wall |

The source's ground/air depletion durations imply 25/50 units per frame; these are arithmetic conversions, not separately measured results. Current defaults are `fd_drain=10`, `fd_block_cost=100`, `fd_damage_cost=4`, `fd_push_percent=300` in [fight.h](../../core/fight.h).

**Recommendation:** establish ordinary corner pushback first, then compare FD against it at close range, tip range and the wall. Test whether FD interrupts Fillet's desired rekka spacing and makes Shark reposition after a blocked hook. Negative advantage alone does not guarantee a punish if the defender's answer cannot reach.

Separate holding drain, air drain, contact cost and spacing in tuning. Treat the saved numbers as a reference, not automatic replacements: our damage scale and resource economy differ. Momentum remains three visual sections, FD remains its only spend, and Negative Penalty remains deferred.

## 6. Make attack strength coherent without tying it to button names

**Source:** [Frame Data: Attack Level](https://www.dustloop.com/w/GGST/Frame_Data#Attack_Level) groups hitstop, hitstun and blockstun into five levels with exceptions. [Mechanics: Counter Hit Types](https://www.dustloop.com/w/GGST/Mechanics#Counter_Hit_Types) describes four counter categories with different audiovisual and mechanical effects. Its slowdown section distinguishes a shared freeze from victim-only slowdown that can persist into later hits.

**Current build:** each move already exposes individual stun/stop values and counter bonuses, initially +4 hitstun/+3 hitstop. Counter detection is based on startup/active versus recovery; all attacks use that classification rather than authored counter-vulnerability windows. There is no persistent victim-only slowdown state.

**Recommendation:** add optional attack-level and counter-effect presets in the editor, retaining explicit overrides. Choose the preset for the move's role, not simply P/K/S/Hs/D; the user has specified that button names do not define what each character does. Start by tuning existing bonuses so a committed heavy counter has a different reward from a quick poke or rekka link.

For closer Strive behavior later, add independent counter-vulnerability windows and a properly simulated slowdown state. More global hitstop alone does not reproduce victim-only slowdown. Coordinate input-buffer behavior with any larger counter freeze: our buffer currently ages during hitstop, and these archives do not establish the complete replacement rules.

## 7. Refine wall rules around the corner-pressure tradeoff

**Source:** [Damage: The Wall](https://www.dustloop.com/w/GGST/Damage#The_Wall) describes damage attached to the defender, a default midscreen accumulation cap at half wall health with exceptions, distinct grounded/airborne splat conditions, and time-dependent accumulation during combos. A normal/special wall break resets both players to actionable neutral. [Mechanics: Positive Bonus](https://www.dustloop.com/w/GGST/Mechanics#Positive_Bonus) describes benefits beyond meter generation.

**Current build:** wall damage already follows the defender. Far hits contribute one quarter but can still accumulate up to full durability. Grounded and airborne hits use the same threshold-to-splat condition. A splat can be broken into neutral, and Positive Bonus grants 150% earned Momentum plus passive generation. Its timer and passive generation pause during hitstop, whereas the saved source explicitly says its passive Tension gain continues during hitstop.

**Recommendation:** test an editable cap on damage accumulated away from a wall, then decide whether grounded splat should require the wall to have been primed before the hit. These affect how readily Fillet's carry routes and Shark's pull routes lead to a break. Tune them before seeking a numerical match to Strive's different wall units.

Measure whether breaking the wall is attractive compared with keeping corner pressure. With only FD available, extra Momentum mainly buys future defense; it does not provide Strive's offensive cancel/super opportunities. Tune existing break damage and bonus duration/gain first. Additional spending, Burst, damage buffs and defense buffs are separate design proposals.

## Playtest cases to keep

- Fillet: full rekka, low shortcut, delayed follow-up and stopped starter against ordinary guard, FD and a 5-frame response; repeat midscreen and in each corner.
- Fillet: spiral from standing and running, with early and late active-frame contact; record spacing and actionable-frame advantage.
- Shark: ground/air hook into P at close/tip range and three jump heights; compare hit, block, whiff and landing before recovery finishes.
- Defense: continuous blockstring versus a one-frame gap; high/low correctness while inputting a reversal; normal recovery throw grace versus guard break.
- Combos: identical follow-up route from a quick starter and a committed starter; repeat a move; check first X hits, threshold, cap and full reset after recovery.
- Walls: identical route begun midscreen and near a corner; grounded versus launched threshold crossing; splat expiry and break reward.
- Replay each authored case from the same state and inputs, including delayed-input rollback, when its corresponding system is implemented.

## Decisions preserved

The unified gatlings, all-attacks same-button command-normal route, minimum 5-frame startup, body-only hurtboxes, four-box pose limit, 2D sweep, `4P+K`/`6P+K` throws, rare hard knockdowns, automatic soft tech **in place**, gravity threshold, forward-run direction and guard-break exceptions remain authoritative. In particular, the saved Strive soft knockdown rolls backward; that is not our requested recovery rule. Universal overhead/anti-air design remains deferred.

Character defense and low-health Guts are possible later balance tools, documented in [Damage: Life Gauge](https://www.dustloop.com/w/GGST/Damage#Life_Gauge). They are lower priority than making the first matchup's timing and damage understandable. The health bar's existing bend near 30% is visual styling, not an implicit Guts mechanic.

## Archive identity

Only original analysis and source metadata are stored in the repository. The supplied MHTML files, their advertising frames and embedded third-party resources were not copied into the project or executed.

| Archive | SHA-256 |
| --- | --- |
| Damage | `0c76ccc72d042ed9ccd6f3a3fbba49f8ed59fe8c0c7bf7486629a25d0dcd4c19` |
| Mechanics | `4a1c2faf781e60e976d8203a445381f4dcbd286c68f3a6afd47ed8a074528d8c` |
| Frame Data | `0bc6e901f5a48ea793cb097674e6b8d1a5f0bf64d00a479af8c9442bc1a9a2a6` |
