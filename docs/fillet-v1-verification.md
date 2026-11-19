# Fillet v1 mechanics and editor verification

Verified 2026-11-19 on `feat/godot-combat-lab`, integrated from
`cd8b0cedabfd508b0d82be2841d640e37928ef91`. This is the mechanics/editor step;
the complete animation package is still in review. See
[implementation and art status](fillet-v1-implementation.md).

## Reproducible inputs

| Input | Identifier |
|---|---|
| Uploaded implementation ZIP SHA-256 | `9f23b24d2bdb70ebdb641a5d75b2f2d91ea9174079e2e2c5cfd6a68aa79548a9` |
| Canonical specification SHA-256 | `796292f71f5af141c91997b983ee223834a0826dbc8d3c7b1b1d7d260445e65d` |
| Current workshop batch SHA-256 | `fa3b022bd32838b13dae908b728a39012afdb2563f8f40968800392bf593c36c` |
| Tested WebAssembly build SHA-256 | `bfd8d029b73a212d5615e5a257045a33a8ad2d63b969559a150daf909ee4a45b` |
| Compiled default tuning fingerprint | `23-0b82d5ff-c3da317e` |
| Current workshop tuning fingerprint | `23-0b82d5ff-c9c7aa10` |
| Schema / shared rules revision | 23 / 2 |

The ZIP is immutable evidence. The current saved batch installs Fillet's selected
kit. An exact comparison with the previous slash/sweep batch confirms that the
other five fighters' existing moves and movement profiles are unchanged; the two
appended slots are disabled for them. Older exports retain their earlier kit.

## Checks executed

| Check | Result |
|---|---|
| Uploaded `tools/validate_package.py` | 13,998 static checks; zero failures |
| `npm test` native executables | 91,600 checks; zero failures, including 387 Fillet runtime checks and 3,576 canonical geometry comparisons |
| `tests/*.test.mjs` | Original 22 tests passed; the added complete-route case and updated real-fingerprint relay test also passed in targeted runs |
| `tests/run_godot_tests.py` | Native bridge, data, combat, migration, training, presentation and menu suites passed; the UI suite was rerun successfully after updating old art-selector expectations and its asynchronous loading deadline |
| `bash scripts/godot.sh --headless --script tests/ui_smoke.gd -- --test --review` | Zero failures, including opening/applying the native kit editor |
| `npm run test:workshop` | All model/browser scripts passed across the initial run and targeted reruns; the added legacy-reset case also passed |
| `npm run test:browser` | Combat, editing, save/export/import, motions, simple inputs, controller mapping, two-client rollback, packaged content and narrow layout passed |
| `node --test tests/network.test.mjs` | Actual current engine fingerprints accepted, mismatches rejected; input relay and rollback passed |
| `git diff --check` | Passed |

The hosted delivery check decoded all 100 artwork sheets and measured a 4.86 MiB
initial fetch. It verified project-subpath URLs, cache headers, active-key dragging,
pose-photo persistence and JSON round trips. Mobile checks cover widths from
320–1440px, touch edits, scrolling, rotation and queued sequences.

The managed local Chromium blocks `file://`. For that specific check, the legacy
standalone content was verified over local HTTP and the editor's direct-file test
was explicitly skipped. The existing GitHub Actions delivery job runs the exact
extracted ZIP in standard Playwright without that local skip.

Two obsolete browser fixtures were corrected: the shipped Fillet jab now edits
an active-frame key, and the older slash/sweep fixture explicitly carries an art
note. The legacy combat client's initial two-fighter selection and network
fingerprint parsing were also repaired; import accepts the larger current saves.

## Complete-route evidence

`tests/fillet-v1.test.mjs` runs Opening → Crown/Heel → Wound using ordinary input
samples against all six receivers, both player indices and both facings: 48
fixtures. It checks natural downed capture, release gap, grey life, duration,
throw grace, no extra health/meter event and snapshot replay through release.
Only the initial positions and meter use setup helpers; the moves are selected
through the normal input resolver.

Running that test writes `build/fillet-v1-review/branch-wound-traces.jsonl.gz`.
The compressed JSONL contains source/build/tuning identifiers, fixture setup,
every input tick, state, resolved hit/hurt/push rectangles and checksum. The
separate c.S → f.S input tests verify hit and block pressure in both roles/facings:
ordinary block 62→68→78px, FD 62→80→110px, normal hit damage 44+32.

These are the executed fixtures, not a claim that every permutation in the
uploaded acceptance document has been exhaustively playtested. Its broader
matchup/corner matrix remains the release checklist alongside the art pass.

## Review and delivery

The native entry remains `bash scripts/godot.sh`; the browser editor is built
with `npm run build:workshop` and served with `npm run start:workshop`. The existing
Pages workflow publishes branch updates to the user's browser link.

Fillet f.S direction **B — Hip-led** is recorded in
`art/characters/fillet-v1/review/`. The generated eight-key studies are review
images, not playable atlas replacements. Precise registration, anatomy, handedness,
both-facing checks, the remaining action choices and paired receiver art are
unfinished. Existing sprites may visibly differ from the new collision poses.
No new playable sprite or manifest entries were installed in this step.
