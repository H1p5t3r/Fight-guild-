# Play Fight Guild in Godot

Extract the whole game ZIP first. On Windows run `FightGuild.exe`; on Linux run `FightGuild.x86_64` (use `chmod +x FightGuild.x86_64` if your unzip tool loses executable permissions). Keep the `.pck` and native library beside the executable. These x86-64 Windows/Linux packages do not require a browser, Node or a separately installed Godot editor.

For the editable project ZIP or the GitHub source ZIP from `feat/godot-combat-lab`, import `godot/project.godot` into **64-bit Godot 4.6.3**, then press F5. Current source ZIPs include the Windows debug/release combat DLLs. The cloud tests use 4.6.3; a newer editor is not required to fix missing DLLs. The complete repository, including concept references, is at https://github.com/H1p5t3r/Fight-guild-/tree/feat/godot-combat-lab.

## Windows: “Could not resolve external class member core”

This is often a secondary error: `CombatModel` could not load the native `FightCore` class. Source ZIPs made before the Windows-binary delivery fix omitted `godot/bin` because compiled libraries were ignored by Git. Editing the highlighted `model.core.pose_boxes(...)` line does not install that dependency.

1. Close Godot completely. Windows locks DLLs while the editor is open.
2. Download [FightGuild-Windows-Core.zip](../exports/FightGuild-Windows-Core.zip), or get a fresh source ZIP from `feat/godot-combat-lab`.
3. For the small repair ZIP, extract its contents into the folder containing `project.godot`. In a repository download this is **`godot/`**. Merge the `bin` folder and replace the matching DLLs. Keep your move JSON and saves.
4. Confirm these exact paths exist relative to `project.godot`:
   - `bin/libfight_core.windows.template_debug.x86_64.dll` — needed by the editor/F5.
   - `bin/libfight_core.windows.template_release.x86_64.dll` — needed by release exports.
5. Reopen `project.godot` and press F5. If it still fails, open **Output** and inspect the **first** GDExtension loading error. That distinguishes an incorrect folder, wrong architecture, blocked DLL or different dependency issue.

Use the repair package with the matching current branch source. Copying an old DLL beside newer scripts can produce a different configuration/API mismatch. The standalone `FightGuild-Windows.zip` is a playable export; its release DLL alone is not sufficient for the Godot editor.

## Choose a mode

The game opens at the main menu. Use the mouse, arrow keys/Enter, or a controller's D-pad/A to navigate; Esc/B goes back. Menus use the supplied Guild Ball panel/font style; Controls opens in its separate warm Settings skin.

- **Versus → Local versus → Fighter select → Let’s fight:** a first-to-two Scrum match, a full-width arena, and a results screen with Rematch and Change fighters.
- **Versus → Online versus → Fighter select → Connection:** choose only your local fighter, then Host or Join. Both peers connect, prepare their fighters and finish the opening before combat starts.
- **Training → Fighter select → Start training:** choose your fighter and a dummy, then practice with dummy behavior, starting Momentum, input history, hitboxes, pause, frame step and reset controls. **Record / Replay / Frame lab** capture exchanges and inspect both players; [training guide](training-lab.md).
- **Development → Fighter select → Open combat lab:** practice controls plus the move editor, sprite review, buffer/Momentum tuning, data import/export and rollback workbench.

Choose Anvil, Hammer, Smoke, Tapper, Shark or Fillet. Each player independently chooses simplified controls. The training dummy can stand, guard, crouch guard, run a practice sequence, use Faultless Defense, repeat Hs attacks or attempt reversals after guarding.

**Esc / gamepad Start / Menu** opens the match menu. Offline rounds freeze there; Resume keeps the exact round, Restart scrum restarts the current Scrum while retaining earlier wins, and Change fighters can be canceled without losing the round. Online play continues with neutral input while the menu is open; leaving closes the connection. Applied move edits survive navigation between modes. Save locally to retain them after quitting.

At fighter select, choose Player 1 or Player 2 above the central roster, then use arrows/D-pad or click a portrait. Both players may choose the same fighter. Simplified-input toggles remain independent. **Motion: Full / Reduced** on the main menu controls menu animation and is saved locally.

Matches use **1st Scrum**, **2nd Scrum**, and **Final Down** when tied 1–1. First to two Scrum wins takes the match; draws replay the current Scrum. Win markers sit beside the health bars. Each Scrum resets health, Momentum and the timer.

A loading card and two fighter introductions lead into “The stands hunger for legends.” → “Let the guilds give them names.” → the Scrum call → “Break the line!” Press Enter/A or click **Skip intros** to skip the spotlights. The four opening beats still play, and held buttons must be released before attacking. Practice resets remain immediate.

See [menu paths and edge cases](menu-flow.md).

| Action | Player 1 keyboard | Player 2 keyboard | Gamepad |
| --- | --- | --- | --- |
| Match menu | Esc | Esc | Start |
| Movement / jump / crouch | WASD | Arrows | D-pad or left stick |
| P | J | Numpad 1 | Bottom face button |
| K | K | Numpad 2 | Left face button |
| S | L | Numpad 3 | Top face button |
| Hs | I | Numpad 5 | Right face button |
| D | O | Numpad 6 | Right shoulder |
| Run / dash macro | Space | Numpad 0 | Left shoulder |
| Simple modifier | Left Shift | Numpad + | Left trigger |
| Faultless Defense (hold away too) | Q | Numpad Enter | Right trigger |

