# Fillet v1 implementation record

Source: `art/characters/fillet-v1/Fillet_Codex_Implementation_v1_0.zip`.
The immutable ZIP and readable canonical files are retained. `source.json` records
hashes and the captured baseline, `cd8b0cedabfd508b0d82be2841d640e37928ef91`.

## Implemented mechanics and authoring

The selected packet installs 26 enabled Fillet actions and disables 21 historical
slots. The new schema is 23, rules revision 2, with 47 stable move slots. 236D and
214D are appended. The current workshop batch preserves the other five fighters'
submitted values and notes, with those two new slots disabled.

- Exact per-frame hurt/push/hit data, four-region anatomy, named routes, horizontal
  and vertical roots, side passage, low crush and late locked-pose inspection.
- Source movement, attack inertia/friction, four-tick air-dash pause/five-tick
  burst, natural coast and owned-bleed speed bonuses.
- Downed-only Wound, 420-tick owned bleed, periodic/block grey life and finite
  Vault/Skim captures. Cashout snapshots grey at capture and pays it once.
- Paired capture roots, individual release recovery, protection, freeze clocks,
  same-tick strike/projectile arbitration, ordinary-throw C1–C6 late tech and
  legacy throw payload preservation. A hit interrupts release recovery; timeout
  discards pending paired damage.
- Shared legal jump priority over ground FD. Legacy saves and the other fighters
  retain their movement/cancel policies. No Just Guard mechanic was added.
- Browser controls, native kit dialog, preview status setups and training readouts.
  Full structured data and art metadata survive save/import/export. Missing,
  unknown and invalid extensions are rejected atomically. A legacy move reset
  uses the legacy kit, avoiding a partial upgrade.

The packet intentionally replaces the previous Fillet rekka: Opening can branch
into Crown or Heel; Crown does not itself route into Heel. Fillet's 2S is a hard
knockdown sweep without special cancels. Her successful ordinary throws now use
the packet's standing release and +2 independent recovery. These are selected
Fillet changes; other fighters retain their authored throw outcomes and sweeps.

Implementation sources: `core/fillet_v1.inc`, `core/extensions.h`,
`core/extension_tables.inc`, `scripts/fillet-v1-data.py`, `web/extensions.mjs`,
`godot/scripts/extension_data.gd`. The JSON extension layout is shared across the
compiler and adapters. Existing tests use an explicit archived Fillet fixture;
the new kit has dedicated tests against the canonical packet and real inputs.

## Verification

- Package validation: 13,998 checks, 26 enabled actions, 894 standalone geometry
  frames, zero failures. This checks the uploaded source independently.
- `tests/fillet_geometry_test.cpp`: 3,576 exact comparisons: every canonical frame,
  both facings and both player slots, including final locked frames.
- `tests/fillet_v1_test.cpp`: paired boundaries, late-tech C1/C6/C7, expired input,
  both roles/facings, Wound, bleed, cashout, timeout, owner cleanup, movement,
  routes, legacy finisher timing and recovery interruption.
- `tests/fillet-v1.test.mjs`: all source scalars and hit keys, metadata, older-save
  preservation, invalid imports, paired snapshot replay, unavailable commands,
  and real c.S → f.S inputs in both roles/facings. Ordinary block spacing is
  62→68→78px, FD is 62→80→110px; normal hit damage is 44+32.
- `godot/tests/fillet_v1_test.gd`: native table/metadata round trip, older-save and
  partial-kit behavior, paired capture and deterministic snapshot replay.
- `tests/workbench-fillet-v1-browser.mjs`: desktop/mobile controls, Wound/cashout
  preview, exact body keys, protection masks, undo and JSON export.

Native, WebAssembly, browser and Godot regression commands are recorded in the
[verification report](fillet-v1-verification.md). The entire acceptance document is retained as the broader
release checklist; this file does not claim its unfinished art matrix is passed.

## Art review and remaining work

The user's later instruction requires the established image-generation and
approval process. This overrides the packet's automatic procedural-art/no-approval
clauses. New character art must be selected and checked before it replaces sprites.
The approved master remains model 06 / A Stalker, black hair, slender arms, short
LEFT knife for c.S and long RIGHT knife for f.S. No transition smears were added.

The user has selected all 11 ground-normal directions: **5P-A, 2P-B, 5K-A,
2K-B, f.S-B, 5Hs-B, 2Hs-B, 6P-B, 6Hs-B**, the packet's short-LEFT **c.S**, and
**2S-B / Hip Reap from the second sweep study**. The original 2S options were
rejected. Motion studies, prompts, provenance and per-action production states
are in [`review/`](../art/characters/fillet-v1/review/README.md). These are selected
directions, not registered gameplay clips. Exact reach, body fit, slender
anatomy, clear handedness, both facings and atlas padding still need production
checks. The user's explicit 6P condition is to keep the red LEFT shoulder/arm
with the SHORT knife and the unarmored RIGHT arm with the LONG knife held back
through every final pose.

No new playable sprite files or sprite-manifest entries are installed by this
mechanics step. Existing art can therefore visibly differ from the new authored
collision poses. Source animation curves/phase keys are preserved as metadata;
complete new pose playback, paired receiver drawings for the cast, all entry/exit
bridges and animation-specific acceptance remain pending the review process.

Next: produce/register the selected ground normals as a consistent set, then
continue the air-normal, special and paired-action motion reviews. Install
checked clips and repeat the game-size/collision review. Do not mark the complete
Fillet art package finished until that work passes.
