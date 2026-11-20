# Combat lab architecture

## Native Godot runtime

`core/fight.h` and `core/fight.cpp` implement an engine-independent C++17 simulation. Each `fight::Simulation` owns its state, six fighters' move definitions and movement profiles, plus input/Momentum/recovery rules. Each step advances one 60 Hz tick using fixed-size structures and integer arithmetic. The core does not use engine objects, heap allocation, clocks, physics, rendering or network calls.

`native/fight_extension.cpp` exposes independent simulations as Godot `FightCore` objects through GDExtension. The minimal godot-cpp build is pinned to the 4.5 stable revision `e83fd0904c13356ed1d4c3d09f8bb9132bdc6b77` and verified with Godot 4.6.3. Linux and Windows x86-64 libraries compile the same core. Editor/debug builds use template-debug extensions; release exports use separately compiled template-release extensions. Matching targets matters: these godot-cpp bindings use different allocator padding in debug and release engines.

Godot's `CombatModel` wraps data validation and persistence. `main.gd` owns activity/screen state, input, training, move editing and scheduling. `GameMenus` renders home, match choice, fighter selection, connection, pause and results pages. Offline simulation only advances on the play screen; online sessions keep ticking with neutral input behind menus. Held confirmation inputs must be released before combat accepts input. Online results inspect a fully confirmed rollback snapshot before committing to a winner screen. Menu navigation preserves applied move data. See [menu flow](menu-flow.md). `arena.gd`, `FighterArt` and `FighterPreview` present generated PNG regions. `CombatFeedback` draws large background combo numerals and counter/punish/reversal notices before the HUD and fighter sprites. It consumes restored state clocks, never wall time, and follows the attacker's current side. These presentation classes do not decide hits or movement. Physics processing schedules fixed ticks; Godot collision physics is not authoritative.

State includes position, velocity, facing, health, move age, contact/hit flags, dash/stun state, Momentum, FD status, movement gain remainder, block reaction/age/advantage, guard break, counter/punish notices, reversal timing, combo display clocks, previous input and 64 history samples per player. Recovery state additionally stores air reel, knockdown/wakeup timing, received-hit count, remaining knockback travel, wall splat, and Positive Bonus. Global state stores independent left/right wall health, wall-break actor/side/progress, captured departure positions and ground index. These all roll back together. Snapshots copy all of `State`, including consumed presses. Configuration stays immutable during a network match. The local 32-bit integer snapshot ABI is not a network serialization format. Configuration schema/core version is 14; version-1/2/3/4/5 files preserve edits while adding defensive fields/Momentum rates/hit-timing fields, the explicit hitbox back offset and any missing fighters. Startup below 5f rejects an import atomically. The C ABI/default instance remains for native tests and the archived WebAssembly harness.

## Rollback and direct connections

`RollbackSession` records state before each frame, inputs used and resulting checksum. Unknown remote input holds its previous value. When late input differs, the session restores and replays through the core. Press edges are reconstructed from restored history. It retains 240 frames, permits 12 predicted frames and stalls when prediction exceeds the confirmed input horizon.

`NativePeer` uses Godot ENet over UDP with reliable input messages and two frames of input delay. Hello negotiation compares versioned move-data and compiled-collision fingerprints; both peers must complete the handshake. Each supplies their fighter/simple-input choice. Actual input is immutable once received. Checksums compare only completely confirmed input prefixes. Divergence, conflicting input or exhausted history ends the session. Reliable delivery can still cause stalls during loss and requires real-network measurement before production tuning.

No browser relay is involved. Direct host/join requires a reachable address/UDP port. Authentication, matchmaking, NAT traversal, reconnect, spectators, platform services and production resilience remain future work. The data fingerprint checks compatibility, not authentication.

## Move data and art

Each of six fighters has 32 stable slots: 25 base definitions and seven optional signature slots. Disabled slots cannot be requested or canceled into. Fields describe buttons/categories, motions/directions, ground/air eligibility, timing, damage, stun, hitstop, advance, rectangular hitboxes, cancels, guard levels, chip damage, guard break and simple mappings. Slot IDs such as `236P` do not change when inputs are remapped. Slot-layout changes need a schema change. Imports validate a complete candidate configuration before committing it atomically.