With simple controls enabled, hold the modifier for per-move shortcuts. Fillet uses 6K / 6S for her spiral/rekka; Shark uses 4S / j.4P for his hooks. Other original shortcuts include forward+P, down+S and up+Hs. Directions are relative to facing. Traditional 236P, 236S and 623Hs still work. Buttons also have crouching, forward command-normal and air variants. These kits are provisional.

Hold back + any two of P/K/S/Hs as an alternative FD chord. Momentum builds through approaching, attacking and defending; FD is its only spend. Its three equal HUD sections fill continuously to 100%; the divisions do not alter gain or costs. Select **Start Momentum: 50%** in training to try it immediately. FD prevents chip damage and adds pushback. Empty meter falls back to ordinary guard. Negative Penalty is deferred.

Block animations distinguish negative/even attacks, plus-on-block pressure and guard break. Enable **Guard break on block** for a move to test its exposed stance: backdash inputs during the stun are discarded and blockstun grab protection is absent. See [Momentum and defense](momentum-defense.md).

Combos show a large number behind the fighters on the attacker's current side. **COUNTER** means startup/active interruption; **PUNISH** means a hit during recovery; **REVERSAL** means an eligible move started on the first actionable frame after stun. Try **Attack loop** or **Guard → reversal** for practice. [Combo and timing rules](combat-feedback.md) cover the editable +4 hitstun/+3 hitstop counter defaults and five-frame reversal input buffer. Reversal timing does not grant invulnerability.

## Fillet and Shark signatures

Fillet: **236K** knife spiral; **236S > 6S > 2S** rekka or **236S > 2S** to skip the mid stab. Shark: **214S** upward ground hook, **j.214P** downward air hook, then **P** after a successful hit to stab. Press each follow-up anew during the source move; Shark’s stab requires a hit.

**66 or Dash** starts forward movement. Most fighters run while forward or Dash is held; Anvil provisionally steps. Back + Dash goes backward. Run/step speed carries into attacks. In Development, expand **Run, step dash & inertia** to tune the selected fighter, and select **Signature attack** in Sprite review for the new art. [Move timings, routes and settings](signature-moves.md).

## Iterate

Enter **Development** for move editing and sprite review. Training also offers pause, frame step and hitboxes.

- **Pause / +1 frame:** inspect startup, active frames, hitstop and recovery. Generated windup and active images follow simulation timing.
- **Development workbench:** scroll below the editor controls for the rollback latency check and gatling reference.
- **Move editor:** choose a fighter/move, adjust values, then Apply & reset. Startup minimums: **2f for grabs, 3f for P normals, 5f for other attacks**. Hitbox back/front, bottom and height control the attack rectangle. Save locally or export/import JSON. Old schema-1–6 saves retain edits and their previous hitbox ranges; Restore default move set loads the new preliminary kits.
- **Sprite review:** inspect all existing attack, defense and movement poses at the same body scale, with collision and facing toggles. Complete animation sequences are still future work.
- **Hitboxes:** cyan body hurtboxes, green pushboxes and orange active hitboxes show the actual simulation geometry. Weapons never extend hurtboxes. Walking, dashing and advancing moves respect body spacing; jump-overs require vertical clearance. See [collision rules](collision-rules.md) and [preliminary move stats](move-stats.md).

Saves use Godot's `user://` directory: normally `%APPDATA%/Godot/app_userdata/Fight Guild` on Windows and `~/.local/share/godot/app_userdata/Fight Guild` on Linux. The cloud launcher uses writable directories under `FIGHT_TOOLS`. Export move JSON before moving between machines.

## Direct online prototype

Both players need the same build and move data. Go to **Versus → Online versus**, choose your local fighter and continue to the connection screen. One player hosts UDP port 7000; the other enters that computer's address and joins. Both use Player 1 controls locally. Allow that UDP port through the host's firewall as needed. `127.0.0.1` works only for two processes on the same computer.

This direct ENet connection uses rollback, two frames of input delay, bounded prediction and confirmed-state checks. No room server is needed. Editing is locked while connected. Use **Return to online lobby** after the full match and host/join again for a rematch; Scrums within the match advance automatically. Cancel a pending connection to retry; failures and disconnects return to the connection screen with an explanation. Matchmaking, automatic NAT traversal and reconnect are backlog work; direct Internet hosting may require router configuration.

## Validation and limits

Linux native rendering, menu routes/back paths, keyboard and simulated-controller navigation, first-to-two matches, draw replay, intro/readiness gates, pause/rematch, connection recovery, all 30 basic buttons, editing, sprite loading, rollback and two independent UDP peers are tested. Windows is cross-compiled/exported; Windows gameplay and physical controllers need hardware playtesting. PS5 requires approved console access and a compatible Godot port provider; no PS5 build is included.

The buffer is an original configurable implementation, not verified Strive parity. Further character mechanics, full move animations, universal overheads and dedicated anti-air rules remain future work. See the source project's `docs/backlog.md` and `docs/sprite-production.md`.

## Generated arenas

The match opens at the Charter Grounds. Breaking the left wall carries the fight into Foundry Walk; the right wall leads to the Tide Docks. Each arena scrolls through independent generated scenery layers as the camera follows the fighters. New configurations use a 2.5-second travel sequence. The existing Reduced motion setting uses a stationary dissolve instead. See [stage art](stage-art.md) for the connected routes and layering details.

Walls fill the entire visible border. Hitstun collisions damage a hidden pool by incoming horizontal speed and stop that speed. The collision after depletion splats; strike the splat to travel. Each side has its own persistent pool, refreshed by a new arena or round. Tune **Wall health** under Development → Combo gravity & walls.
