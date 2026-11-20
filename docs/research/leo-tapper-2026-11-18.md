# Leo reference → Tapper authoring map

> 18 November 2026 update: the startup-floor decisions below are historical. Standard ground/air throws now start in 2f. Minimums are 2f for grabs, 3f for P normals, and 5f for other attacks; see [current startup rules](../startup-rules.md).

Source: user-supplied **GGST - Leo Whitefang.mht**, captured **18 November 2026 at 01:11:35 UTC**. Saved [article revision 581554](https://www.dustloop.com/wiki/index.php?title=GGST/Leo_Whitefang&oldid=581554) reports last edited **20 October 2026 at 16:48**. This is a verified saved page, not a live fetch or verification of the currently installed Strive patch.

Original archive SHA-256: `7a674b4dbce99f7db24eb5685fefd4070573ca4d21f3748d344a24ef34aa1235`. The [machine-readable source map](../../references/frame-data/leo-whitefang-2026-11-18.json) preserves all normal/throw frame tables and their extended data, with independently written utility notes. It is a reference artifact, **not an importable Move Workshop JSON file**.

## Normal frame data

One frame is 1/60 second. Startup includes the first active frame. `3(3)3` means three active frames, three inactive frames, then three active frames. `High` in the source means overhead against a grounded defender. H is Hs in Fight Guild.

| Leo move | Tapper mapping | Startup | Active | Recovery | On block | Guard |
|---|---|---:|---|---|---|---|
| 5P | 5P | 5 | 5 | 6 | -1 | All |
| 5K | 5K | 9 | 4 | 13 | -3 | All |
| c.S | 5S close-distance variant | 7 | 6 | 10 | +1 | All |
| f.S | 5S far-distance variant | 12 | 6 | 21 | -13 | All |
| 5H | 5Hs | 15 | 5 | 22 | -10 | All |
| 2P | 2P | 6 | 4 | 8 | -2 | All |
| 2K | 2K | 7 | 6 | 11 | -5 | Low |
| 2S | 2S | 10 | 3 | 13 | -2 | Low |
| 2H | 2Hs | 12 | 8 | 29 | -20 | All |
| 2D | 2D outside rolling stance | 12 | 6 | 19 | -8 | Low |
| 6P | 6P | 10 | 5 | 21 | -9 | All |
| 6K | 6K | 14 | 3 | 18 | -4 | All |
| 6H | 6Hs | 28 | 2 | 30 | -15 | All |
| j.P | j.P | 5 | 3 | 9 | +5~+6 (IAD j.PPPP) | High |
| j.K | j.K | 10 | 7 | 25 | 0 (IAD) | High |
| j.S | j.S | 7 | 3(3)3 | 17 | +6 (IAD) | High |
| j.H | j.Hs | 11 | 3 | 19 | +3 (IAD) | High |
| j.D | j.D | 22 | Until Landing | 15 | -6 ~ -2 | High |

Air-normal advantage in the page is contextual: j.P is an IAD repeated-jab example; j.K/j.S/j.H assume an IAD; j.D varies with contact height. These must be recreated as tests rather than entered as universal block advantages. Landing timing and contact frame matter.

## Grounded timing translation

For a fixed-duration grounded move, first-active-frame block advantage is `blockstun − (active − 1 + recovery)`. This gives directly usable blockstun targets without confusing advantage with stun:

| Move | Derived blockstun | Source on block |
|---|---:|---:|
| 5P | 9 | -1 |
| 5K | 13 | -3 |
| c.S | 16 | +1 |
| f.S | 13 | -13 |
| 5H | 16 | -10 |
| [H]S_or_[S]H / Guard Attack | 16 | 0 |
| 2P | 9 | -2 |
| 2K | 11 | -5 |
| 2S | 13 | -2 |
| 2H | 16 | -20 |
| 2D | 16 | -8 |
| 6P | 16 | -9 |
| 6K | 16 | -4 |
| 6H | 16 | -15 |

KD/HKD advantage includes a hit reaction and recovery sequence; it must not be assigned directly to `hitstun`. For example, 6P’s grounded result includes floating crumple, so merely changing its stun field does not port its utility.

## Move-function mapping

- **5P → 5P:** Fast, low-recovery pressure/defense jab; upward coverage also supports anti-airing. Can be low-profiled.
- **5K → 5K:** Advancing whiff-punish and approach normal, with useful dash momentum carry.
- **c.S → 5S close-distance variant:** Proximity-only pressure/punish starter, +1 on block, low pushback; ground bounce against airborne targets.
- **f.S → 5S far-distance variant:** Longer poke with strong dash carry and airborne horizontal push. Holding S enters Guard Stance on move frame 26.
- **5H → 5Hs:** Large, slower poke; low-reaching hitbox during move frames 17-19; wall bounce on airborne hit. Holding H enters Guard Stance on frame 27.
- **[H]S_or_[S]H → held S/Hs guard and opposite-button follow-up:** Hold S after f.S or H after 5H to guard mids/highs. Lows and throws beat the hold. The opposite button starts Guard Attack, which has one-hit mid/high armor on frames 1-9. Guard hold negates blockstun, preserves chip/hitstop, and has 16f release recovery.
- **2P → 2P:** Lower-reaching jab; slower than 5P but less susceptible to low-profile attacks.
- **2K → 2K:** Long and active low with run/dash carry; pressure, counterpoke and retreat-catching utility.
- **2S → 2S:** Low poke and pressure tool; -2 on block permits threatening a delayed follow-up or pressure reset.
- **2H → 2Hs:** Launcher/combo filler; substantial recovery and punishable on block.
- **2D → 2D outside rolling stance:** Hard-knockdown sweep, no special cancel. Semi-airborne frames 5-18 give low-crush/throw-avoidance utility.
- **6P → 6P:** Upper-body-protected anti-air; low hurt profile on frames 1-3 and 4-14. Floating crumple on grounded hit and hard knockdown on airborne counter hit.
- **6K → 6K:** Advances during startup; kick confirm/pressure tool, -4 on block. Counter hit can link to close Slash.
- **6H → 6Hs:** Slow advancing mid, not an overhead; airborne ground bounce and backdash-callout utility. No overhead anti-air hitbox implied by the animation.
- **j.P → j.P:** Fast, short air-to-air jab; listed advantage is a contextual IAD repeated-jab example.
- **j.K → j.K:** Versatile air-to-air/jump-in; listed advantage assumes an IAD setup.
- **j.S → j.S:** Two-hit, short-range air combo tool: 3 active, 3 inactive, 3 active frames. Upward hit trajectory; jump/air-dash cancelable on either hit.
- **j.H → j.Hs:** Long horizontal air-to-air and retreating air normal; limited downward coverage.
- **j.D → j.D:** Stalls air momentum during startup, then dives diagonally until landing; 15f landing recovery. Air hit has wall/ground bounce. Hit/block allows special, jump and air-dash cancels, including landing frames.
- **Ground_Throw → 4P+K / 6P+K outside rolling stance:** Forward/back throw gives hard knockdown and enters offensive stance. Source startup is 2f; Fight Guild minimum requires 5f unless that rule is explicitly changed.
- **Air_Throw → air-throw definitions needed:** Forward/back air throw can catch targets on either side; hard knockdown. Source startup is 2f; recovery is 38 or landing+10.

## Engine and editor support assessment

This assessment is against Fight Guild commit `619f18c` / combat schema 17. It describes implementation work; no Tapper runtime values were changed by this source-ingestion pass.

| Requirement | Current support | Work needed for the Leo baseline |
|---|---|---|
| Fixed startup/active/recovery, guard level, blockstun, proration and counter tier | Editable per move | Apply the verified values, keeping source damage separate from Fight Guild balance. |
| Close and far Slash on the same S input | One grounded 5S definition per fighter | Add distance-dependent selection and independent editable definitions. Expose both in preview; never hide one behind an unrelated command input. |
| Holding f.S / 5Hs into guard | No held guard transition | Add the timed hold/release states, opposite-button follow-up and preview hold controls. Guard hold is a front-facing neutral-kit mechanic, separate from the custom rolling stance that cannot block. |
| One-hit mid/high armor on Guard Attack | No armor contact rule | Add a hit-limited armor window that preserves damage/hitstop and loses to lows/throws. Guard hold itself has different blockstun/chip behavior and must not be implemented as armor. |
| j.S's two hits | Timed hitboxes and hit groups exist | Use active span 9 with groups at active frames 1 and 7, and an empty key at frame 4. Each hit has 3 active frames; the middle 3 frames do not hit. Give the later hit its upward coverage. |
| 5Hs's late low-reaching hitbox | Timed hitboxes exist | Start its lower hitbox at active frame 3, corresponding to move frame 17; keep it through frame 19. Hurtboxes still describe Tapper's body, never his staff. |
| 5K / 6K / 6Hs startup advancement | Opening displacement and active travel exist | Add or author actual startup movement over time; an instantaneous opening teleport is not equivalent. |
| j.D's stall, diagonal dive and landing recovery | Air movement and landing recovery exist, but attacks have fixed active durations | Add startup velocity control, active dive velocity, activity until landing and the specified landing cancel window. Test several contact heights. |
| Ground/wall bounces | Launch, knockdown, velocity-driven walls and wall splat exist | Add bounded bounce reactions and editor controls. Keep current wall-health damage tied to collision velocity; do not copy the source's flat Wall Damage column into it. |
| 6P grounded crumple / airborne counter-hit hard knockdown | Universal upper-body protection and basic launch/KD exist | Add contextual hit reactions. A uniform knockdown field cannot reproduce both outcomes. |
| Timed low profiles / semi-airborne 2D | Three-phase hurtbox masks and body profiles exist | Add finer timing for 6P's early profile and 2D's frames 5–18. Semi-airborne must affect throw eligibility and collision without selecting an air normal accidentally. |
| Ground throw enters Tapper's rolling stance | Ground throws and hard knockdown exist | Connect successful contact to the custom stance state, with the collar/headbutt animation brief. |
| Air throw | Universal throw selection/collision is grounded | Add air target eligibility, both-side catch behavior, side switching, landing recovery and editor definitions. Source 2f startup becomes 5f under the existing minimum. |
| Rolling stance and running tackle throw | Not implemented | Use the user's custom design, rather than importing Leo's entire backturn move set or his specials. |

## How the stance reference informs Tapper

The source contains useful comparisons for Tapper's custom stance, but the user asked for the **non-stance** kit to mirror Leo. These are references and proposals, not automatically approved stance frame values:

| Leo reference | Startup / active / recovery | Ordinary on block | Relevance to Tapper |
|---|---|---|---|
| bt.K | 5 / 3 / 6 | +3 | This is Leo's self-looping pressure button. Its timing is a closer starting reference for Tapper's fast, self-pressuring **mid S** than copying bt.S directly. Tapper S remains a mid; the guard level would differ. |
| bt.S | 6 / 6 / 14 | −3 | Fast and long-reaching, but ordinarily negative. Its reported +5 is after the earliest stance cancel, not its uncanceled advantage. |
| bt.H | 18 / 4 / 21 | −8 | A useful overhead reference. Reported +3 requires the earliest stance cancel. Ground bounce and startup movement are part of its reward. |
| Stance cancel | 11 total frames | Depends on the source move/window | A concrete reference for the recovery of Tapper's proposed 2D exit. The user has approved the input and route, not this duration yet. |

Leo's bt.H has restrictive outgoing cancels. **Tapper's confirmed cross-normal stance gatlings take priority.** Likewise, Tapper's running tackle → single strong punch → stance offense is a custom command throw. Do not substitute Leo's existing command-grab animation or silently assign its motion input.

## Preserved project decisions and limits

- Source throws start in 2f. The existing minimum remains 5f unless the user explicitly changes it; record this as an intentional difference.
- The custom grounded Drive replaces Leo's Dust attack. Both Dust versions are retained as source data only. No charged Dust, homing follow-up or new Momentum spend is implied.
- Outside rolling stance, 2D is the hard-knockdown sweep. Inside rolling stance, it is the user-defined stance exit.
- Leo's 2D cannot special cancel. This is a specific utility exception to evaluate/apply within the project's provision for per-move exceptions.
- Unified non-stance gatlings and the universal same-button command-normal rule remain authoritative. Record any Leo route that conflicts; the source's entire cancel chart is not an automatic replacement for Fight Guild's rules.
- Leo has no matching ordinary 6S or 6D normal in this source. Tapper's provisional command slots need deliberate disabling or reassignment in the implementation, not invented Leo data.
- Source pixel sizes, damage, R.I.S.C., flat wall damage and Tension gain are not automatically compatible with Fight Guild's coordinate, health, wall and Momentum systems.
- Exact move shapes need Tapper-specific body/weapon animation. The source is sufficient for timing and utility, but not a finished sprite or hurtbox set.

The next implementation can use this complete mapping without asking for the same archive again. Source ingestion is complete; the stance, selector, guard, movement and reaction work above remains explicit in the backlog.
