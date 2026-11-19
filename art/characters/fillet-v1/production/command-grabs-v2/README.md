# Fillet — command grab animation replacement

This pass replaces the owner art for **236D / Vault** and **214D / Skim** using
the previously authorized implementation-pack choreography and the held-pose
[animation standard](../../../../../docs/attack-animation-standard.md).

Each move has its own twelve-drawing generated atlas. The hop collects its
landing legs; the slide collects a trailing foot into a fully standing latch.
Both keep the long knife in the anatomical right hand and the short knife in
the anatomical left. The left forearm braces the receiver while the right knife
performs a compact draw-cut. A smaller left accent precedes the release.

| Clock | Drawing / event |
|---|---|
| Final startup, frame 21 | Loaded approach; no extended capture arm |
| First active, frame 22 | Largest capture-arm change; grounded left latch |
| Capture C0, six-frame freeze | Exact same drawing and registration as first active |
| C1–4 | Distinct landing collection or trailing-foot collection |
| C5–8 | Left brace |
| C9–12 | Torso coil / right knife loaded |
| C13–16 | Long-right draw-cut accent |
| C17–20 | Smaller short-left accent; forearm remains closed |
| C21 | Release contact; begin collecting knives |
| C23 | Smaller withdrawal |
| C25–27 | Settle toward Stalker |
| C28 | Existing single damage event and release freeze |

The finite whiff uses the unsupported latch and staged withdrawal. It never
plays the successful cut. Gameplay stays **22/2/30**, capture/release freeze
**6/8**, pair duration **28**, damage **55 + saved grey**, recovery **16/18**,
and final spacing **170px**. Receiver art remains the existing roster reactions;
the paired roots, freeze, damage, collisions and rollback clocks are unchanged.

`sources.json` records final generated PNGs, their hashes, prompts and atlas
calibration. Originals are preserved. Registration changes metadata only; it
does not repaint, stretch or blend body pixels. `paired-plans.json` binds the
drawings to saved capture ticks. `before.json` preserves the immediately prior
build (commit `6f46a36`) for an honest before/after review.

Rebuild with `python3 scripts/register-fillet-kit.py`, then the normal combat,
Godot and Workshop build scripts. Record the finished clips with
`node scripts/capture-fillet-command-grabs.mjs`. The browser review opens
directly on a grab using `fillet-motion-review.html?move=236D` or `?move=214D`.

The 60 fps video is the game-speed reference; the half-speed recording duplicates
each simulation tick and adds no interpolated drawings.

- [Game-speed before/after](previews/Fillet-Command-Grabs-60fps.mp4)
- [Half-speed before/after](previews/Fillet-Command-Grabs-Half-Speed.mp4)
- [Capture manifest](previews/capture.json)

Validated with the native Fillet runtime suite, all ten attack-animation tests,
the Godot art catalog and the hosted browser review. The grab tests check both
facings, matching first-active/C0 pixels, the six-frame capture hold, real knife
accent ticks, release damage, final gap and snapshot replay. The browser review
compares every recorded movement/damage/freeze value to the prior build.
