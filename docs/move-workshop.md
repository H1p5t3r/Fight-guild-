# Move Workshop

Tune attacks in a normal browser without installing or running the game. The
hosted edition uses a small entry page and loads artwork as needed, instead of
putting every sprite sheet into one large HTML download. It uses the same
six-fighter data and plain-JavaScript combat preview. No account or WebAssembly
is needed. Edits, notes, pose references and sequence queues stay in your browser.

The portable **FightGuild-Move-Workshop.zip** contains the same editor and artwork.
Extract the whole folder and open `index.html`; keep its `assets` folder beside
it. This version works offline without a server or installation. The larger
single-file HTML remains available for compatibility.

The [complete control guide (PDF)](../exports/FightGuild-Move-Workshop-Guide.pdf)
explains every browser editor control, with allowed ranges, worked examples,
diagrams, clickable contents and an alphabetical field index. It covers the
schema-16 controls, including combat playback, timed hitboxes, hurtboxes,
art notes and pose photos, character movement and projectiles. This page also
documents the newer mobile layout and sequence testing.

## Use it on another PC

1. After the one-time Pages setup below, open
   **https://h1p5t3r.github.io/Fight-guild-/** in Chrome or Edge. Bookmark that URL
   for future updates.
2. For offline use, download **FightGuild-Move-Workshop.zip** from the chat or
   the **FightGuild-Portable-Editor** GitHub Actions artifact. Extract the entire
   ZIP, then open `FightGuild-Move-Workshop/index.html`. If downloading an Actions
   artifact, extract the included editor ZIP as well.
3. Start with Fillet or Shark, choose a move by numpad notation, then edit its
   timing, hitbox, reactions, cancels or inputs. **Import JSON** opens a current
   game export or a previous workshop download.
4. Use **Download JSON** before leaving work. At home, open the game's
   **Development** mode, choose **Import** in the move editor and select the
   downloaded JSON. The import applies the move set and resets the match.
   Choose **Save locally** in the game to keep those values for the next launch.
5. You can also attach that JSON in the chat. The move values, **Art & notes**
   notes and embedded pose photos provide a brief for future sprite and
   hit/block-effect revisions.

The page autosaves on the current browser/device when storage is available.
Drafts do not sync across PCs. Clearing browser data, using a private window or
moving/renaming a local HTML file can change access to that draft. Downloaded
JSON is the portable backup. If storage is blocked/full, editing and JSON
downloads still work; the page shows a reminder. A damaged saved draft can be
downloaded for recovery before explicitly starting a new one.

## Phone and desktop layout

On a phone or narrow window, the **Fighter** and **Move** selectors replace the
long sidebar. Tap **Move** to search, filter or show unused slots in a dialog.
Choose the editing section with the selector below the preview. Undo, redo,
reset and save status stay with that selector. **Import** and **Export** in the
header are the same JSON controls as on desktop.

The shared preview appears before the fields and scrolls away by default so
the form has room. On taller phone screens, **Pin** keeps it visible while
editing; tap again to release it. **Preview ↑** returns to the same stage.
**Minimize** hides the stage while keeping playback and the timeline available.
Short or landscape screens let the preview scroll away, and it unpins while a
small software-keyboard viewport is active. There is still only one preview
and one set of editing controls.

**Options** opens test setup, overlays, distances and playback speed on mobile.
On desktop, **Test setup** and **View & playback** are expandable sections
below the stage. Swipe across the stage to scroll normally. In a box-editing
section, tap **Drag boxes** to turn on touch dragging, then **Done dragging** to
resume scrolling. Mouse dragging works directly. Numeric fields remain an
alternative for precise geometry.

## Finding and arranging controls

**Find a setting…** searches field names, groups and help across sections,
including character movement and art notes. Choose a result to open its group
and focus the control. Arrow keys also navigate the results.

**Relevant fields** shows controls used by the move's current configuration.
Inactive groups remain labelled and can be opened to inspect retained values;
**Show inactive fields** reveals disabled dependencies inside a group. Choose
**All fields** to inspect everything in the section, with explanations of why
some values have no effect. Switching views never clears or resets values.
Invalid edits remain visible and must be fixed before leaving the section.

Tap a group title to collapse or expand it. Those choices are remembered for
each fighter, move, section and visibility mode. A **?** beside a label opens
that field's explanation. Help, layout and pin preferences are kept separately
from gameplay JSON.

