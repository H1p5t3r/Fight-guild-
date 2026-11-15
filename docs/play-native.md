# Play Fight Guild in Godot

Extract the whole game ZIP first. On Windows run `FightGuild.exe`; on Linux run `FightGuild.x86_64` (use `chmod +x FightGuild.x86_64` if your unzip tool loses executable permissions). Keep the `.pck` and native library beside the executable. These x86-64 Windows/Linux packages do not require a browser, Node or a separately installed Godot editor.

For the editable project ZIP, import `godot/project.godot` into **Godot 4.6.3**, then press F5. The archive includes native binaries for the platforms built. The complete repository, including concept references, is at https://github.com/H1p5t3r/Fight-guild-/tree/feat/godot-combat-lab.

## Choose a mode

The game opens at the main menu. Use the mouse, arrow keys/Enter, or a controller's D-pad/A to navigate; Esc/B goes back. Menus use the supplied Guild Ball panel/font style; Controls opens in its separate warm Settings skin.

- **Matches → Local versus → Fighter select → Start match:** two players, a full-width arena, and a results screen with Rematch and Change fighters.
- **Matches → Online versus → Fighter select → Connection:** choose only your local fighter, then Host or Join. The match starts after both peers connect successfully.
- **Training → Fighter select → Start training:** choose your fighter and a dummy, then practice with dummy behavior, starting Momentum, input history, hitboxes, pause, frame step and reset controls.
- **Development → Fighter select → Open combat lab:** practice controls plus the move editor, sprite review, buffer/Momentum tuning, data import/export and rollback workbench.

Choose Anvil, Hammer, Smoke, Tapper, Shark or Fillet. Each player independently chooses simplified controls. The training dummy can stand, guard, crouch guard, run a practice sequence, use Faultless Defense, repeat Hs attacks or attempt reversals after guarding.

**Esc / gamepad Start / Menu** opens the match menu. Offline rounds freeze there; Resume keeps the exact round, Restart starts over, and Change fighters can be canceled without losing the round. Online play continues with neutral input while the menu is open; leaving closes the connection. Applied move edits survive navigation between modes. Save locally to retain them after quitting.

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
| Dash macro | Space | Numpad 0 | Left shoulder |
| Simple modifier | Left Shift | Numpad + | Left trigger |
| Faultless Defense (hold away too) | Q | Numpad Enter | Right trigger |

With simple controls enabled, hold the modifier and use forward+P, down+S or up+Hs. Directions are relative to facing. Traditional 236P, 236S and 623Hs still work. Buttons also have crouching, forward command-normal and air variants. These kits are provisional.

Hold back + any two of P/K/S/Hs as an alternative FD chord. Momentum builds through approaching, attacking and defending; FD is its only spend. Its three equal HUD sections fill continuously to 100%; the divisions do not alter gain or costs. Select **Start Momentum: 50%** in training to try it immediately. FD prevents chip damage and adds pushback. Empty meter falls back to ordinary guard. Negative Penalty is deferred.

Block animations distinguish negative/even attacks, plus-on-block pressure and guard break. Enable **Guard break on block** for a move to test its exposed stance: backdash inputs during the stun are discarded and blockstun grab protection is absent. Throws themselves are future work. See [Momentum and defense](momentum-defense.md).

Combos show a large number behind the fighters on the attacker's current side. **COUNTER** means startup/active interruption; **PUNISH** means a hit during recovery; **REVERSAL** means an eligible move started on the first actionable frame after stun. Try **Attack loop** or **Guard → reversal** for practice. [Combo and timing rules](combat-feedback.md) cover the editable +4 hitstun/+3 hitstop counter defaults and five-frame reversal input buffer. Reversal timing does not grant invulnerability.

## Iterate

Enter **Development** for move editing and sprite review. Training also offers pause, frame step and hitboxes.

- **Pause / +1 frame:** inspect startup, active frames, hitstop and recovery. Generated windup and active images follow simulation timing.
- **Development workbench:** scroll below the editor controls for the rollback latency check and gatling reference.
- **Move editor:** choose a fighter/move, adjust values, then Apply & reset. Save locally writes the complete six-fighter set. Export/import JSON for a portable backup. Old schema-1/2/3 saves retain edits and supply defaults for new fields/fighters.
- **Sprite review:** compare windup/active or any of the three defensive contact/settle pairs at the same body scale. Some details/effects still need consistency cleanup; complete animation sequences are not present.
- **Hitboxes:** overlays show authoritative collision shapes. Sprite weapons and smears do not decide hits.

Saves use Godot's `user://` directory: normally `%APPDATA%/Godot/app_userdata/Fight Guild` on Windows and `~/.local/share/godot/app_userdata/Fight Guild` on Linux. The cloud launcher uses writable directories under `FIGHT_TOOLS`. Export move JSON before moving between machines.

## Direct online prototype

Both players need the same build and move data. Go to **Matches → Online versus**, choose your local fighter and continue to the connection screen. One player hosts UDP port 7000; the other enters that computer's address and joins. Both use Player 1 controls locally. Allow that UDP port through the host's firewall as needed. `127.0.0.1` works only for two processes on the same computer.

This direct ENet connection uses rollback, two frames of input delay, bounded prediction and confirmed-state checks. No room server is needed. Editing is locked while connected. Use **Return to online lobby** after a round and host/join again for a rematch. Cancel a pending connection to retry; failures and disconnects return to the connection screen with an explanation. Matchmaking, automatic NAT traversal and reconnect are backlog work; direct Internet hosting may require router configuration.

## Validation and limits

Linux native rendering, menu routes/back paths, keyboard and simulated-controller navigation, pause/rematch, connection recovery, all 30 basic buttons, editing, sprite loading, rollback and two independent UDP peers are tested. Windows is cross-compiled/exported; Windows gameplay and physical controllers need hardware playtesting. PS5 requires approved console access and a compatible Godot port provider; no PS5 build is included.

The buffer is an original configurable implementation, not verified Strive parity. Character mechanics, distinct move animations, throws, universal overheads and dedicated anti-air rules remain future work. See the source project's `docs/backlog.md` and `docs/sprite-production.md`.
