# Combat lab architecture

## Native Godot runtime

`core/fight.h` and `core/fight.cpp` implement an engine-independent C++17 simulation. Each `fight::Simulation` owns its state, six fighters' move definitions and input rules. Each step advances one 60 Hz tick using fixed-size structures and integer arithmetic. The core does not use engine objects, heap allocation, clocks, physics, rendering or network calls.

`native/fight_extension.cpp` exposes independent simulations as Godot `FightCore` objects through GDExtension. The minimal godot-cpp build is pinned to the 4.5 stable revision `e83fd0904c13356ed1d4c3d09f8bb9132bdc6b77` and verified with Godot 4.6.3. Linux and Windows x86-64 libraries compile the same core. Editor/debug builds use template-debug extensions; release exports use separately compiled template-release extensions. Matching targets matters: these godot-cpp bindings use different allocator padding in debug and release engines.

Godot's `CombatModel` wraps data validation and persistence. `main.gd` handles input, training, selection, move editing and scheduling. `arena.gd`, `FighterArt` and `FighterPreview` present generated PNG regions. They do not decide hits or movement. Physics processing schedules fixed ticks; Godot collision physics is not authoritative.

State includes position, velocity, facing, health, move age, contact/hit flags, dash/stun state, previous input and 64 history samples per player. Snapshots copy all of `State`, including consumed presses. Configuration stays immutable during a network match. The local 32-bit integer snapshot ABI is not a network serialization format. Configuration schema/core version is 2; version-1 files migrate the first two fighters into the six-character configuration. The C ABI/default instance remains for native tests and the archived WebAssembly harness.

## Rollback and direct connections

`RollbackSession` records state before each frame, inputs used and resulting checksum. Unknown remote input holds its previous value. When late input differs, the session restores and replays through the core. Press edges are reconstructed from restored history. It retains 240 frames, permits 12 predicted frames and stalls when prediction exceeds the confirmed input horizon.

`NativePeer` uses Godot ENet over UDP with reliable input messages and two frames of input delay. Hello negotiation compares versioned move-data fingerprints; both peers must complete the handshake. Each supplies their fighter/simple-input choice. Actual input is immutable once received. Checksums compare only completely confirmed input prefixes. Divergence, conflicting input or exhausted history ends the session. Reliable delivery can still cause stalls during loss and requires real-network measurement before production tuning.

No browser relay is involved. Direct host/join requires a reachable address/UDP port. Authentication, matchmaking, NAT traversal, reconnect, spectators, platform services and production resilience remain future work. The data fingerprint checks compatibility, not authentication.

## Move data and art

Each of six fighters has 22 stable provisional move slots. Fields describe buttons/categories, motions/directions, ground/air eligibility, timing, damage, stun, hitstop, advance, rectangular hitboxes, cancels, guard levels and simple mappings. Slot IDs such as `236P` do not change when inputs are remapped. Slot-layout changes need a schema change. Imports validate a complete candidate configuration before committing it atomically.

Unified gatlings live in one C++ predicate. `normalRoutes` and `commandRoutes` use -1 for shared defaults or a five-button override mask. Every attack's same-button command-normal route precedes those overrides; self/whiff restrictions still apply. Special and jump cancels have explicit flags.

Art regions, foot pivots and body scale are recorded in `godot/assets/fighters/manifest.json`. Windups display before the first active tick; active poses display during active ticks and their hitstop. Recovery currently returns to a ready pose while gameplay recovery continues. Crouching, command, special and air slots temporarily reuse button artwork. Pose changes derive from current state, so rollback corrects them automatically. Art never enters simulation hashes. [Sprite production](sprite-production.md) defines the planned consistency pipeline and five-stage animation contract.

## PC, PS5 and future 3D

Godot is the current engine. PC packages use its compatibility renderer. The future 3D presentation should also read simulation state: models, animation, cameras and effects must not drive authoritative movement or hits. The integer combat plane can remain unchanged.

PS5 requires Sony approval/SDK access and compatible console port tooling, typically through a licensed Godot console provider. This repository contains no PS5 SDK or export. Validate determinism on the console compiler and measure rollback budgets on hardware before production delivery.

## Verification

`bash scripts/test-godot.sh` checks combat rules, all six fighters' basic buttons, exact 1,200-frame native/Godot parity, save migration and atomic imports, delayed/jittered rollback, artwork metadata/alpha, actual keyboard UI paths, windup-to-active switching for 30 basic buttons, sprite review and two separate ENet processes selecting Shark/Fillet. Script errors fail the runner even if Godot exits zero. Native screenshots validate rendering and layout.

The archived browser harness remains useful for native/WebAssembly determinism and relay regression tests via `npm test`. It is no longer the primary gameplay client. Windows export validation does not replace Windows hardware playtesting.