Related settings now live together: **Hitboxes & impact** contains attacker
travel, grounded/airborne reactions, block and knockdown; **Hurtboxes & defense**
contains body regions, timed protection, low-crush and armor; **Inputs & cancels**
contains input mapping, proximity replacements and follow-up routes;
**Move behavior** contains held guards, charging, dive/recoil and grab sequences;
**Art & notes** contains sprite selection, finisher poses and the art brief.

## Drive system

The overview lists the current fighter's enabled Drive actions. Tap an input to
edit that move without leaving the section. Tapper's entries (including throws),
stance attacks and exits are grouped separately. Stance access and transitions
are edited here, alongside the selected action's behavior.

For Shark and Fillet, **Initial attack** shows the original startup/active/recovery
and damage in its closed summary. **Applied status** selects tether or bleed.
Below it, the controls show the current status and its repeat-input follow-up:
Shark's pull timing and movement, or Fillet's bleed/grey life and cash-out grab.
Unrelated mechanic controls appear in **All fields** or through setting search.

**Test initial attack**, **Test apply → follow-up** and Fillet's **Test bleed
timeout** use the same shared preview and test setup. **Open sequence test**
opens the existing queue editor for longer routes. The overview describes and
edits the current mechanics; it does not create a new stance or status type.

## Hosted publishing

The [Publish Move Workshop workflow](../.github/workflows/workshop-pages.yml)
builds, tests and deploys the editor after changes on `feat/godot-combat-lab`.
It publishes only `build/move-workshop`, with versioned assets and no backend.
The hosted data is the committed project draft, never a user's browser save.

