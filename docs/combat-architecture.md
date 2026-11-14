# Combat lab architecture

## Runtime boundary

`core/fight.h` and `core/fight.cpp` contain the combat simulation. It uses fixed-size structures and integer arithmetic, no engine objects, heap allocation, clocks, randomness, physics engine, rendering, or network calls. One `step(input0, input1)` advances one 60 Hz simulation tick. Native tests compile with a C++17 compiler; the browser compiles exactly the same source to freestanding WebAssembly with Zig 0.14.1. The module has no imports or runtime glue dependency.

`web/engine.mjs` wraps the C ABI. `web/app.mjs` owns keyboard/gamepad sampling, rendering, UI, and editor persistence. `web/rollback.mjs` owns transport-independent input prediction and resimulation. `scripts/server.mjs` serves the files and relays room messages. The server does not determine combat results.

The simulation stores position, velocity, facing, health, move age, contact/hit flags, dash/stun state, prior input, and 64 input-history samples for both players. Move definitions and input rules are immutable during a match and separate from snapshots. The local snapshot copies all of `State`, including input histories and press consumption. Visual effects are derived from current state and do not affect combat.

The snapshot ABI uses 32-bit integers on little-endian native/Wasm targets. It is a local in-process format, not a network serialization format. Its version must change when layout or simulation contract changes. There is one world per native process or WebAssembly instance; a multi-match native host should wrap this in a per-match owner before integration.

## Rollback and rooms

Each frame records state before stepping, the two inputs used, and the resulting checksum. Unknown input predicts the previous input. When late input differs, restore the preceding state and replay subsequent frames through the same core. Press edges are reconstructed from restored history, so held buttons do not become repeated new attacks.

The default session retains 240 frames, permits at most 12 frames of prediction, and stalls when the confirmed input horizon is exceeded. Network matches use two frames of input delay. Actual input is immutable once received; conflicting packets, invalid input, and packets outside history stop the session. Out-of-order packets within history are supported. Checksums are compared only for frames whose entire input prefix is confirmed.

Room negotiation checks a versioned move-data fingerprint and exchanges fighter/simple-input choices. The fingerprint is a compatibility check, not authentication. Confirmed hashes detect divergent execution. Transport is WebSocket/TCP, useful for prototype validation and LAN iteration but susceptible to head-of-line blocking. There is no production matchmaking, account system, anti-cheat, reconnect, spectator mode, or platform network integration. Real Internet conditions and physical gamepad hardware still need playtesting.

## Move-data model

Two provisional characters have 22 move slots each. Numeric fields cover button/category, direction/motion, ground/air state, timing, damage/stun/hitstop, movement, rectangular hitboxes, cancels, guard level, and simple mappings. Slots have stable IDs for this version; adding/removing slots requires a schema change. IDs such as `236P` identify slots, so remapping does not rename the ID.

Unified gatlings live in one C++ predicate. `normalRoutes` and `commandRoutes` use −1 for the shared default or a five-button mask for an override. The universal same-button command-normal route precedes those overrides; self/whiff restrictions still apply. Special and jump cancels have explicit flags.

## Unreal and platform path

Unreal was recommended for the eventual PC/PS5 game, but it is not installed in the current cloud image. This iteration delivers a playable browser harness and portable native simulation. There is no Unreal project or PS5 build yet.

The next engine adapter should compile the same C++ core into an Unreal module, sample platform input into the same bitmasks, and feed a fixed-tick scheduler. Actor transforms, sprites, animation, cameras, audio, and effects should read simulation state. They must not drive authoritative hit detection or movement. Replace the browser renderer without translating combat rules into Blueprints. A later 3D model adapter should use the same state and data.

Before console work, obtain Sony developer/SDK access and Unreal console tooling. Validate determinism on the actual compiler/platform, introduce versioned protocol/build identifiers, replace the prototype relay with the chosen production transport, and measure rollback budgets on target hardware.

## Verification and next iteration

Native checks exercise cancel policy, motion input, simple mode, hit/block/trade resolution, buffering, jump cancels, movement, KO, and replay. JavaScript tests compare a 1,200-frame native/Wasm trace, test latency/jitter correction and prediction bounds, validate atomic imports, and connect clients through the relay. Browser checks exercise gameplay, editing, persistence, controls, both room clients, the standalone artifact, and a narrow layout.

Next priorities are playtesting button feel and unified routes, measuring Strive input behavior against traces, designing character-specific Drive mechanics, and improving animation feedback. Production content, air-combat rules, throws/overheads/anti-airs, round/match flow, and console delivery remain separate milestones.
