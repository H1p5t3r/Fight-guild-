# Implement Fillet v1.0 completely

Implement this entire Fillet package in the current Fight Guild project, run its acceptance checks, and deliver a playable result. The user has delegated the remaining design and production decisions. **Do not pause for move, balance, pose, animation or system approval.** Complete mechanics, data migration, exact collision, presentation and usable training/Workshop support together. Resolve routine implementation details autonomously and report the finished result and any material deviations.

This package is a selected authoring specification, **not an import-ready schema-22 Workshop save and not an already implemented game build**. Its viewers are reference tools. Your deliverable is the functioning character in the game, with complete deterministic animation; a static sheet, data import or engine scaffold alone does not complete the assignment.

## 1. Start from the current project, preserving newer work

The reconciled baseline is `feat/godot-combat-lab` at **`cd8b0cedabfd508b0d82be2841d640e37928ef91`**. Its current saved batch is `2026-11-19-slash-sweeps/FightGuild-Slash-Sweeps.json`, SHA-256 `694db863a698510ddbedb8fb2ffc1ac20d7c9809be5994da36b503f2b1801510`. Read `baseline/current_source/` and `baseline/Current_Workshop_Batch.json` for the captured behavior, then reconcile the actual working branch/HEAD before modifying it. Preserve subsequent upstream changes and user work; do not reset the repository to this snapshot.

The baseline already implements **contextual c.S→f.S selection and the all-cast 2S sweep migration**. Extend those systems. Do not create a second Slash dispatcher, restore the obsolete pre-migration rules, or replace another character with this package's historical snapshot.

The `baseline/` directory is read-only evidence and a reproducible probe input. Do not overlay its source files onto a newer working repository.

Replace Fillet's selected tuning and art integration. Preserve the latest Anvil, Hammer, Smoke, Tapper and Shark move data, artwork and character policies except for the explicitly declared shared systems below. **Hammer redesign, supers and Roman Cancel are outside this assignment.** Do not implement them or leave Fillet waiting for them.

## 2. Read the package in this authority order

| File | Responsibility |
|---|---|
| `FILLET_SPEC.json` | Authoritative selected numeric values, geometry, routes, mechanics and behavior. Zero and empty lists are intentional values. |
| `ENGINE_IMPLEMENTATION.md` | Integration semantics: state/tick order, collision, capture eligibility, clocks, migration, shared rules and cross-runtime parity. |
| `ANIMATION_AND_ART.md` | Complete directed deterministic clips, support-foot transfers, all paired choreography, anatomical ownership, rig/manifest integration and playable fallback. |
| `ACCEPTANCE_TESTS.md` | Observable completion cases to implement, execute and repair. |
| `ALL_MOVES.md` | Generated human-readable view of the final action data; regenerate when its source changes. |
| `FRAME_GEOMETRY.jsonl`, `FRAME_VIEWER.html`, `ACTION_ATLAS.html` | Derived exact-frame geometry and inspection tools, not independent gameplay sources or finished sprite animation. |
| `CS_GEOMETRY_RESOLUTION.json/.md`, `CS_REGISTERED_ACTIVE_GUIDE.svg` | Registered c.S rig, fixed weapon geometry, complete limb path and explanation of the selected short-LEFT motion. |
| `MOVEMENT_ANIMATION.json` | Extracted copy of the canonical movement/reaction/pair contract; keep synchronized with `FILLET_SPEC.json`. |
| `FINAL_MOVE_VALUES.json` | Complete scalar matrix, including disabled records; preserve its field ordering. |
| `PROPERTY_REFERENCE.json`, `BASELINE_GLOBAL_RULES.json` | Field semantics, controlling conditions and captured shared-rule values. Inactive compatibility fields do not create mechanics. |
| `VISUAL_REFERENCE_INDEX.md` and `references/` | Reference provenance and motion/identity direction. Donor images and overview art never override exact engine geometry. |
| `BALANCE_AND_ROUTES.md` | Selected tuning rationale and comparisons with the installed cast; not a claim of completed playtesting. |
| `VALIDATION.json`, `CURRENT_CORE_CHECKS.md`, `PACKAGE_CHECKS.json` | Results and precise limits of checks already executed while preparing the package. New engine acceptance still belongs to your implementation. |
| `MANIFEST.json` | File inventory and SHA-256 integrity hashes. |

If a generated view disagrees with canonical data, fix the generator/view and regenerate. Do not choose whichever duplicate is easiest to import or silently discard an unsupported extension. Use the supplied derived-data tooling where applicable.

## 3. Install the complete inventory and behavior

The selected inventory is **47 stable slots, 26 enabled actions, 21 disabled actions, 138 scalar fields per record, and 894 standalone action-frame geometry records**. Those 894 records cover ordinary/whiff action timelines; pair, locomotion and reaction clocks are specified separately.

- **15 normals:** `5P`, `5K`, `c.S`, `5S` displayed f.S, `5Hs`, `2P`, `2K`, `2S`, `2Hs`, `6P`, `6Hs`, `j.P`, `j.K`, `j.S`, `j.Hs`.
- **6 specials:** `236P`, `236S`, `236S>6S`, `236S>2S`, `236K`, `623Hs`.
- **2 ordinary throws:** `4P+K`, `6P+K`.
- **3 Drive actions:** `5D` Wound, `236D` Vault cashout, `214D` Skim cashout.

Keep existing indices; append the two cashouts at slots 45/46 unless newer upstream data has already allocated them, in which case migrate by stable ID into the next free slots. Other fighters receive disabled appended records. Fillet's old normal `2D` is disabled; `2S` is her sweep. Do not infer a 2K→2S gatling or enable dormant stance/air-throw/charge actions.

