# Playable-build backlog

## Hammer · Break Step

- [x] Full provisional normals, air normals, throws and three specials; approved A / Shoulder Drive art.
- [x] One-use step Drive, special → Drive → normal routes, full velocity carry, editable block advantage and neutral reset.
- [x] Automatic reach + block-push travel calibration, rollback state, editor controls and an interactive motion review.
- [ ] Playtest spacing, reactability and the +4f pressure reward against the other finished kits.
- [ ] Replace Hammer’s remaining legacy walk/run, guard and hit-reaction artwork through the approved options process.

## Approved combat priorities from the Dustloop study

The [2026-11-15 source review](research/strive-dustloop-2026-11-15.md) compares the three supplied saved pages with the Fillet/Shark build. The user approved these priorities, including block carryover and post-stun throw protection after clarification. **No Just Guard / Instant Block timing mechanic is requested.** Guard-break throw vulnerability and the backward-dash restriction remain authoritative.

- [x] Add a two-player frame timeline with contact, phase, gap, spacing, cancel-window, input-age, damage and gravity readouts; record/replay both players or P2 alone from a saved state.
- [x] Add editable normal/special/jump/follow-up cancel windows while retaining the unified routes; verify Fillet's full rekka and low shortcut.
- [x] Add starter proration, per-move combo scaling and minimum damage independently of gravity; preserve the first-X-hits rule and add repeated-move gravity after that threshold.
- [x] Add ordinary block carryover and editable post-recovery throw protection, preserving guard-break throw vulnerability and its backdash restriction.
- [x] Add move-specific landing recovery, including Shark's air hook and air stab, and a separate recovered-air-action landing duration.
- [x] Add editable grounded jump startup before takeoff; define empty-jump recovery independently of aerial attacks.
- [x] Add ordinary corner pushback and separate FD ground/air drain and attack-level contact costs. Keep FD as the only Momentum spend and Negative Penalty deferred.
- [x] Add optional attack-strength/counter presets, per-move overrides and counter-vulnerability masks; distinguish heavy counters from pokes and follow-ups.
- [x] Replace the earlier midscreen cap / grounded priming design with per-wall health and velocity-based hitstun collisions; depletion primes a separate later collision to splat.
- [ ] Playtest the recorded Fillet/Shark pressure, FD spacing, hook height and wall-break reward cases from the source review before locking balance.

See [combat tuning](combat-tuning.md) for defaults, migration rules and verified cases.

## Fillet v1 integration and art review

- [x] Apply the supplied animation-guide audit across all 26 enabled Fillet actions; refine c.S short-knife reach/trail, j.K atlas/pelvis registration and 623Hs staged lowering. Preserve actual pre-audit recordings and add hit/guard/whiff, silhouette/effect controls and a 60fps comparison. See [guide audit](fillet-animation-audit-2026-11-20.md).
- [ ] Replace the legacy neutral-air artwork with an approved common air tuck and landing-entry family; reconcile j.P/j.K/j.S/j.Hs release silhouettes without changing airborne momentum or landing lockout.
- [ ] Author paired receiver poses for Fillet's throws and cashouts so collar/forearm contact stays physically connected across the roster's sizes. Keep the existing confirmed-capture clocks and release events.
- [ ] Refine the shared broad crescents on f.S/5Hs/236S and the late shoulder lowering on 2Hs. Check silhouettes with VFX hidden, preserve current reach and hit groups, and use the current approval process for new motion directions.

