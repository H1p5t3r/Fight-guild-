# Grounded March and stance travel

Authorization: the user's **“Continue with your judgement”** on 2026-11-24.
Selected Hammer A / Grounded March; Tapper retains his existing Dempsey guard
with short forward/back shuffles, guarded step dashes and stance withdrawals.

48 production drawings: three eight-key Hammer locomotion sheets, eight Tapper
shuffle drawings, eight step-dash drawings and eight stance recovery drawings.
The runtime originals are in `godot/assets/fighters/movement-v1/`; PNG pixels are
unmodified. `sources.json` and `prompts.json` retain checksums, source paths,
references and the explicit correction to Hammer's leg alternation.

Registration uses source regions, fixed anatomy scale, belt landmarks and boot
contact lines. The first two return columns use a custom gutter boundary so the
jab's boot is not clipped into the kick drawing. Airborne step-dash keys retain
the intended clearance above the floor. Near-transparent source-edge RGB is not
treated as visible body silhouette when measuring bounds.

Playback follows resolved travel distance or the saved move/dash clock. New
drawings are presentation-only; the canonical collision atlas, move timings and
native libraries are unchanged. No smears, pose crossfades or interpolated roots.

See `docs/movement-transitions.md` for reproduction, verification and review.