Implement the full pressure→knockdown→Wound→bleed→cashout loop. Wound is a standalone 24/2/20 attempt, Downed-only on its two active ticks, with no cancel entry. Success replaces the remaining action with capture freeze 4 and a 20-tick pair; release deals no damage, applies bleed, and returns both standing at +0 and a 120px gap. Eligibility follows actual timing/geometry, not a source-move whitelist.

Owned bleed lasts 420 unfrozen combat ticks, begins with 20 grey, grows by 3 every 30 ticks, and gains `floor(base damage × 20%)` on ordinary block. FD adds zero grey; ordinary hits add no extra grey and never refresh duration. Keep the cap/health clamp, expiry-before-action order, owner-hit cleanup and all reset rules. It grants the selected movement bonuses and cashout access, not faster attacks.

Both cashouts are finite 22/2/30 attempts, with distinct hop/low-profile approaches, protection ending after frame 21 and fully standing capture on 22–23. Latch failure from acceptance when the target is already airborne/prejump, and on a later accepted jump/airborne transition. No air catch, pursuit, landing recapture or strike fallback. Confirmed capture snapshots/consumes bleed and enters the 28-tick pair; release deals 55 plus saved grey once, followed by 16/18 recovery at a 170px gap. Ordinary throws instead deal 45, retain sides or exchange by their authored track, and end standing with 12/14 recovery at 120px. They do not create Wound access.

Implement named cancels exactly. A permitted bleed-grab cancel additionally requires owned bleed, contact, its listed window and five subsequent completed attacker action ticks since contact. No freeze ticks count toward that gate. No normal throw cancel or Wound cancel exists.

## 4. Implement the declared shared changes and migration

Keep the five-world-tick button buffer. Process a fresh/still-buffered **legal Up before grounded FD**, without inventing held-Up autojump or bypassing action locks; FD must not consume Up merely because its chord was requested. Implement the six-unfrozen-tick **late ordinary ground-throw tech** and the documented adapter preserving other characters' existing throw payloads. Commands, air throws and stance throws do not inherit a late-tech window.

Collect strike/projectile/capture candidates before committing a pair. A legal connecting strike/projectile defeats entry to the pair; two simultaneous legal ground captures use the symmetric break without damage or bleed consumption. Preserve final protected ticks even when control has decremented a timer to zero. Apply pair release health/status once and discard pending events at round termination.

Version the extended format, compiler, saves, snapshots and network fingerprints together. Starting from captured version 22/rules revision 1, use 23/2 or the next unused versions if upstream advanced. Preserve old saves through explicit migration; installing this package is a complete Fillet override, not a mixture of new scalars and old collision/status logic. Include all new tables/state in hashes and rollback. Update native C++, Godot, WASM/browser, Workshop and all array bounds consistently.

## 5. Finish the entire animation set in the same pass

Author all 26 actions, 24 base locomotion/defense clips plus the interruptible four-tick stop-settle overlay, five paired owner/receiver guides, and the tech branch. Include whiff recovery, actual last-locked poses, both facings and every geometry-boundary key. Use the selected broad Stalker standing anatomy, real incoming support foot and existing startup to collect the free foot; no snapping into a narrow stance, extra root lunge or animation delay.

Short anatomical **LEFT** performs the reverse-grip rising c.S; long **RIGHT** stays low/ready and performs f.S. Keep fixed rig/weapon lengths, grip, mature anatomy and material identity. Crown/Heel share standing load on local frames 1–5 and diverge at 6. Skim is low only on 6–21 and stands from 22 through recovery. Action clocks, hitstop, counter slow, landing and paired releases determine presentation; render time cannot override them.

Use the existing rig/assets where available. Otherwise create the specified deterministic procedural rig and **complete matching production poses for every state now**. Missing polished raster frames select those exact poses, not generic slash/idle placeholders. Bake/register them or provide equivalent deterministic native/browser presentation. Raster polish must not block the playable character. Reference sheets remain motion guides; registered geometry and the selected rig are the authority.

## 6. Verify, repair and deliver

Execute `ACCEPTANCE_TESTS.md` and the current project's build/test commands. The captured project exposes `npm test`, `npm run test:browser`, `npm run build:workshop` and `npm run test:workshop`; inspect current scripts and run applicable Godot/native checks too. Add focused state/replay tests for the new systems. Repair failures rather than stopping with a checklist for the user.

For package integrity, run `python3 tools/validate_package.py` and `node tools/validate_viewer.cjs` from the extracted package. `python3 tools/build_derived.py` regenerates the move book, frame records, viewer and geometry atlas after an intentional canonical-data change. These tools do not implement game features or replace the in-engine acceptance pass. Parse the large JSON files programmatically when extracting subsets; every final field is explicit.

Deliver Fillet selectable in the normal playable build/review entry point, with accurate move labels/routes, training reset, exact frame stepping, hit/hurt/push overlays and all new states inspectable. Confirm both facings, both corners, each receiver profile, FD/jump/grace boundaries, captures/tech, input/save round trips and native/browser/rollback parity. Include an unchanged-other-cast data comparison covering the latest upstream batch.

Report the final commit, schema/rules versions, authoritative hashes, build entry point, tests run/results, compact animation/collision evidence and any remaining external blocker. Distinguish an actual external blocker from routine implementation work, and complete everything independently available. **Return the complete playable implementation for the user's review; do not request another design or pose approval first.**
