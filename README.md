# Fight Guild

A native **Godot 4.6.3** fighting-game lab for iterating toward a PC/PS5 game. The PC build includes **Anvil, Hammer, Smoke, Tapper, Shark and Fillet**, generated sprites, all five basic **P / K / S / Hs / D** buttons, unified gatlings, a move editor, Momentum/Faultless Defense, two supers per fighter, counter/punish/reversal feedback and experimental direct rollback multiplayer.

Watch the [all-six-fighter combo showcase](exports/FightGuild-Combo-Showcase-2026-11-25.mp4): twelve verified routes, full-speed footage, half-speed replays and fighter themes. The [route guide and individual videos](docs/combo-showcase-2026-11-25.md) include inputs, damage, setup conditions and reproduction instructions. Anvil's revised animations use magma-orange shield effects, consistent anatomical scale and front/behind grab choreography.

Each fighter has matching **windup and active** pose studies plus movement poses and three two-frame block reactions. Open **Development → Sprite review** to compare actions at the same scale. These are provisional kits and images. The [sprite production contract](docs/sprite-production.md) and [backlog](docs/backlog.md) cover consistent palettes, silhouettes, smear shapes, future characters and eventual windup → active → impact → follow-through → recovery sequences.

**Fillet versus Shark** is the default matchup. Recovery editing includes independent grounded/airborne knockback, block pushback, launch and soft/hard knockdown. Universal **2D** sweep and **4P+K / 6P+K** throws cause hard knockdown. Combo gravity begins after five hits by default; Velocity-driven wall impacts deplete independent hidden wall pools; the next impact splats, a follow-up breaks the wall, and the attacker earns Momentum Positive Bonus. See [recovery and walls](docs/recovery-and-walls.md) for editable values and prototype limits.

Fillet has **236K** knife spiral and **236S > 6S > 2S** rekka, with **236S > 2S** as the shortcut. Shark has **214S / j.214P** diagonal hook pulls and **P** on-hit stabs. Both have dedicated generated windup/active art. Most fighters run forward; Anvil and Tapper step. Run/step velocity carries into attacks, including motion commands. Tune these in Development; [signature moves and movement](docs/signature-moves.md) lists the inputs and settings.

Body-only hurtboxes follow all **1431 current poses**, using **legs, torso-and-arms, head, and at most one optional extension**—four boxes maximum. Per-fighter pushboxes and preliminary stats/hitboxes cover **282 move slots**. **Weapons never extend hurtboxes; startup minimums are 2f for grabs, 3f for P normals, and 5f for other attacks.** Development overlays and Sprite review show the actual collision geometry. See [collision rules](docs/collision-rules.md) and [move stats](docs/move-stats.md).

Menus share the supplied **Guild Ball** visual language: Barlow Condensed, charcoal panels, raised blue controls and brass trim. Character select adds a central angled roster and large guild-colored fighters, following the requested 2XKO-inspired direction. Versus fills the screen with generated Fillet/Shark face portraits, guild-colored health rails with names inside, an open timer dial, diamond Scrum markers and floating three-section Momentum. The stage floor and fighters share one camera projection, with body contact shadows and readable outlined combo numerals. Menus use interruptible eased transitions, with a saved reduced-motion option. Controls uses its separate warm Settings skin. [Menu style and provenance](docs/menu-style.md) records the reusable assets and review workflow.

**Tapper’s new kit is playable:** Leo-derived normals, close/far Slash, held guard, air throws and a no-block rolling stance. **5D / ground throw** enters; stance **S** self-chains, **Hs** is overhead, **2D** exits and **236D** runs into a tackle and single punch. New ready/rolling idles, walk and step-dash sprites accompany 64 attack drawings. [Full kit, frame data and editor instructions](docs/tapper-design.md).

