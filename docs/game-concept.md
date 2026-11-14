# Game concept

## Agreed direction

- A 1v1 fighting game using Guild Ball characters, with Guilty Gear Strive as the closest reference.
- No ball, goals, or sports mechanics.
- Captains and their individual identities drive the roster. Squadies may be considered if they fill a needed fighting-game archetype.
- Initial roster: Anvil, Smoke, Tapper, Shark, Fillet, and Hammer.
- Remake all six reference guides in the new game's visual style.
- Retain each character's original miniature weapons, using external reference research where the supplied concept sheets differ.

## Initial character proposals

These are working translations discussed during planning, not finalized movesets.

| Fighter | Proposed role | Distinction |
| --- | --- | --- |
| Anvil | Defensive powerhouse | Holds ground and punishes commitments; his original shield supports this identity. |
| Smoke | Setplay / okizeme specialist | Uses knockdown time to establish cloud setups, then exploits them through teleport positioning and timed threats. |
| Tapper | Close-range brawling grappler | Threatens throws and sustained close pressure; retain his hooked staff in the kit. |
| Shark | Mobile hit-and-run fighter | Creates openings through movement and evasive positioning. |
| Fillet | Bleed-driven rushdown | Opens a wound and sustains aggressive offense. |
| Hammer | Advancing bruiser | Takes ground and converts clean hits into forceful knockdowns. |

Anvil holds ground while Hammer takes it. Shark creates openings through movement; Fillet sustains pressure through bleed. These are intended distinctions to test, not established balance facts.

## Smoke's specific design requirement

The user explicitly refined Smoke from general setup/space control into an **okizeme specialist**. Her clouds and teleports should depend on setting up during knockdown offense.

Proposed loop: earn a knockdown → place clouds → threaten a wake-up mixup through teleport positioning → convert into another setup.

Her neutral and defense, teleport restrictions, cloud activation timing, and defensive counterplay are still to be designed. Avoid treating fullscreen fog or generic keep-away zoning as her core identity.

## Implementation decisions

- Target platforms: PC and PS5. The current executable prototype runs natively in Godot on PC.
- Start with 2D sprites; later use 3D models on a 2D gameplay plane.
- Five attack buttons: P, K, S, Hs, D, plus a dash macro and a simplified-input modifier.
- Traditional motions are the original control design. Simple input mappings are per move, enabled independently at character select.
- Unified gatlings and the universal same-button command-normal cancel rule are specified in [combat-rules.md](combat-rules.md).
- Rollback is an architectural requirement. The initial core includes complete snapshots and is exercised with delayed inputs and a room relay.
- A move editor inside the playable training interface supports direct tuning and JSON import/export.

## Still open

- Final movement tuning, meter, defensive mechanics, round format, damage scaling, and combo restrictions.
- Exact character moves, resources, matchups, and frame data.
- Unreal integration, console access, production online infrastructure, and the art/animation pipeline.
- Final visual approval, orthographic model sheets, and animation specifications.

The current lab uses portable C++ through a Godot GDExtension, with generated 2D sprites for all six fighters. Each has playable basic buttons, windup/active poses and provisional move data. The simulation remains independent of presentation for eventual 3D models on the 2D plane. A repeatable sprite and future-character pipeline is tracked in the backlog.
