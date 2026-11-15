# Playable-build backlog

## Next: consistent sprite and future-character pipeline

Requested scope: make repeatable character images performing directed actions, with one shared art language. See [the working sprite contract](sprite-production.md).

- [ ] Review and approve a common style master: outline weights, cel shadows, lighting, material ramps, camera and scale. Establish exact palette swatches and silhouette landmarks for all six current fighters before adding characters.
- [ ] Create a reusable character specification: neutral model sheet, proportions, face, costume landmarks, equipment geometry/handedness, palette, allowed deformation and prohibited drift. Use the same specification to onboard future characters.
- [ ] Create a structured action brief and generation template with pose direction, planted foot, root/contact anchors, weapon path, timing, phase and approved references. Save prompt/reference provenance and review decisions with every revision.
- [ ] Establish the common smear library: tapered crescents, thrust wedges, blunt arcs, smoke lobes. Separate effects from the body; make impact effects depend on contact. Replace inconsistent baked-in effects in the starter sheets.
- [ ] Add a review tool that compares silhouette, palette and landmarks against the master, scrubs adjacent frames, and previews actual in-game size, flipped facing, hitboxes and backgrounds.
- [ ] Automate validated import/packing: transparent margins, no neighboring sprite leakage, stable root/feet pivots, per-frame bounds, versioned manifests, naming, missing-frame checks and reproducible source-to-runtime mapping. Retain source art unchanged.
- [ ] Re-author windup and active frames per move, including crouching, command, special and airborne variations; the initial build reuses five button poses per fighter.
- [ ] Extend each attack to **windup, active, impact, follow-through and recovery** animations after the first two stages are approved. Support multiple drawings per phase and explicit whiff/hit/block paths without changing authoritative combat timing accidentally.
- [ ] Trial the complete workflow on one fighter and a second fighter with a different silhouette; measure drift and revision cost before using it for the rest of the roster or a new character.

## Momentum and defense

- [x] Divide the continuous Momentum HUD into three equal sections without adding spends or thresholds.
- [x] Add Momentum gain, 0–100% HUD and Faultless Defense as the only spend; expose training and editor controls.
- [x] Add three two-frame blocking clips for all six fighters, selected by actual contact advantage or authored guard break.
- [x] Prevent backdash buffering during guard break and expose the removal of blockstun throw protection.
- [ ] Measure/tune the provisional gain and FD formulas against a chosen GGST version. **Negative Penalty is deferred by user decision.** No additional meter spending is authorized in this pass.
- [ ] Add standing/crouching/air variants and smooth intermediate defensive frames under the same shape/palette rules.
- [ ] Connect the future throw resolver to `throwInvulnerable`; retain normal blockstun protection and the guard-break exception.

## Combo feedback and hit timing

- [x] Add a large styled combo counter behind fighters, following the attacker's current side with deterministic pop/hold/fade timing.
- [x] Distinguish startup/active counter hits from recovery punishes, including symmetric trades.
- [x] Expose per-move counter-hit hitstun/hitstop bonuses and reversal eligibility; preserve old saved move sets.
- [x] Detect first-actionable-frame reversals through the existing input buffer and add attack-loop / guard-to-reversal practice dummies.
- [ ] Playtest the provisional +4 hitstun/+3 hitstop counter defaults across the six kits before choosing distinct move-specific values.
- [ ] Design knockdown/wakeup and invulnerable reversal moves separately; route wakeup completion through the same reversal timing opportunity.

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

- [ ] Playtest the basic P/K/S/Hs/D buttons and unified gatlings, then replace provisional move data and Drive behaviors character by character.
- [ ] Collect repeatable Strive input traces to tune buffer behavior and motion leniency.
- [ ] Design throws, universal overheads, universal anti-air rules with the user.
- [ ] Broaden native online testing under real network conditions; add Internet connectivity/matchmaking and resilience after local rollback validation.
- [ ] Validate physical controllers and Windows gameplay; establish the approved PS5 Godot port/tooling path before console delivery.
- [ ] Retain the simulation/presentation boundary for eventual 3D characters constrained to the 2D plane.