- [x] Import the supplied v1 mechanics into schema 23, preserving the other fighters and older saves. Add Wound, owned bleed, finite Vault/Skim captures, paired recovery and shared ordinary-throw tech.
- [x] Expose exact body/push/root keys, named routes and paired settings in the Workshop and native development controls; add live state inspection.
- [x] Verify all 894 canonical action frames in both facings and player slots, plus paired capture/release, real-input pressure and rollback checks.
- [x] Record **B — Hip-led** as the selected f.S motion direction and generate review studies using model 06.
- [x] Generate [batch 01 options for 5P, 2P, 5K and 2K](../art/characters/fillet-v1/review/normals-batch-01/README.md), refine P-option differences and lower 5K contact height. User selected **5P-A, 2P-B, 5K-A, 2K-B**.
- [x] Generate [batch 02 options for 5Hs, 2S, 2Hs, 6P and 6Hs](../art/characters/fillet-v1/review/normals-batch-02/README.md), then expand them to one sheet per move with **windup, contact and follow-through**, plus blade/body/footwork direction arrows. User selected **5Hs-B, 2Hs-B, 6P-B, 6Hs-B** and **2S-B / Hip Reap from the second study**. For 6P, correct LEFT-short/RIGHT-long arm ownership in every final pose and both facings is an explicit production requirement. All 11 ground-normal directions are selected; all 26 action directions/production states are tracked in the review selection log.
- [x] Generate and register the selected 11 ground normals as [92 playable pose keys](fillet-ground-art.md), with correct 6P arm ownership, second-study Hip Reap sweep, authored timing, edited-timing playback, hitstop and rollback checks. Preserve source pixels and canonical combat geometry.
- [x] Expand 5P, 5K and 2S with 24 drawn in-betweens: phase-entry drawing plus every second action frame, following the user's photographed rule. Add an inspectable before/after browser player and recorded preview; keep move timing and combat geometry unchanged.
- [x] Review the sweep's held anticipation, contact and recovery timing, then apply the approved exposure process across the full kit.
- [x] Rework 2S after timing review: seven consistent body poses, a fixed support foot, held load, sharp first active frame and deliberate recovery. Preserve 12/4/23 timing and actual 9-frame hitstop; provide game-speed whiff/contact comparisons.
- [ ] Refine exact ground-normal anatomical/weapon fit against canonical geometry, including f.S's 125px reach, support-foot entry variants, continuous entry/exit clips and separate reverse-view artwork. First production pass uses the existing mirrored renderer.
- [ ] Finish paired receiver coverage, interruption/entry/exit clips and the full art acceptance matrix within the approved implementation-pack choreography. New motion directions still go through the options stage.

See [implementation and verification](fillet-v1-implementation.md).

## Next: consistent sprite and future-character pipeline

Requested scope: make repeatable character images performing directed actions, with one shared art language. See [the working sprite contract](sprite-production.md).

- [x] Add a standalone browser move workshop for office PCs: existing sprite/hitbox preview, attack tuning, Godot JSON exchange and per-move art/effect notes. See [Move Workshop](move-workshop.md). The full generation/approval pipeline below remains to be built.
- [x] Attach per-move pose-reference photos with captions and Windup/Active labels; preserve the image data in workshop JSON exports, browser drafts and undo history.
- [x] Edit attack hurtboxes in the browser by phase and body region, with a four-box limit, isolated move profiles, native JSON import/save, collision checks and rollback compatibility.

- [x] Redraw Fillet/Shark first with mature athletic proportions; integrate all 64 current poses, refit body/strike regions, preserve old versions and record generation corrections.
- [x] Remake Fillet/Shark model references and four windup/active signature pairs per fighter under a shared page/style system; record equipment/palette rules, editor-data handoff, exact prompts, archives and downloadable PDFs. See [reference 03](fillet-shark-references.md). These are reference candidates; runtime replacement and user approval remain separate work.
- [x] Record the user's A / Stalker standard-stance selection, superseding B/F spacing; update Fillet's model thumbnail and Shark's lower-volume long hair across model/action references in revision 04, with preserved history and new PDFs.
- [x] Select Shark F / Shoulder Rest; replace face paint with blue sports glasses across model/action references and preserve long, lower-volume hair (reference 05).
- [x] Add selected Stalker / Shoulder Rest ready sprites and separate eight-frame walk/run loops for Fillet/Shark, with blue sports glasses, fitted body-only hurtboxes, distance-driven playback and native/browser review.
- [x] Generate a 3x swing-band thickness pass for all existing swing trails; retain attack reach, timings and geometry.
- [ ] Add breathing loops and transition in-betweens; carry the selected model/eyewear into older attack, defensive, jump, portrait and intro drawings.
- [ ] Review the new Fillet/Shark studies in motion, approve their anatomical/palette masters, then apply the same proportion rules to Anvil, Hammer, Smoke and Tapper.