Unified gatlings live in one C++ predicate. `normalRoutes` and `commandRoutes` use -1 for shared defaults or a five-button override mask. Every attack's same-button command-normal route precedes those overrides; self/whiff restrictions still apply. Special and jump cancels have explicit flags.

Art regions, foot pivots and body scale are recorded in `godot/assets/fighters/manifest.json`. Windups display before the first active tick; active poses display during active ticks and their hitstop. Recovery currently returns to a ready pose while gameplay recovery continues. Slots without a dedicated signature pose temporarily reuse button artwork. Fillet/Shark signatures have four windup/active pairs each; Shark’s detached spear reads core weapon endpoints. The C++ core selects poses from current state for both hurtboxes and sprite rendering, so rollback corrects them automatically. Block clips select stable/pressure/broken poses from actual contact advantage and the guard-break flag. Their two frames advance after four unfrozen blockstun ticks; all selection state is restored with rollback. The throw resolver and `throwInvulnerable` getter share one eligibility check; guard break removes blockstun protection. Image pixels never enter state hashes. Authored collision rectangles compile through the same art pivots/scale into integer tables; their hash enters the configuration fingerprint. [Sprite production](sprite-production.md) defines the planned consistency pipeline and five-stage animation contract.

`godot/data/fighter_collision.json` contains 160 sets of body rectangles and six push profiles. `starter_moves.json` contains 192 slots (157 enabled) and six movement profiles. `scripts/generate-combat-data.py` validates and compiles them into `core/combat_data.h` and a frame-data reference. The native core supplies world-space hit/hurt/push/wall rectangles to overlays, and local pose rectangles to Sprite review. Movement sweeps retain horizontal order while pushboxes overlap vertically; airborne clearance permits crossing, and wall/landing resolution removes penetration. See [collision authoring and rules](collision-rules.md).

## PC, PS5 and future 3D

Godot is the current engine. PC packages use its compatibility renderer. The future 3D presentation should also read simulation state: models, animation, cameras and effects must not drive authoritative movement or hits. The integer combat plane can remain unchanged.

PS5 requires Sony approval/SDK access and compatible console port tooling, typically through a licensed Godot console provider. This repository contains no PS5 SDK or export. Validate determinism on the console compiler and measure rollback budgets on hardware before production delivery.

## Verification

`bash scripts/test-godot.sh` checks combat rules, all six fighters' basic buttons, Momentum/FD/guard-break rules, counter/punish/reversal boundaries and combo lifetime, exact 1,200-frame native/Godot parity, save migration and atomic imports, delayed/jittered rollback, artwork metadata/alpha, actual keyboard UI paths, keyboard/simulated-controller menu navigation, offline pause/rematch and local ENet menu handshake/cancel/disconnect recovery, windup-to-active switching for 30 basic buttons, both frames of all 18 defensive clips, visible feedback restoration and a real combo after a side-switch, sprite review and two separate ENet processes selecting Shark/Fillet. Script errors fail the runner even if Godot exits zero. Native screenshots validate rendering and layout.

The archived browser harness remains useful for native/WebAssembly determinism and relay regression tests via `npm test`. It is no longer the primary gameplay client. Windows export validation does not replace Windows hardware playtesting.

## Native match orchestration

`MatchScore` counts first-to-two wins outside the per-frame combat snapshot. Offline outcomes commit once; online outcomes commit only from a fully confirmed rollback state. `MatchEntry` prepares atlas resources, presents fighter introductions and the four opening beats, and freezes the combat clock until release. Practice resets bypass the ceremony.

Native ENet protocol 4 gates intros, countdown and intermission with readiness from both peers. Each new Scrum resets combat into a fresh rollback session and increments a packet generation; old-generation inputs and hashes are discarded. The host verifies the remote outcome and the client verifies the next-Scrum score. A draw retains the score/call and uses a fresh generation. The results menu appears only after two wins; online match rematches still return through the lobby.

