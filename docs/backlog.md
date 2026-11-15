# Playable-build backlog

## Approved combat priorities from the Dustloop study

The [2026-11-15 source review](research/strive-dustloop-2026-11-15.md) compares the three supplied saved pages with the Fillet/Shark build. The user approved these priorities, including block carryover and post-stun throw protection after clarification. **No Just Guard / Instant Block timing mechanic is requested.** Guard-break throw vulnerability and the backward-dash restriction remain authoritative.

- [x] Add a two-player frame timeline with contact, phase, gap, spacing, cancel-window, input-age, damage and gravity readouts; record/replay both players or P2 alone from a saved state.
- [x] Add editable normal/special/jump/follow-up cancel windows while retaining the unified routes; verify Fillet's full rekka and low shortcut.
- [x] Add starter proration, per-move combo scaling and minimum damage independently of gravity; preserve the first-X-hits rule and add repeated-move gravity after that threshold.
- [x] Add ordinary block carryover and editable post-recovery throw protection, preserving guard-break throw vulnerability and its backdash restriction.
- [x] Add move-specific landing recovery, including Shark's air hook and air stab, and a separate recovered-air-action landing duration.
- [ ] Add grounded jump startup before takeoff; define empty-jump recovery independently of aerial attacks.
- [x] Add ordinary corner pushback and separate FD ground/air drain and attack-level contact costs. Keep FD as the only Momentum spend and Negative Penalty deferred.
- [x] Add optional attack-strength/counter presets, per-move overrides and counter-vulnerability masks; distinguish heavy counters from pokes and follow-ups.
- [x] Add an editable midscreen wall-damage cap and grounded wall priming, with separate airborne threshold behavior.
- [ ] Playtest the recorded Fillet/Shark pressure, FD spacing, hook height and wall-break reward cases from the source review before locking balance. Persistent victim-only slowdown remains a later feature, separate from shared hitstop.

See [combat tuning](combat-tuning.md) for defaults, migration rules and verified cases.

## Next: consistent sprite and future-character pipeline

Requested scope: make repeatable character images performing directed actions, with one shared art language. See [the working sprite contract](sprite-production.md).

- [ ] Review and approve a common style master: outline weights, cel shadows, lighting, material ramps, camera and scale. Establish exact palette swatches and silhouette landmarks for all six current fighters before adding characters.
- [ ] Create a reusable character specification: neutral model sheet, proportions, face, costume landmarks, equipment geometry/handedness, palette, allowed deformation and prohibited drift. Use the same specification to onboard future characters.
- [ ] Create a structured action brief and generation template with pose direction, planted foot, root/contact anchors, weapon path, timing, phase and approved references. Save prompt/reference provenance and review decisions with every revision.
- [ ] Establish the common smear library: tapered crescents, thrust wedges, blunt arcs, smoke lobes. Separate effects from the body; make impact effects depend on contact. Replace inconsistent baked-in effects in the starter sheets.
- [ ] Add a review tool that compares silhouette, palette and landmarks against the master, scrubs adjacent frames, and previews actual in-game size, flipped facing, hitboxes and backgrounds.
- [ ] Automate validated import/packing: transparent margins, no neighboring sprite leakage, stable root/feet pivots, per-frame bounds, versioned manifests, naming, missing-frame checks and reproducible source-to-runtime mapping. Retain source art unchanged.
- [ ] Continue per-move windup/active art beyond the first Fillet/Shark signatures, including crouching, command and airborne normals.
- [ ] Extend each attack to **windup, active, impact, follow-through and recovery** animations after the first two stages are approved. Support multiple drawings per phase and explicit whiff/hit/block paths without changing authoritative combat timing accidentally.
- [ ] Trial the complete workflow on one fighter and a second fighter with a different silhouette; measure drift and revision cost before using it for the rest of the roster or a new character.

## Momentum and defense

- [x] Divide the continuous Momentum HUD into three equal sections without adding spends or thresholds.
- [x] Add Momentum gain, 0–100% HUD and Faultless Defense as the only spend; expose training and editor controls.
- [x] Add three two-frame blocking clips for all six fighters, selected by actual contact advantage or authored guard break.
- [x] Prevent backdash buffering during guard break and expose the removal of blockstun throw protection.
- [ ] Measure/tune the provisional gain and FD formulas against a chosen GGST version. **Negative Penalty is deferred by user decision.** No additional meter spending is authorized in this pass.
- [ ] Add standing/crouching/air variants and smooth intermediate defensive frames under the same shape/palette rules.
- [x] Connect 4P+K / 6P+K throws to shared throw eligibility; retain normal blockstun protection and the guard-break exception.

## Combo feedback and hit timing

- [x] Add a large styled combo counter behind fighters, following the attacker's current side with deterministic pop/hold/fade timing.
- [x] Distinguish startup/active counter hits from recovery punishes, including symmetric trades.
- [x] Expose per-move counter-hit hitstun/hitstop bonuses and reversal eligibility; preserve old saved move sets.
- [x] Detect first-actionable-frame reversals through the existing input buffer and add attack-loop / guard-to-reversal practice dummies.
- [ ] Playtest the new minimal/small/medium/large counter presets across the six kits before locking move-specific values.
- [x] Add automatic soft/hard knockdown recovery and route wakeup completion through the existing reversal opportunity.
- [ ] Design invulnerable reversal tools separately.