- [ ] Review and approve a common style master: outline weights, cel shadows, lighting, material ramps, camera and scale. Establish exact palette swatches and silhouette landmarks for all six current fighters before adding characters.
- [ ] Complete and approve the reusable character specification across the roster: neutral model sheet, proportions, face, costume landmarks, equipment geometry/handedness, palette, allowed deformation and prohibited drift. The [Fillet/Shark draft](fillet-shark-references.md) supplies the first two model/action sets; use the same specification to onboard future characters.
- [ ] Create a structured action brief and generation template with pose direction, planted foot, root/contact anchors, weapon path, timing, phase and approved references. Save prompt/reference provenance and review decisions with every revision.
- [ ] Revisit authored weapon-only smearing after visual review. Automatic limb/pose stretching was removed on 2026-11-17; do not reintroduce it.
- [ ] Export registered body/weapon material mattes with new sprite sheets and backfill older attack, movement and reaction poses. The native pause renderer has exact stance masks and a conservative legacy fallback; dark handles and pale armor need authored separation for uniform white weapons. Keep these visual masks independent of hurtboxes. See [native ink menus](native-ink-menus.md#weapon-material-regions).
- [ ] Establish the common smear library: tapered crescents, thrust wedges, blunt arcs, smoke lobes. Separate effects from the body; make impact effects depend on contact. Replace inconsistent baked-in effects in the starter sheets.
- [ ] Add a review tool that compares silhouette, palette and landmarks against the master, scrubs adjacent frames, and previews actual in-game size, flipped facing, hitboxes and backgrounds.
- [ ] Automate validated import/packing: transparent margins, no neighboring sprite leakage, stable root/feet pivots, per-frame bounds, versioned manifests, naming, missing-frame checks and reproducible source-to-runtime mapping. Retain source art unchanged.
- [ ] Continue per-move windup/active art beyond the first Fillet/Shark signatures, including crouching, command and airborne normals.
- [ ] Extend each attack to **windup, active, impact, follow-through and recovery** animations after the first two stages are approved. Support multiple drawings per phase and explicit whiff/hit/block paths without changing authoritative combat timing accidentally.
- [ ] Trial the complete workflow on one fighter and a second fighter with a different silhouette; measure drift and revision cost before using it for the rest of the roster or a new character.

## Animation audit follow-ups — 20 November

- [x] Audit eight attacks against the supplied fighting-game animation guide; give Smoke's four approved specials authored follow-through and recovery, with actual hit/block/whiff comparison recordings. See the [audit](attack-animation-audit-2026-11-20.md).
- [ ] Give Smoke f.S distinct gas-pulse drawings for its changing multi-hit path and a held recovery sequence; retain the authored hit groups and timing.
- [ ] Reduce Smoke 2Hs fire occlusion where fighters overlap, while preserving the visible active reach and the approved eruption.

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
- [x] Add medium/large counter impact freezes and deterministic defender-only slowdown, oversized italic combat text and a reduced-motion camera option.
- [x] Refine large callouts into translucent outline lettering, with lighter combo fills and split diagonal accents.
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
- [x] Native keyboard/gamepad remapping, stable controller assignments, stick/trigger thresholds and a live input tester; verify motions, buffered actions and input isolation. See [controls](input-controls.md).
- [x] Local side selection before fighter select: left / neutral / right, independent controller input, swappable keyboard layouts, hot-plug handling and cancelable draft assignments.
- [x] Real fighter loading, two character spotlights, four-beat opening and synchronized online readiness.
- [x] First-to-two Scrums: 1st Scrum, 2nd Scrum, Final Down at 1–1, automatic intermissions, draw replay, win marks and packet isolation between Scrums.
- [ ] Author dedicated intro animation clips and record the announcer once the presentation copy is settled.
- [ ] Add negotiated online match rematches and matchmaking after the direct-connection prototype.
- [ ] Decide stage selection and knockdown/wakeup presentation with the user.

## Combat and delivery

- [x] Fit body-only hurtboxes to all 160 existing sprite poses; weapons and effects add no hurt area.
- [x] Limit each pose to legs, torso-and-arms, head, and one optional extension; enforce the four-hurtbox maximum in authoring and native storage.
- [x] Add per-fighter pushboxes, wall separation, movement sweeps and airborne crossing/landing checks.
- [x] Give the original 132 move slots preliminary stats and sprite-derived attack rectangles; enforce startup floors in core, editor and imports (now 2f grabs / 3f P normals / 5f others).
- [x] Share pose selection between collision and rendering; add live collision colors and all-pose/facing review.
- [ ] Replace shared button collision with per-move, per-animation-frame geometry as dedicated animations are produced; playtest spacing and matchup balance.
- [ ] Playtest the basic P/K/S/Hs/D buttons and unified gatlings, then replace provisional move data and Drive behaviors character by character.
- [ ] Collect repeatable Strive input traces to tune buffer behavior and motion leniency.
- [x] Add universal 2D sweep and 4P+K / 6P+K throws with hard knockdown (now 2f startup).
- [ ] Design universal overheads and universal anti-air rules with the user.
- [ ] Broaden native online testing under real network conditions; add Internet connectivity/matchmaking and resilience after local rollback validation.
- [ ] Validate physical controllers and Windows gameplay; establish the approved PS5 Godot port/tooling path before console delivery.
- [ ] Retain the simulation/presentation boundary for eventual 3D characters constrained to the 2D plane.

## First matchup, recovery and walls

- [x] Focus Fillet/Shark, use numpad notation, and retain the full roster.
- [x] Edit ground/air hit displacement, block pushback, launch, soft/hard down and wakeup timing, wall health and throw range.
- [x] Keep gravity unchanged for the first X hits, then scale per hit to an editable cap.
- [x] Add independent hidden wall health, swept velocity-driven impacts, splat/follow-up break, deterministic transition/neutral reset and timed Momentum Positive Bonus.
- [x] Fill each visible wall border with generated solid scenery across its full vertical and horizontal extent.
- [x] Preserve schema 1–6 move edits and test delayed-input rollback through wall breaks.
- [ ] Tune Fillet/Shark routes, gravity threshold and wall durability through local playtests.
- [ ] Author dedicated windup/active sweep and throw art first, then coherent launch/splat/down/wakeup clips under the existing sprite contract. Prone/hard and supine/soft knockdown/get-up clips are now implemented for all six; launch/splat and remaining action clips are still pending.
- [x] Generate three layered arenas, independent horizontal parallax, left/right passage cutouts and deterministic wall-break travel. See [stage art](stage-art.md).
- [ ] Author dedicated character travel/landing animation, environmental loops and sound for the generated stages.
- [ ] Tune the custom wall-health values and Positive Bonus through playtests. Super-specific break knockdowns wait for super design.

## First signature kits and locomotion

- [x] Generate Fillet knife spiral and upward/mid/low rekka windup/active poses under the shared style contract.
- [x] Implement 236K; 236S > 6S > 2S and the 236S > 2S shortcut, with a low soft-knockdown finisher.
- [x] Generate Shark ground/air hooks and short-blade follow-up pairs; separate the spear weapon from hook-active bodies.
- [x] Implement 214S / j.214P, opposing 45° trajectories, narrow moving hitboxes, body-only hurtboxes, pull and hit-only P follow-ups.
- [x] Add forward runs for most fighters, provisional Anvil step dash, 66/macro inputs and attack velocity carry; expose per-character movement and per-move inertia/travel.
- [x] Extend Sprite review, configuration migration, collision validation and rollback checks for the new kits.
- [ ] Playtest follow-up windows, whiff routes, travel friction, pull distance and hook matchups before locking balance.
- [ ] Author dedicated run/step poses and coherent return/retrieval animation. Current movement reuses walking poses; hook retraction reuses the active body.

### Completed: browser contact preview and attack authoring

- Real combat playback with input-driven approach, hit/block reactions, travel,
  freeze, launch/pull and scaled damage; uses existing art.
- Active-frame hitbox keys, optional multi-hit groups and per-key impact values.
- Prominent attack enable switch for optional command normals and other slots.
- Schema-14 JSON migration, native import/save, rollback and updated control PDF.

- Unified the browser editor and combat preview: one timeline and target scene,
  direct box dragging in both facings, and move-frame preservation after edits.

- Added live workshop distance guides: root spacing, pushbox gap/overlap, attack
  front extent, selected-box size and a facing-relative ground ruler.


## Tapper stance and Leo baseline

- [x] Record the user's rolling-stance direction and 2026-11-18 cancel/input corrections in [Tapper's design specification](tapper-design.md).
- [x] Read the user-supplied Leo MHTML (captured 2026-11-18, revision 581554); preserve its hash, frame tables and move-function mapping in the [source report](research/leo-tapper-2026-11-18.md) and structured reference.
- [x] Map non-stance normals, command normals, aerials and ordinary throws to the verified Leo baseline, distinguishing contextual advantage and the 2f-throw/5f-minimum conflict. Keep Tapper's specials for separate design.
- [x] Implement the verified baseline: close/far Slash selection, held S/Hs guard and armored follow-up, startup travel, two-hit j.S, late low-reaching 5Hs, j.D stall/dive/landing behavior, bounces/crumple, timed low profiles and air throws. Implemented with local scale adaptations; see the current Tapper guide.
- [x] Implement the no-blocking stance, cross-normal cancels, S self-cancel, Hs overhead, low branch and cancelable 2D exit, with editor controls and real preview playback.
- [x] Implement Drive/throw stance entries and the stance command throw: run → tackle → one strong punch → stance offense. Confirmed 236D; recovery, knockdown and spacing remain provisional.
- [x] Generate dedicated windup/active pairs for the normal/stance kit, collar/headbutt and tackle/punch; add normal/rolling idles, walk and finite step dash.
- [ ] Playtest Tapper pressure and throw escapes; refine body fits, impact/follow-through/recovery animation, and his future specials.

## User move authoring batches

- [x] Preserve and validate 2026-11-17 batch 1: 21 edited moves across Fillet and Shark, plus Fillet air-dash tuning. Load as a work-in-progress preset in the editor and native build.
- [x] Add independent per-phase hurtbox region switches and universal 6P upper-body protection, with coordinate preservation and editable recovery coverage.
- [ ] Review Shark 5Hs’s key at active frame 10 (currently beyond 7 active frames) and the S input on the `j.214P` slot with the remaining move edits.
- [x] Preserve and validate 2026-11-17 batch 2: Shark 2D reach/height, Fillet 5D overhead/soft-knockdown tuning, and four named move briefs.
- [x] Implement Shark’s persistent Drive tether and follow-up pull with editable timing, speed and contact rules. See [character mechanic briefs](character-mechanics-drafts.md).
- [x] Implement Fillet’s bleed, refundable grey-life accumulation and leaping command-grab cash-out with editable values and real preview playback.
- [ ] Replace reused Drive follow-up poses with dedicated pull/grab animation after move tuning.
- [ ] Receive the remaining move edits and completed art briefs/references before deriving revised attack sprite sheets.