**Hammer’s full kit is playable:** compact shoulder-led normals, three hammer specials and **5D Break Step**. Cancel a special into one burst per string, then a normal with full velocity carry and +4f block advantage. [Kit and controls](docs/hammer-kit.md) · [interactive animation review](https://h1p5t3r.github.io/Fight-guild-/hammer-motion-review.html).

Current combo physics uses **Strive-style decay, velocity knockback, weaker repeated bounces and tighter gatlings**. [Rules, editor controls and verified routes](docs/combo-decay.md) explain the provisional coefficients and character exceptions.

All six fighters now have **two supers**. **Whiskey Chaser** is Tapper’s stance barrage and **Freemason** is Hammer’s heavy finisher. Confirmed cinematic supers lock both players until their finish; **The Air Is Mine** and **Grand Design** remain actionable after their utility casts recover. [Inputs, roles and rules](docs/supers.md) · [native super showcase](exports/FightGuild-Supers-2026-11-25.mp4).

The full super animation pass starts with **Sky Foundry**: 16 body drawings, a dedicated torn-screen face, magma launch/slam effects and four original sounds, all on its existing combat clocks. [Watch with sound](exports/FightGuild-Sky-Foundry-2026-11-25.mp4) · [production notes](docs/super-animation-production.md).

**Iron Dominion** follows with a complete 16-drawing shield assault, separate rising/downward impacts, a final shield plant, its own face and four shield sounds. [Watch hit, block and whiff](exports/FightGuild-Iron-Dominion-2026-11-25.mp4).

**Freemason** adds Hammer's full 16-drawing horizontal/rising/downward sequence, blue hammer-force effects and a held finishing recoil before knockdown. [Watch the native review](exports/FightGuild-Freemason-2026-11-25.mp4).

**Grand Design** completes Hammer's pair with an eight-key ground cast, independent six-key stone wave, matching contact debris and a real follow-up demonstration. [Watch the native review](exports/FightGuild-Grand-Design-2026-11-25.mp4).

**Flashpoint** gives Smoke a full backhand, rising fire lift, compression and ignition, with 16 body keys, separate flames and four original sounds. [Watch the native review](exports/FightGuild-Flashpoint-2026-11-25.mp4).

**The Air Is Mine** completes Smoke’s pair with twelve caster keys, an independent six-key gas loop and separate contact pulses. [Watch hit, block and all three placements](exports/FightGuild-The-Air-Is-Mine-2026-11-26.mp4).

**Last Orders** gives Tapper twenty body keys: uppercut, headbutt, Dempsey finish and separate staff-return recovery on block or miss. [Watch the native review](exports/FightGuild-Last-Orders-2026-11-26.mp4).

**Whiskey Chaser** completes Tapper’s pair with sixteen alternating-hook keys, three distinct blocked punches and a heavy stance finish. [Watch the native review](exports/FightGuild-Whiskey-Chaser-2026-11-26.mp4).

**No Safe Harbour** gives Shark twenty hook-thrust, reel, drive and shoulder-return keys, with a long-range contact review. [Watch the native review](exports/FightGuild-No-Safe-Harbour-2026-11-26.mp4).

**Undertow** completes Shark’s pair with twenty sweep, overhead-reel and side-switch keys, plus separate miss recovery. [Watch the native review](exports/FightGuild-Undertow-2026-11-26.mp4).

## Play or edit

For browser-only attack tuning on a work PC, the [hosted Move Workshop](https://h1p5t3r.github.io/Fight-guild-/) is the intended delivery after the [one-time Pages setup](docs/move-workshop.md#hosted-publishing). It loads artwork as needed, keeps drafts and pose photos in your browser, and exports JSON for the Godot editor. The **Publish Move Workshop** workflow deploys updates from `feat/godot-combat-lab`. For offline use, extract **FightGuild-Move-Workshop.zip** and open `index.html`; keep its `assets` folder beside it. The single-file HTML is still built for compatibility. Current exports use schema 27; version-12–26 workshop files migrate automatically. No game install is needed. Before switching to the website, download your JSON from the old editor and import it on the site.

Download the Windows/Linux ZIP from this branch's successful GitHub Actions artifacts, extract the whole folder and run its executable. The current GitHub source ZIP also includes Windows x86-64 debug/release DLLs: import `godot/project.godot` in 64-bit Godot 4.6.3 and press F5. If an older source ZIP reports “Could not resolve external class member core,” use the [small Windows DLL repair ZIP](exports/FightGuild-Windows-Core.zip) and the [repair instructions](docs/play-native.md#windows-could-not-resolve-external-class-member-core). [Native play guide](docs/play-native.md) covers controls, saves, editing and direct online play.

- Versus is first to two Scrum wins: **1st Scrum**, **2nd Scrum**, and **Final Down** at 1–1. Fighter loading/intros and the four-beat opening lead into each match; online clients synchronize before release.
- Start from **Versus**, **Training** or **Development**, then choose fighters. Esc / gamepad Start opens the match menu. [Menu flow](docs/menu-flow.md) explains entry, pause, rematch and connection recovery.
- **Local versus** first asks you to choose sides. Move your controller left/right or use the device cards. **Controls** saves remaps, controller assignments and deadzones, with a live input test; [control setup](docs/input-controls.md).
- **Player 1:** WASD; J/K/L/I/O = P/K/S/Hs/D; Space = run/dash; back + Q = Faultless Defense.
- **Player 2:** arrows; numpad 1/2/3/5/6 = attacks; numpad 0 = run/dash; back + numpad Enter = Faultless Defense.
- Specials and supers use motion inputs. The simple-input modifier, shortcuts and character-select toggles are removed. Existing move files still import.
- In **Training**, use **Record**, **Replay** and **Frame lab** to inspect both fighters, cancel windows, input age, spacing and damage scaling. P2-only replay lets you practice against a recorded exchange; [training lab](docs/training-lab.md) explains the controls.
- **Super cut-in** in Training/Development previews a frozen-match face banner; **F8 / Shift+F8** select P1/P2. The preview spends no meter; real supers trigger the same cut-in and cost two Momentum segments. [Preview and face-art selection](docs/super-freeze-presentation.md).
- **Fighter themes:** all six supplied songs play in native matches. **Sound** offers independent music/effects volume, P1/P2 or fixed-theme selection, and a song preview. [Assignments and playback](docs/fighter-music.md).
- In **Development**, edit any fighter, Apply & reset, then Save locally or export JSON. Old schema-1–17 saves preserve edits during migration; Restore default move set loads the new starter tuning.
- Online: direct ENet/UDP host and join, default port 7000. Both players use Player 1 controls locally. Matching move data is required.

Momentum has **three equal sections**, with continuous gain and separately editable ground/air FD costs. Try **Start Momentum: 50%** and the **Faultless guard** dummy in training. The move editor exposes chip damage and **Guard break on block**; Sprite review includes negative/even, positive and guard-break clips. [Momentum and defense rules](docs/momentum-defense.md) describe the provisional tuning. Negative Penalty is deferred. FD and supers spend meter; each super costs two segments (66.67%).

Combos now appear as large background numerals on the attacker's current side. **Attack loop** and **Guard → reversal** training dummies help test counter hits, recovery punishes and first-frame reversals. Counter freeze, defender-only slowdown, bonuses and reversal eligibility are editable per move. Medium/large counters use oversized italic callouts, and large counters briefly push the camera in. See [combo and timing rules](docs/combat-feedback.md).

Native combat uses **Ink Snap II**: sharp contact flashes, distinct block/FD/shattered-guard/armor effects, subtle attack-release accents and 60 original material-based sound samples. Heavy hits have a low accent; confirmed impacts cut their swing tails. Watch the [gameplay effects review with audio](exports/FightGuild-Combat-Effects-2026-11-25.mp4). Sound settings let you audition hits and defense. The move-editor website remains paused; this pass is for Godot.

The [combat tuning editor](docs/combat-tuning.md) now supports cancel windows, starter and progressive damage scaling, jump startup, landing recovery, attack/counter presets, block carryover, five-frame post-stun throw protection and grounded wall priming. Guard break retains its throw vulnerability and backdash restriction. Blocking has no Just Guard or Instant Block timing requirement.

## Develop on Linux

Needs Git, curl, Python 3 with pip, a C++17 compiler and standard Linux Godot runtime libraries. Setup installs a pinned editor if needed, SCons and godot-cpp bindings in `FIGHT_TOOLS`, then builds and tests. The cloud default is `/workspace/.fight-guild-tools`; elsewhere set `FIGHT_TOOLS` to an absolute writable path outside the checkout.

```bash
bash scripts/setup.sh
bash scripts/godot.sh --editor
# Or launch the game directly:
bash scripts/godot.sh
```

After C++ changes, run `bash scripts/build-godot.sh`. When changing collision authoring, default move data or atlas pivots/body scale, first run `python scripts/generate-combat-data.py`, then rebuild the extension. The Windows DLLs in `godot/bin` are tracked for source-ZIP users. After core/native changes, also rebuild both Windows targets below and commit their refreshed `windows-core.json`; `python scripts/windows-core.py check` rejects stale binaries. Ordinary GDScript/presentation changes need no native rebuild. Validate with `bash scripts/test-godot.sh`.

To export, install templates and build the Windows library with MinGW-w64 (setup builds the Linux library):

```bash
bash scripts/install-godot.sh --templates
bash scripts/build-godot.sh target=template_release
bash scripts/build-godot.sh platform=windows
bash scripts/build-godot.sh platform=windows target=template_release
python scripts/windows-core.py check
python scripts/windows-core.py package --output exports/FightGuild-Windows-Core.zip
bash scripts/export-godot.sh
```

`build/` receives Windows and Linux ZIPs plus an editable Godot project ZIP containing available extension binaries. `bash scripts/export-godot.sh Linux` packages only Linux. `mingw_prefix=/absolute/toolchain/prefix` selects a relocated MinGW toolchain. The template download is approximately 1.2 GB; only four PC templates are installed.

## Implementation and limits

The shared C++ core runs at 60 fixed ticks with integer state, independent of presentation. [Architecture](docs/combat-architecture.md) explains native instances, rollback, versioned data and future 3D integration. [Combat rules](docs/combat-rules.md) separates confirmed design from defaults.

Linux rendering, keyboard gameplay, all 30 basic attacks, editing, save migration, sprites, latency/jitter correction and two UDP processes are tested. Windows is cross-compiled/exported and needs hardware playtesting. PS5 requires approved console access and Godot port tooling; no PS5 build is included. Strive input-buffer parity is a future measurement task.

The browser combat harness is retained for regressions: `bash scripts/setup-web.sh`, then `npm test`. The separate [Move Workshop](docs/move-workshop.md) provides portable attack authoring; Godot remains the game client and delivery path.

The [Move Workshop control guide (PDF)](exports/FightGuild-Move-Workshop-Guide.pdf) covers the earlier base controls. The [current Workshop guide](docs/move-workshop.md) includes later movement, projectile, Drive and stance controls; [Tapper’s guide](docs/tapper-design.md) includes his complete kit and tuning notes.

## Current reference guides

These are the latest character references. Fillet and Shark's **reference 05** set keeps the mature athletic proportions and matched rendering rules, selects **A / Stalker** for Fillet's standard combat stance, selects **F / Shoulder Rest** for Shark, and gives him blue sports glasses with long, lower-volume white hair. These drawing references guide sprite production; they are not runtime atlases or actual 3D assets. Their selected ready poses and separate eight-frame walk/run loops are now playable.

| Anvil | Smoke | Tapper |
| --- | --- | --- |
| [![Anvil](art/characters/anvil.png)](art/characters/anvil.png) | [![Smoke](art/characters/smoke.png)](art/characters/smoke.png) | [![Tapper](art/characters/tapper.png)](art/characters/tapper.png) |

| Shark | Fillet | Hammer |
| --- | --- | --- |
| [![Shark](art/characters/shark.png)](art/characters/shark.png) | [![Fillet](art/characters/fillet.png)](art/characters/fillet.png) | [![Hammer](art/characters/hammer.png)](art/characters/hammer.png) |

[Download the six-page reference PDF](exports/character-reference-guides.pdf).

For the first matchup: [Fillet action sheet](art/characters/fillet-actions.png),
[Shark action sheet](art/characters/shark-actions.png), and the
[four-page model/action PDF](exports/FightGuild-Fillet-Shark-References-v5.pdf).
[Reference rules and move-editor handoff](docs/fillet-shark-references.md) cover
palette, equipment, root travel, phased hitboxes, hurtboxes and pose-photo briefs.

Fillet's selected standard stance is **A / Stalker** from the
[six-option sheet](art/characters/stance-studies/fillet-01.png). The later
[B/F spacing refinements](art/characters/stance-studies/fillet-02.png) remain
exploration history; the A selection supersedes that narrower-base direction.

[Open the offline movement preview](exports/FightGuild-Movement-Preview.html)
for both selected stances, eight-frame walk/run loops, mirroring and hurtboxes.
In Godot, use **Development → Sprite & collision review → Walk / Run** to play
or scrub the same frames. The Move Workshop's approach preview also uses them.
Existing swing trails have a generated **3x thickness** pass; attack reach and
hitboxes are unchanged. [Production notes](docs/sprite-production.md) record
source prompts, collision fits and the remaining attack-art consistency work.

## Project notes

- [Game concept and roster](docs/game-concept.md)
- [Visual direction and review criteria](docs/art-direction.md)
- [Miniature sources and equipment notes](references/README.md)
- [Earlier visual explorations](art/archive/README.md)
- [Asset provenance and checksums](art/asset-manifest.json)

## Repository layout

```text
godot/                 Native project, UI, generated sprites and tests
native/                GDExtension adapter and build configuration
core/                  Deterministic C++ simulation
scripts/               Setup, build, tests and PC packaging
tests/                 Core, network and archived browser checks
docs/                  Rules, architecture, play guide and art pipeline backlog
art/characters/        Character model guides, action sheets and generation provenance
references/            Miniature sources and equipment notes
licenses/              Engine, dependencies and binding notices
web/                   Archived browser prototype
```

Guild Ball characters, names and miniature images belong to their respective rights holders. This is an unofficial concept project. No license for third-party material is implied.

Fillet and Shark now have **32 redrawn poses each**, with mature athletic proportions, stronger hands/boots and fitted body-only hurtboxes. The new outlined combat callouts use translucent fills so the fight stays visible. See the [sprite contract](docs/sprite-production.md) for the remaining roster and animation pipeline.

Generated stage presentation: [three layered arenas, directional wall breaks and the image-generation contract](docs/stage-art.md).

The browser Move Workshop now includes real hit/block playback, approach and
command movement, active-frame hitbox keys, optional multi-hit groups and a
prominent **Attack enabled** switch. See [the workshop guide](docs/move-workshop.md)
and [the complete control PDF](exports/FightGuild-Move-Workshop-Guide.pdf).
Use the current schema-14 game build to import new workshop downloads.