## Menus and match flow

- [x] Give the main screen a fighting-game identity: title wordmark, full-size fighter face-off and a prominent Versus entry.

- [x] Match the supplied Guild Ball style with shared nine-slice surfaces, licensed fonts, semantic button states, a scoped warm Controls guide and a fighting-game title screen.
- [ ] Import the actual newspaper drawing/page-turn background films when supplied; retain a still presentation for reduced motion.

- [x] Main menu with separate Versus, Training and Development paths and full-screen fighter selection.
- [x] Smooth interruptible menu/match transitions, input isolation and persistent reduced motion.
- [x] Central six-fighter portrait grid, opposing guild artwork, animated selection and independent player markers/input toggles.
- [x] Local match results/rematch, offline pause/restart, cancelable fighter changes and return to main menu.
- [x] Direct online connection lobby with waiting/cancel/error recovery and neutral input while the in-match menu is open.
- [x] Keyboard/controller UI actions and held-confirm protection; verify source and exported Linux builds.
- [x] Real fighter loading, two character spotlights, four-beat opening and synchronized online readiness.
- [x] First-to-two Scrums: 1st Scrum, 2nd Scrum, Final Down at 1–1, automatic intermissions, draw replay, win marks and packet isolation between Scrums.
- [ ] Author dedicated intro animation clips and record the announcer once the presentation copy is settled.
- [ ] Add negotiated online match rematches and matchmaking after the direct-connection prototype.
- [ ] Decide stage selection and knockdown/wakeup presentation with the user.

## Combat and delivery

- [x] Fit body-only hurtboxes to all 160 existing sprite poses; weapons and effects add no hurt area.
- [x] Limit each pose to legs, torso-and-arms, head, and one optional extension; enforce the four-hurtbox maximum in authoring and native storage.
- [x] Add per-fighter pushboxes, wall separation, movement sweeps and airborne crossing/landing checks.
- [x] Give the original 132 move slots preliminary stats and sprite-derived attack rectangles; enforce startup ≥ 5f in core, editor and imports.
- [x] Share pose selection between collision and rendering; add live collision colors and all-pose/facing review.
- [ ] Replace shared button collision with per-move, per-animation-frame geometry as dedicated animations are produced; playtest spacing and matchup balance.
- [ ] Playtest the basic P/K/S/Hs/D buttons and unified gatlings, then replace provisional move data and Drive behaviors character by character.
- [ ] Collect repeatable Strive input traces to tune buffer behavior and motion leniency.
- [x] Add universal 2D sweep and 4P+K / 6P+K throws with hard knockdown and the 5f startup floor.
- [ ] Design universal overheads and universal anti-air rules with the user.
- [ ] Broaden native online testing under real network conditions; add Internet connectivity/matchmaking and resilience after local rollback validation.
- [ ] Validate physical controllers and Windows gameplay; establish the approved PS5 Godot port/tooling path before console delivery.
- [ ] Retain the simulation/presentation boundary for eventual 3D characters constrained to the 2D plane.

## First matchup, recovery and walls

- [x] Focus Fillet/Shark, use numpad notation, and retain the full roster.
- [x] Edit ground/air hit displacement, block pushback, launch, soft/hard down and wakeup timing, wall damage and throw range.
- [x] Keep gravity unchanged for the first X hits, then scale per hit to an editable cap.
- [x] Add wall damage/decay, splat/follow-up break, deterministic transition/neutral reset and timed Momentum Positive Bonus.
- [x] Preserve schema 1–6 move edits and test delayed-input rollback through wall breaks.
- [ ] Tune Fillet/Shark routes, gravity threshold and wall durability through local playtests.
- [ ] Author dedicated windup/active sweep and throw art first, then coherent launch/splat/down/wakeup clips under the existing sprite contract. Current reactions reuse existing poses.
- [ ] Produce distinct stage-travel backgrounds and wall-break shots; current ground variants share a layout.
- [ ] Measure a chosen Strive patch's wall-damage and Positive Bonus behavior before claiming exact parity. Super-specific break knockdowns wait for super design.

## First signature kits and locomotion

- [x] Generate Fillet knife spiral and upward/mid/low rekka windup/active poses under the shared style contract.
- [x] Implement 236K; 236S > 6S > 2S and the 236S > 2S shortcut, with a low soft-knockdown finisher.
- [x] Generate Shark ground/air hooks and short-blade follow-up pairs; separate the spear weapon from hook-active bodies.
- [x] Implement 214S / j.214P, opposing 45° trajectories, narrow moving hitboxes, body-only hurtboxes, pull and hit-only P follow-ups.
- [x] Add forward runs for most fighters, provisional Anvil step dash, 66/macro inputs and attack velocity carry; expose per-character movement and per-move inertia/travel.
- [x] Extend Sprite review, configuration migration, collision validation and rollback checks for the new kits.
- [ ] Playtest follow-up windows, whiff routes, travel friction, pull distance and hook matchups before locking balance.
- [ ] Author dedicated run/step poses and coherent return/retrieval animation. Current movement reuses walking poses; hook retraction reuses the active body.
