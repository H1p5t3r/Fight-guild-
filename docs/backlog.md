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

- [x] Add Momentum gain, 0–100% HUD and Faultless Defense as the only spend; expose training and editor controls.
- [x] Add three two-frame blocking clips for all six fighters, selected by actual contact advantage or authored guard break.
- [x] Prevent backdash buffering during guard break and expose the removal of blockstun throw protection.
- [ ] Measure/tune the provisional gain and FD formulas against a chosen GGST version. **Negative Penalty is deferred by user decision.** No additional meter spending is authorized in this pass.
- [ ] Add standing/crouching/air variants and smooth intermediate defensive frames under the same shape/palette rules.
- [ ] Connect the future throw resolver to `throwInvulnerable`; retain normal blockstun protection and the guard-break exception.

## Combat and delivery

- [ ] Playtest the basic P/K/S/Hs/D buttons and unified gatlings, then replace provisional move data and Drive behaviors character by character.
- [ ] Collect repeatable Strive input traces to tune buffer behavior and motion leniency.
- [ ] Design throws, universal overheads, universal anti-air rules and match flow with the user.
- [ ] Broaden native online testing under real network conditions; add Internet connectivity/matchmaking and resilience after local rollback validation.
- [ ] Validate physical controllers and Windows gameplay; establish the approved PS5 Godot port/tooling path before console delivery.
- [ ] Retain the simulation/presentation boundary for eventual 3D characters constrained to the 2D plane.
