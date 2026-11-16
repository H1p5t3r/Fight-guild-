# Move Workshop

Tune attacks in a normal browser without installing or running the game. The
download is one self-contained **FightGuild-Move-Workshop.html** file (about 9 MB),
including the current six-fighter data, sprite sheets and fonts. No account,
server, WebAssembly or network access is needed to use the downloaded page.

## Use it on another PC

1. Download **FightGuild-Move-Workshop.html** from the chat attachment or this
   branch's **FightGuild-Move-Workshop** GitHub Actions artifact. Extract the
   artifact ZIP if downloading from Actions.
2. Open the HTML file in Chrome or Edge. If your workplace disallows local HTML,
   the same file can be served as `index.html` on an approved static website;
   this repository does not currently publish that website.
3. Start with Fillet or Shark, choose a move by numpad notation, then edit its
   timing, hitbox, reactions, cancels or inputs. **Import JSON** opens a current
   game export or a previous workshop download.
4. Use **Download JSON** before leaving work. At home, open the game's
   **Development** mode, choose **Import** in the move editor and select the
   downloaded JSON. The import applies the move set and resets the match.
   Choose **Save locally** in the game to keep those values for the next launch.
5. You can also attach that JSON in the chat. The move values, **Art brief**
   notes and embedded pose photos provide a brief for future sprite and
   hit/block-effect revisions.

The page autosaves on the current browser/device when storage is available.
Drafts do not sync across PCs. Clearing browser data, using a private window or
moving/renaming a local HTML file can change access to that draft. Downloaded
JSON is the portable backup. If storage is blocked/full, editing and JSON
downloads still work; the page shows a reminder. A damaged saved draft can be
downloaded for recovery before explicitly starting a new one.

## What you can tune

- All 192 move slots across six fighters, with unused slots hidden by default.
- Startup/active/recovery, damage, chip, hitstun and blockstun.
- Hitbox edges and height, opening movement, active travel and run/dash carry.
- Per-attack **Hurtboxes** for windup, active and recovery: three body regions
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
- **Pose references** in Art brief accepts up to three JPG, PNG or WebP photos
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
removes its custom hurtbox profiles while retaining its art notes and photos.
A successful import is also undoable.

## Edit attack hurtboxes

1. Choose the fighter and move, then open **Hurtboxes**.
2. Choose Windup, Active or Recovery. Recovery is available when the move has
   recovery frames. The preview jumps to that phase.
3. Enable **Custom boxes for this phase** to start from the current sprite's
   body boxes. Only this move and this phase change; shared sprites and other
   attacks are unaffected.
4. Select Legs, Torso & arms, or Head. Drag the selected blue box's center to
   move it, drag its edge handles to resize it, or edit its position/size in
   game pixels. You can include one **Body extension** for an extended limb.
5. Download JSON and import it into the updated schema-13 Godot build. The
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

- One gameplay frame is 1/60 second. Playback runs at half speed for inspection.
  A 5-frame startup has four windup frames, then its first active frame. Startup
  cannot be below five frames.
- **On block** assumes contact on the first active frame, no cancel and no FD.
  A later active-frame hit can change the actual advantage.
- Positions/distances use game pixels; travel/launch use pixels per frame.
  Hundredths are preserved exactly in the core's integer units.
- Orange is attack geometry, blue is body hurtboxes, and green is the pushbox.
  On the Hit & movement tab, drag a normal strike's active rectangle or its edge
  handles. Numeric fields cover hooks and throws. The hook preview draws eight
  moving spear segments; the rope is not a hitbox.
- The preview holds existing pose studies. It does not simulate opponents,
  attack movement or contacts, regenerate sprites, or promise that new hitbox
  dimensions already match the old art. Match feel still needs in-game testing.
  Recovery uses idle/crouch/air placeholders.
- The **Hurtboxes** tab edits body coverage while pushboxes remain read-only.
  Weapons have no hurtboxes, and each pose retains at most four body boxes.
  Sprite replacement and body-box refitting remain a coordinated later pass.

Exports use schema/core version **13**. Existing version-12 workshop exports and
browser drafts migrate automatically, keeping their numbers, notes and photos
and inheriting the original body poses. Invalid or incomplete files are rejected
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
