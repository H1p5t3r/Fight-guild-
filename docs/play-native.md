# Play Fight Guild in Godot

Extract the whole game ZIP first. On Windows run `FightGuild.exe`; on Linux run `FightGuild.x86_64` (use `chmod +x FightGuild.x86_64` if your unzip tool loses executable permissions). Keep the `.pck` and native library beside the executable. These x86-64 Windows/Linux packages do not require a browser, Node or a separately installed Godot editor.

For the editable project ZIP, import `godot/project.godot` into **Godot 4.6.3**, then press F5. The archive includes native binaries for the platforms built. The complete repository, including concept references, is at https://github.com/H1p5t3r/Fight-guild-/tree/feat/godot-combat-lab.

## First match

Choose Anvil, Hammer, Smoke, Tapper, Shark or Fillet. Each player independently chooses simplified controls. Enter training, walk toward the opponent and try the five buttons. The dummy can stand, guard, crouch guard or run a practice sequence. Switch to Local versus for a second player.

| Action | Player 1 keyboard | Player 2 keyboard | Gamepad |
| --- | --- | --- | --- |
| Movement / jump / crouch | WASD | Arrows | D-pad or left stick |
| P | J | Numpad 1 | Bottom face button |
| K | K | Numpad 2 | Left face button |
| S | L | Numpad 3 | Top face button |
| Hs | I | Numpad 5 | Right face button |
| D | O | Numpad 6 | Right shoulder |
| Dash macro | Space | Numpad 0 | Left shoulder |
| Simple modifier | Left Shift | Numpad + | Left trigger |

With simple controls enabled, hold the modifier and use forward+P, down+S or up+Hs. Directions are relative to facing. Traditional 236P, 236S and 623Hs still work. Buttons also have crouching, forward command-normal and air variants. These kits are provisional.

## Iterate

- **Pause / +1 frame:** inspect startup, active frames, hitstop and recovery. Generated windup and active images follow simulation timing.
- **Move editor:** choose a fighter/move, adjust values, then Apply & reset. Save locally writes the complete six-fighter set. Export/import JSON for a portable backup. Old two-fighter schema-1 saves retain Anvil/Hammer edits and supply defaults for the others.
- **Sprite review:** compare windup and active poses at the same body scale. Some details/effects still need consistency cleanup; complete animation sequences are not present.
- **Hitboxes:** overlays show authoritative collision shapes. Sprite weapons and smears do not decide hits.

Saves use Godot's `user://` directory: normally `%APPDATA%/Godot/app_userdata/Fight Guild` on Windows and `~/.local/share/godot/app_userdata/Fight Guild` on Linux. The cloud launcher uses writable directories under `FIGHT_TOOLS`. Export move JSON before moving between machines.

## Direct online prototype

Both players need the same build and move data. Choose your Player 1 fighter locally. One player hosts UDP port 7000; the other enters that computer's address and joins. Both use Player 1 controls locally. Allow that UDP port through the host's firewall as needed. `127.0.0.1` works only for two processes on the same computer.

This direct ENet connection uses rollback, two frames of input delay, bounded prediction and confirmed-state checks. No room server is needed. Editing is locked while connected. Leave and reconnect for a rematch. Matchmaking, automatic NAT traversal and reconnect are backlog work; direct Internet hosting may require router configuration.

## Validation and limits

Linux native rendering, keyboard input, all 30 basic buttons, editing, sprite loading, rollback and two independent UDP peers are tested. Windows is cross-compiled/exported; Windows gameplay and physical controllers need hardware playtesting. PS5 requires approved console access and a compatible Godot port provider; no PS5 build is included.

The buffer is an original configurable implementation, not verified Strive parity. Character mechanics, distinct move animations, meter, throws, universal overheads and dedicated anti-air rules remain future work. See the source project's `docs/backlog.md` and `docs/sprite-production.md`.