Schema 6 appends universal sweep and two throw slots, separate airborne/block displacement, ground/air launch, knockdown/wakeup, wall damage and throw reach. Recovery rules serialize after input and Momentum rules. Older saves gain these fields/slots without erasing edits. Wall transitions run entirely inside the fixed-tick core and consume input during the freeze; the Godot renderer only draws their restored progress. See [recovery and walls](recovery-and-walls.md).

Schema 7 packs moves, then six nine-field movement profiles, then the existing 26 global rules. Horizontal velocity, running/step state, pull owner/time/gap, and all input history live in the rollback snapshot. The core supplies both spear endpoints and its eight moving diagonal hit rectangles. Godot’s `HookWeapon` only draws the weapon/tether. Follow-up source IDs, unblocked-hit requirements, inertia and travel are move fields. See [signature moves](signature-moves.md).

## Combat tuning and training capture

Schema 10 extends the packed layout to 69 move fields and 38 global rules, retaining the six nine-field movement profiles. Per-fighter slowdown phase/remaining ticks, counter cinematic clocks/focus, prejump, landing and throw-grace timers, starter/remaining damage scale, repeated-move counts and counter/diagnostic values are authoritative integer snapshot state. The Godot training lab records both raw inputs and a starting snapshot, checks the configuration fingerprint before playback, and compares the final checksum for full replays. The timeline derives presentation from state; it never drives combat. See [combat tuning](combat-tuning.md) and [training controls](training-lab.md).

## Editable attack hurtboxes (schema 13)

Each move can override windup, active and recovery independently with three required body rectangles and one optional extension. Missing phases inherit the compiled sprite pose; moves sharing artwork remain independent. The fixed configuration layout appends 6 × 32 × 3 records of 17 integers (count plus four rectangles) after movement profiles and before hitbox timelines/global rules. Imports validate a complete candidate before applying it. Configured rectangles are canonical integer coordinates relative to the fighter, mirrored by facing, and apply to actual hit detection and runtime overlays. No additional hurtbox data is needed in snapshots: the profile is immutable during a match, and phase selection derives from restored move age. Profiles participate in the move-data fingerprint; mismatched peers cannot start. Version-1–12 saves retain inherited body poses.

## Active-frame hitboxes and browser combat preview (schema 14)

Each move has a fixed `MoveHit` sidecar: a multi-hit flag and up to 32 ordered
keys. A key stores an active-relative start frame, hit group 1–32, four optional
damage/stun/hitstop overrides, and up to four rectangles. Inherited geometry
uses count −1; a collision gap uses count 0. Keys hold until the next key. Before
the first key the ordinary shape and hit group 1 apply. Without multi-hit enabled,
all keys share the existing one-contact rule. With it enabled, a 32-bit consumed
group mask allows one contact per hit group per move execution; the mask is part
of rollback state. Multiple overlapping boxes never multiply a contact. Throws
keep their separate single-hit resolver. Version-1–13 migrations retain ordinary
one-hit behavior.

Packed configuration appends 192 records of 738 integers after the hurtbox
sidecar and before the 38 global rules. It is fingerprinted and validated
atomically by both adapters. Snapshot version 14 includes the hit-group mask.

The standalone workshop translates the same WebAssembly build to ordinary
JavaScript with pinned Binaryen, then embeds independent core instances. There
is no WebAssembly runtime or network dependency in the downloaded editor. Its
preview enters approach and command inputs, records collision/reaction states,
and replays them with existing sprites. Explicit authoring helpers place the
fighters and start contextual follow-ups in isolation; the UI labels those
follow-ups as isolated tests. JS/WASM parity and native JSON-import tests protect
the shared behavior and portable data.

The workshop has one combat scene and timeline. Paused box handles transform
through the attacker’s world position and facing. Drags freeze the current
scene transform; on release, the core records the edited exchange and resolves
the saved move-frame cursor into its new elapsed tick, preserving hitstop
position where possible. Disabled or unmapped moves use labelled geometry-only
frames in the same scene, without executing or fabricating contacts.