One-time repository setup: an owner/admin opens
[Settings → Pages](https://github.com/H1p5t3r/Fight-guild-/settings/pages), chooses
**GitHub Actions** under **Build and deployment → Source**, then reruns the
latest **Publish Move Workshop** workflow if it previously stopped at deployment.
The standard workflow token can deploy updates, but cannot enable Pages itself.
The site is live only after that workflow's deployment job succeeds.

Before switching from the old downloaded HTML, use **Download JSON** there and
**Import JSON** on the website. Browser storage is separate for local files and
the hosted address. A site update preserves an existing saved draft; import
`FightGuild-moves.json` from the published folder only when you want to replace
it with the shipped kit. Download your own draft first.

Build both deliveries with `npm run build:workshop`. `npm run start:workshop`
serves the hosted folder locally. The portable ZIP opens directly from disk.
`version.json` records the source commit and schema for deployment verification.

## What you can tune

- All 270 move slots across six fighters, with unused slots hidden by default.
- **Attack enabled** beside the move title: turn off unused command normals or
  attacks without deleting their tuning data. Enable **Show unused slots** to
  find them again. Disabled attacks cannot execute or be cancel destinations.
- Startup/active/recovery, damage, chip, hitstun and blockstun.
- Active-frame hitbox keys, up to four boxes per key, optional separate hits,
  and damage/stun/hitstop overrides per key.
- Hitbox edges and height, opening movement, active travel and run/dash carry.
- Per-attack **Hurtboxes & defense** for windup, active and recovery: three body regions
  plus one optional extension, with numeric editing and draggable blue handles.
- Ground/air knockback, block pushback, ground/air launch, soft/hard knockdown,
  down/wakeup durations, landing recovery, hook pull and throw reach.
- Unified or custom gatling destinations, normal/special/jump/follow-up cancel
  windows, follow-up sources, input mappings and simple controls.
- Counter-hit timing/strength/vulnerability, reversal eligibility and damage
  scaling. Reversal timing does not itself grant invulnerability.
- Per-move nickname, gameplay intent, windup, active/weapon-path, hit/block
  effects, and later follow-through/recovery notes. **Download art brief** also
  produces a readable Markdown companion.
- **Pose references** in Art & notes accepts up to three JPG, PNG or WebP photos
  or pose sketches per move. Tag each as General pose, Windup or Active, and
  add a caption describing what to borrow. Click a thumbnail to enlarge it.
  Removing a photo is undoable; resetting move stats keeps the references.

Photos are embedded directly in **Download JSON**, so importing that file on
another PC restores the images, labels and captions. Adding a file does not
upload it anywhere. The browser makes a WebP copy up to 1200 pixels along the
longest edge; the source file stays unchanged. Source photos may be up to 20 MB.
The draft allows 12 MB of embedded reference data in total, and move JSON imports
support files up to 32 MB. Large photo drafts may exceed browser storage; use
Download JSON when the storage warning appears.

Undo/redo and **Reset move** are available. Reset restores that move's stats and
removes its hitbox timeline and custom hurtbox profiles while retaining its art
notes and photos.
A successful import is also undoable.

## Play and edit in one workspace

The shared attack workspace runs the same combat rules as the game. Choose the target,
Take the hit / Standing guard / Crouching guard / Faultless Defense / Airborne,
and an approach: standing, walking, running, jumping or forward jumping. Set the
body gap, facing and Traditional / Simple inputs. The preview enters the move’s
mapped command; air-only attacks jump automatically. Run or step movement comes
from that fighter’s actual movement profile and carries into attacks.

Play, pause, restart or scrub through the exchange at quarter, half or full
speed. Open **Hitboxes & impact** or **Hurtboxes & defense** to drag boxes directly on the
attacker in this same scene. The target stays visible, and the handles follow
the attacker’s position and facing. There is one canvas and one timeline.

After numeric edits or a drag, the exchange recalculates while keeping the
selected move frame, even if contact changes hitstop or approach changes timing.
Windup / Active / Recovery jump to those move phases in the same timeline. The readouts show input, move frame, freeze, target stun, hit/block
counts, scaled damage and attacker travel. Existing sprites follow the actual
movement, hit and block reactions. Context-only follow-ups are started in
isolation with a warning; this does not verify their entry route. Conflicting
input mappings also show a warning. Disabled or unmapped moves remain editable
in the same scene, labelled **Geometry only**, with no simulated contacts.
Enable the move or correct the input mapping to test execution.

This is a recorded spacing/reaction test, not an interactive training match.
It uses existing artwork, with placeholder recovery poses; it does not generate
new animation frames. Use **Sequence test** for routes and Godot for match feel.

## Check a sequence of moves

1. Choose a fighter, then open **Sequence test** in the section navigation.
2. Select a move and press **Add move**. Queue up to 12 attacks. Each row lets
   you change the move, move it up/down or remove it.
3. **Delay +f** adds 0–120 simulation frames after the first legal input
   opportunity for that step. Zero tries the earliest accepted command,
   including the game's input buffer. Shared hitstop and wall transitions do
   not consume the added delay. If a delay misses a cancel window, the move
   waits for its next legal opportunity, such as recovery ending.
4. Use the shared preview's play, restart and scrub controls. A row's **Frame**
   button jumps to when that move actually starts. The active row is outlined.
5. Test different spacing, facing, approach, inputs and defender behavior in
   **Options → Test setup**. The preview reports hits, blocks and damage; the
   queue summary adds maximum combo count and any input failures. A queue can
   execute completely while dropping its combo or missing the target.

The sequence uses real commands and the combat core's cancel rules. It does
not force a follow-up or manufacture a whiff cancel. Each trial command is
checked on a copy of the simulation before it is sent to the recorded exchange.
Repeated presses release the button between attacks. Air attacks insert a real
jump input when grounded, respecting jump-cancel and takeoff rules. Contextual
attacks require their real prerequisite: queue Fillet's rekka starter before
its follow-ups, or Tapper's stance entry before stance normals. An unavailable
move, disabled slot or conflicting input stops the sequence with an explanation.
Simple mode uses each mapped modifier command; ordinary normals and directional
rekka follow-ups still use their regular buttons when no modifier mapping exists.

Queues contain move selections and delays; they are not arbitrary input scripts.
There is no separate button-hold duration control. Clips are capped at 1,800
frames and stop after the exchange settles or the target is defeated.

Each fighter has its own queue. Undo/redo and **Clear queue** work normally.
Queues autosave locally and travel in **Export JSON** under
`_moveWorkshop.sequences`, alongside artwork notes and references. They do not
change gameplay tuning. Keep the workshop JSON: the game's gameplay-only export
does not preserve workshop metadata.

## Measure spacing and reach

**Distances** starts enabled. The same scene shows horizontal measurements in
**game pixels**, independent of browser zoom or camera scale:

- **Roots** / **Root spacing**: distance between the fighter roots.
- **Body gap**: space between the nearest pushbox edges. **Body overlap** shows
  overlapping horizontal projections, which can happen with airborne fighters.
- **Box front**: the farthest forward edge of the visible attack shape, measured
  from the attacker’s root. It follows the current hitbox key or moving hook.
  An inactive reference outline is labelled **inactive**; gaps have no reach.
- A selected editable hitbox or hurtbox shows its **width × height**.
- The ground ruler is **0 at the attacker**, positive forward and negative behind.
  It mirrors with facing and uses wider tick intervals when needed for readability.

The readout under the canvas repeats the values as text. Guides update during
playback, scrubbing and dragging. Hide them with **Distances** to clear the view;
the current frame, scene scale and move data stay the same. These are horizontal
measurements; vertical alignment, timing and other collision rules still decide
whether an attack connects.

## Change hitboxes during active frames

1. Open **Hitboxes & impact**, then pause or scrub the shared timeline. The attack
   and its target stay in the same scene.
2. Scrub to an active frame and choose **Add key at active …**. Active frame 1 is
   the move’s first possible contact frame, not the start of its windup.
3. A key holds until the next key. **Use base geometry** follows the ordinary
   strike/hook shape; **Add hitbox** starts a custom rectangular profile, with
   up to four boxes; **No hitboxes · gap** creates a non-hitting interval.
4. Select a box and use its orange handles or Left / Bottom / Width / Height.
   All boxes in a key share its hit number and values. The coordinates mirror
   with facing. Custom hook boxes replace the moving spear geometry.
5. Optional Hit damage, Hit hitstun, Hit blockstun and Hit hitstop values override
   the move’s base values. **−1 inherits**. Combo scaling and counter bonuses
   still apply. The top summary shows base values, not every key’s overrides.
6. Keep **Allow multiple hits** off for one contact across all keys. Turn it on
   and assign different **Hit number** values for separate hits. A number can
   connect only once per attack, even if repeated later or used by overlapping
   boxes. Repeated hits each apply damage, stun and hitstop normally.

There are at most 32 keys, with distinct start frames 1–120 and hit numbers 1–32.
Keys beyond the move’s Active duration are retained and editable, but cannot
hit. Edges stay within ±500 game pixels and each box is at least 1×1 px. Before
the first key, the move uses base geometry and hit number 1. A gap does not reset
a consumed hit number. Throws retain their single-hit range resolver.

JSON, browser Undo/Redo, Godot import, local saving and rollback preserve these
settings. **Reset move** restores the bundled defaults and clears custom keys.

## Edit attack hurtboxes

1. Choose the fighter and move, then open **Hurtboxes & defense**.
2. Choose Windup, Active or Recovery. Recovery is available when the move has
   recovery frames. The preview jumps to that phase.
3. Enable **Custom boxes for this phase** to start from the current sprite's
   body boxes. Only this move and this phase change; shared sprites and other
   attacks are unaffected.
4. Select Legs, Torso & arms, or Head. Drag the selected blue box's center to
   move it, drag its edge handles to resize it, or edit its position/size in
   game pixels. You can include one **Body extension** for an extended limb.
5. Download JSON and import it into the updated schema-16 Godot build. The
   imported profiles affect actual hit detection and the in-game collision
   overlay. **Save locally** in Godot retains them for future launches.

Turning off Custom boxes restores the sprite profile for just that phase. The
three main body boxes are required, so the editor cannot silently create an
invulnerable phase by removing all boxes. There are at most four boxes, each at
least 1×1 px, with edges between −500 and 500 px relative to the fighter's root.
Fit them to the body; weapon reach adds no hurtbox. Pushboxes remain separate.
These are whole-phase profiles; individual animation-frame keyframes remain
future work. The inherited recovery pose can change with crouching/landing in
the live game; a custom recovery profile stays fixed for that move's recovery.

The page edits the 68 currently effective move fields and preserves the retired
`wallDamage` compatibility field. Walls still take damage from horizontal
collision velocity. Character movement profiles and global combat rules are
preserved through import/export, but are not tuning controls in this page.

## Preview and data conventions

- One gameplay frame is 1/60 second. Playback defaults to half speed for inspection.
  A 5-frame startup has four windup frames, then its first active frame. Startup
  minimums are 2 frames for grabs, 3 for P normals (normal/command category), and 5 for other attacks. Drafts older than schema 20 upgrade standard ground/air throws to 2f; schema-20 and later exports preserve subsequent timing edits.
- **Base on block** assumes contact on the first active frame, no cancel and no FD.
  A later active-frame hit can change the actual advantage.
- Positions/distances use game pixels; travel/launch use pixels per frame.
  Hundredths are preserved exactly in the core's integer units.
- Orange is attack geometry, blue is body hurtboxes, and green is the pushbox.
  The most recent attacker draws in front after a hit or block. Seeking backward
  restores the draw order from the selected frame.
  On the Hitboxes & impact tab, drag a normal strike's active rectangle or its edge
  handles, or edit a selected custom key box. Numeric fields cover base hook and
  throw geometry. The inherited hook preview draws eight
  moving spear segments; the rope is not a hitbox.
- The shared workspace uses existing pose studies. New hitbox dimensions do not
  automatically refit the art. Recovery uses idle/crouch/air placeholders.
- The **Hurtboxes & defense** tab edits body coverage while pushboxes remain read-only.
  Weapons have no hurtboxes, and each pose retains at most four body boxes.
  Sprite replacement and body-box refitting remain a coordinated later pass.

Exports use schema/core version **15**. Version-12, version-13 and version-14 workshop files
and browser drafts migrate automatically, keeping their numbers, notes, photos
and body profiles. Missing hitbox timelines inherit one-hit base geometry. Invalid or incomplete files are rejected
before changing the draft. An older save can first be imported and re-exported
by the current Godot build, which owns the earlier legacy migrations.
Unknown JSON properties are preserved by the workshop.

Art notes and pose references are stored under `_moveWorkshop` alongside the ordinary game data.
Godot accepts the file and ignores that extra metadata. **Keep the workshop
JSON:** a subsequent export from Godot contains gameplay data only and does not
carry the art notes or photos back out. The Markdown brief lists reference names,
phases and captions; the images themselves remain embedded in the JSON.

## Developer build and checks

With the existing web toolchain installed (`bash scripts/setup-web.sh`):

```bash
npx playwright install chromium
npm run build:workshop
npm run test:workshop
npm run start:workshop
```

The local preview server listens at `http://127.0.0.1:8081`; it is not a public
work-PC link. `PORT` and `HOST` may be set for an approved deployment. For static
hosting, deploy the contents of `build/move-workshop/` to the site's root. There
are no server routes or API dependencies.

`build:workshop` rebuilds the portable combat core before packaging. Accepted
integer limits and defaults come from that core. Original generated PNGs remain
untouched; the page embeds WebP encodings at the same atlas dimensions and
pivots. Chromium is needed only for packaging/testing; `CHROMIUM_PATH` selects
an existing installation. Users of the HTML need only ordinary browser
JavaScript support.

Tests cover core field limits, exact collision geometry, per-phase hurtboxes and
real hit detection, shared-sprite isolation, version-12 migration, atomic imports,
roster/rule preservation, fixed-point units, history, real browser JSON
downloads with embedded images, photo removal/undo and validation, autosave,
storage failure/recovery and responsive layouts. Run the
native interop check against the browser test's actual downloaded file:

```bash
bash scripts/godot.sh --headless --script tests/workshop_import_test.gd -- \
  "$PWD/build/workshop-browser-roundtrip.json"
```

Review screenshots are written to `build/workshop-review/`. The managed cloud
Chromium blocks `file://` URLs, so automated browser checks serve the identical
self-contained HTML through a temporary local HTTP server. They verify that
the document requests no secondary resources. Workplace browser policies still
determine whether local HTML or a hosted URL is allowed.

## Movement, defense and projectiles (schema 15)

**Character movement** edits the selected character and keeps the shared preview. Choose an idle, walk, 66, 44, jump, air dash or FD demonstration, then play or scrub the actual core simulation. Fillet uses A / Stalker with black hair and lean arms; Shark uses F / Shoulder Rest. Both have eight-frame walk/run cycles.

- **66 / 44:** independent Run, Step dash, Hover dash or Teleport. Runs continue while held. Step/hover use speed and duration; a ground hover rises toward its height, while an air hover holds height. Teleports relocate once after startup, clamp to stage boundaries, permit side switches and keep pushboxes separated. Startup/recovery lock actions and do not grant invulnerability.
- **Air movement:** forward/backward toggles, independent styles/speeds/durations, a shared dash budget, and additional air jumps per character. Every air dash clears existing velocity, pauses in place, then starts its full burst. **Air forward pause** and **Air backward pause** default to 4 frames and accept 1–30; burst duration is separate. Air teleports use this pause as their windup. Budgets refill on landing. Jump speed, directional steering, gravity and prejump are editable. Attacks after the pause can inherit the new burst velocity. See [air-dash rules](air-dash-pause.md).
- **Pushblock:** the existing Faultless Defense mechanic. Per-character overrides control enablement, separation, ground/air drain and base block cost. `-1` inherits the match rule. Costs use 100 units per 1% Momentum; attack-level/damage surcharges still apply.
- **Projectiles:** disabled by default for every move. Enable Moving or Stationary, set spawn frame/offset, dimensions, speed, gravity, lifetime, hit count, re-hit interval, clash durability and survival on owner hit. Spawn frame 0 uses first active; no spawn is earlier than frame 5. Throws do not spawn projectiles. Enable “Keep the body strike too” for melee plus projectile attacks. The projectile uses the move’s damage, stun, guard, knockback, launch and knockdown; hitbox-timeline overrides belong to the body strike. Each owner can have eight live objects. Fixed-point swept collision handles fast thin shots and opposing clashes. Stationary objects ignore velocity/gravity. Shared hitstop freezes projectile time; rounds and wall travel clear them. Projectile immunity remains a separate future feature.
- **Animation:** poses display directly, with no generated transition smear frames. Weapon smearing is deferred. Old JSON smear fields are retained for compatibility and ignored by both renderers.

Movement and all attack controls support undo, autosave and JSON export/import. Schema-14 imports preserve old edited values and add new fields with compatible defaults. A move’s art brief and pose photos remain in the workshop JSON. Native Godot imports the same gameplay values; keep the workshop file for its art metadata.


## Vulnerable regions (schema 16)

In **Hurtboxes & defense → Regions that can be hit**, turn Legs, Torso & arms, Head and the available Body extension on or off independently for windup, active and recovery. This works on inherited sprite geometry and custom profiles. Turning a region off preserves its coordinates, removes it from collision and the live hurtbox overlay, and supports undo, autosave and JSON. At most four regions still exist. Pushboxes and attacking hitboxes are independent.

Every fighter’s **6P** defaults to legs only during windup and active frames, with all body regions restored in recovery. This is upper-body protection against melee and projectiles; overlapping leg hits and throws remain possible. The three exported fields are `hurtMaskWindup`, `hurtMaskActive` and `hurtMaskRecovery` (bits 1/2/4/8, all = 15). Earlier exports migrate without dropping edited stats, rectangles, timelines or art briefs. No transition smearing is reintroduced.

## Current working batch

The [17 November batch 2](move-batches/2026-11-17-batch-02.md) is bundled as a work-in-progress preset. A fresh browser opens that batch; an existing local draft takes priority. To replace an existing browser draft, use **Import JSON** with the archived batch (or your newer file); Undo restores the prior draft. Reset move still restores the starter data.

Godot loads the batch before a locally saved move set. **Development → Load latest workshop batch** applies it again for playtesting; **Save locally** is explicit. Both original uploads are archived unchanged. The current file preserves the 6P vulnerability controls and includes four move briefs. Schema 17 implements the tether/pull and bleed/grey-life/cash-out systems with editable controls. See [Drive mechanics](character-mechanics-drafts.md) for rules, provisional defaults and preview use. Remaining moves and pose references are still pending.

### Drive mechanics (schema 17)

The **Drive system** tab configures status application, bleed amounts/timing, tether velocity, and conditional follow-up startup, active/recovery, grab damage, reach and leap movement. Select **Drive test → Apply → follow-up** to record the applying hit and repeat its input; **Apply → wait for timeout** shows bleed expiry. Grey life and tethers are visible in the shared preview. Older imports retain their prior move values and notes while receiving these new defaults. See [complete behavior and inheritance](character-mechanics-drafts.md).


### Additional move behavior (schema 18)

Tapper's full kit and confirmed **st.236D** are in the [current Tapper guide](tapper-design.md). These controls are per move and appear in both editors. The browser groups them by purpose across Drive system, Move behavior, Hitboxes & impact, Hurtboxes & defense, Inputs & cancels, and Art & notes. Values use frames, world pixels and pixels/frame as labeled; JSON keeps the existing 100-units-per-pixel convention. A timed mask intersects the phase mask; it never enables a region disabled in Hurtboxes. Bits are legs=1, torso/arms=2, head=4, extension=8.

| Control | What it does |
|---|---|
| Required stance | Any, normal stance only, or rolling stance only. |
| Stance transition | Enter rolling stance on successful hit, or exit when the action starts. |
| Action behavior | Strike, held guard, stance exit, stall/dive, timed grab, hold-to-charge, or air projectile stall/recoil. |
| Held-input destination | Move slot entered while holding the source attack button; -1 disables. |
| Hold transition frame | First move frame on which the held-input transition can start. |
| Guard hold button | Button to keep held when previewing this guard action. |
| Guard attack destination | Opposite S/Hs input starts this move from held guard; -1 disables. |
| Close-distance move | Alternate move selected when starting this input within the proximity range. |
| Close-distance range | Root-to-root distance for the close version; checked at move start. |
| Startup travel | Forward movement per startup tick; retains authored run/dash carry. |
| Dive / recoil horizontal speed | Forward speed during an active dive, or velocity on air projectile release. Negative values recoil away from the opponent. |
| Dive / recoil vertical speed | Downward speed during the active dive or on air projectile release. Startup stalls vertical movement. |
| Air-hit ground bounce | One bounce upward at ground contact, only when this move hits an airborne target. |
| Air-hit wall bounce | One rebound away from the wall; velocity still damages wall health and depleted walls splat first. |
| Grounded floating crumple | Grounded hit enters a vulnerable floating crumple for this many ticks. |
| Air counter-hit knockdown | Override knockdown on an airborne counter hit; 0 keeps the ordinary result. |
| Hurtbox window begins | Move-frame start of a finer body-region mask; 0 disables the window. |
| Hurtbox window ends | Inclusive final move frame for the temporary body mask. |
| Window body mask | Bit mask: legs 1, torso/arms 2, head 4, extension 8. Weapons never add hurtboxes. |
| Low-crush window begins | During this window low strikes and ground throws miss, without changing input selection. |
| Low-crush window ends | Inclusive final move frame of low/ground-throw avoidance. |
| Mid/high armor duration | First move frames protected by hit-limited armor. Lows and throws beat it. |
| Armor hits | Hits absorbed within the armor window; damage and hitstop still apply. |
| Grab sequence duration | Ticks from capture to the single finishing hit. Target is held until the finish. |
| Finisher artwork pose | Optional second pose during the grab or active timeline; 0 uses the initial pose. |
| Finisher pose frame | Active frame or grab-sequence tick at which the finisher drawing appears. |

The base block-advantage card is inapplicable to throws, exits and guard holds. Captures pause the move clock and show a separate capture/finish clock. Bounces are one-use reactions on airborne hits. Stance requirements and transitions do not grant invulnerability. Startup/active hitboxes, per-phase hurtbox editing and no more than four body regions remain unchanged.

New contextual slots are disabled when importing an older file; existing values and art notes survive. Local browser drafts take priority over the bundled draft. Back up the current draft, then import `FightGuild-Tapper.json` to load the new kit deliberately.

## Smoke normals and Tapper box corrections — schema 19

The [Smoke guide](smoke-design.md) lists the saved Queen Dizzy timings, attack visuals, source traces and remaining approximations. Leo diagrams only correct Tapper attack boxes; his custom stance and move timing are preserved. Schema19 adds `6[Hs]` and `5[D]` as editable charged follow-ups. Older imports leave these slots disabled.

**Hold to charge** keeps the base attack in anticipation while its button stays held, then enters the **Held-input destination** at **Hold transition frame**. Early release fires the uncharged attack, no earlier than its startup. Disabling the destination falls back to the base strike. **Air projectile recoil** stalls vertical motion before the shot, then applies the editable recoil velocities at emission. The source j.D emission tick is represented as one active tick plus19 recovery ticks.

The block-advantage card now evaluates the first frame of the last distinct hit group, so Smoke f.S reads−7 and5Hs reads−4. Shape-only keys do not improve that estimate; actual air/projectile contact and cancels still change advantage.
