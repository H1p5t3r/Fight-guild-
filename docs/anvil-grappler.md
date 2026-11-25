# Anvil: Bulwark grappler prototype

The native Godot build uses the approved **C / Bull** body, **Shield 1 / Guild Original** and **D / High Clamp** idle. Anvil remains the largest fighter, with less height and width than the first concept, narrower footing and a broad closed-jaw toothy grin. `art/characters/anvil-grappler-v1/high-clamp-hand-corrected.png` records the approved five-digit right hand. Neutral carry exposes the shield’s inner face, left-hand grip and straps; guard/Drive turns its armored face outward. The free right elbow stays bent roughly 90°, with an upright hand reaching to grab. Runtime sheets are in `godot/assets/fighters/anvil-bull-v2`; prompts, exposure plan and source hashes are in `art/characters/anvil-bull-v2`.

## Inputs and purpose

| Input | Move | Behavior |
|---|---|---|
| Hold D; hold forward to advance | Bulwark | 5f entry; two upper-body armor hits; 14f recovery after releasing D. Advance speed 2.2 px per action frame. |
| j.D | Falling Bulwark | Stop all horizontal momentum and hover through 9f startup, then descend at 9 px per action frame. Wide, five-hit shield attack; 22f landing recovery. |
| 63214P | Foundry Drop (approved grab A) | 5f startup, 333 damage, 88-tick catch/lift/powerbomb sequence, hard knockdown. |
| 63214K | Iron Turn (approved grab B) | 6f startup, 333 damage, 92-tick catch/turn/sweeping throw, switches sides, hard knockdown. |
| [4]6Hs | Iron Advance | Hold back/down-back/up-back for 30f, then forward + Hs. 23f startup, one intrinsic armor hit, advancing shield strike. |
| P during Iron Advance | Plant | Brake during the approach. Stops movement, removes armor, 17 locked frames. |
| 63214Hs | Sky Foundry | Provisional anti-air command-grab super: 50% Momentum, 54-tick screen freeze, 5f startup, long airborne-only capture and 112-tick slam sequence. |
| 4P+K / 6P+K | Ordinary throws | Retain 2f startup, 40-tick grip and the six-tick tech window. |

Half-circle-back recognition accepts the full 63214 and the cardinal 624 path; 214 alone is insufficient. Motions mirror with facing. Simple-mode shortcuts are modifier + 4P / 4K / 4Hs for the grabs, modifier + 6Hs for Iron Advance. All tuning here is provisional.

## Armor contract

- Bulwark's armor starts when the shield stance becomes active. It does not block, refresh while held, or award entry meter.
- Any strike touching a leg hurtbox bypasses upper-body armor, even if it also overlaps the torso. Lows and throws also bypass it. Head, torso/arms and upper extensions can absorb hits.
- An absorbed hit still deals damage and causes shared hitstop; it does not interrupt Anvil or push him back.
- A direct cancel from active Bulwark into a special or command grab transfers `min(1, unspent stance hits)`. Exhausting both stance hits transfers nothing.
- Transferred armor is upper-body-only and lasts through startup/active frames, never recovery. It cannot be accumulated or passed through another cancel.
- Iron Advance's own one-hit armor can absorb a low. Bulwark adds at most one upper-body hit to it; the added hit is consumed first when eligible.
- Two small shield marks above Momentum show currently available armor. Falling Bulwark has no armor.

The air slam has independent hit groups starting on active frames 1, 4, 7, 10 and 13. Its last group can connect later in the descent if it has not connected already; it cannot repeatedly hit after being spent. Landing ends all attack boxes immediately and begins recovery.

## Normals, captures and super

Anvil's grounded shield normals reach up to 245 px. The shield has no hurtbox. Normals do not chain into each other or jump-cancel; they special-cancel on contact. Standing S retains close/far context. 2S remains a hard-knockdown sweep and is -15 on first-active block.

Ground command grabs do not catch airborne/prejump targets or ordinary hitstun, blockstun, landing lock and throw immunity. They cannot be manually teched. Their damage is paid once at the slam, followed by hard knockdown. The A/B staging uses saved pair-root movement and separate catch/lift/slam drawings. Successful captures hold their finish through release hitstop and owner recovery; missed grabs only reach and withdraw.

Sky Foundry never catches a grounded target. It can catch an airborne juggle; existing combo scaling carries through the entire capture. The super spends 50% at activation, including on whiff, and does not refund attacker Momentum on hit. The freeze stops both fighters, projectiles, round time, status timers and hitstop while input samples continue. It drives the existing screen-rip cut-in from saved simulation time, including on rollback. Its provisional invulnerability lasts through the catch window.

## Implementation and verification

- Schema/core version stays 27 with the existing 148 move fields; rules revision is 6. Character extension policy 2 is Anvil's cancel policy. Action types 7–12 select grappler grab, anti-air super, armored rush, brake, shield stance and shield descent.
- Armor carry, the super clock and initial capture height are snapshot state. Snapshot byte-size checks reject the old layout; the rules fingerprint prevents mixed-build matches.
- `scripts/author-anvil-kit.py` produces the native batch and starter tuning. Other fighters retain their preceding batch data.
- Generate with `python scripts/generate-combat-data.py --native-only` while the website is frozen. Browser editor files and deployment remain unchanged. The frozen web JSON adapter does not support Anvil policy 2 yet; use the native editor for this kit until web work resumes.
- Native C++ and Godot tests cover inputs in both directions/player slots, armor exhaustion and transfer, leg contacts, normal cancel restrictions, grabs, multi-hit descent, super cost/freeze/capture, damage scaling and rollback. A direct WASM-core test checks the same saved combat state without changing the frozen editor.

## Production art registration

`python scripts/register-anvil-bull.py` registers 17 unchanged generated atlases: idle/crouch, walk/back walk, step dash/backdash, shield advance, all 26 enabled actions, hit/guard reactions, and face-up/face-down recovery. It writes native atlas regions, pivots, anatomical boxes and white-shield pause masks. Run the native-only combat generator afterward. It does not write the frozen website.

The 173 attack exposure keys use the existing startup/active/recovery stats, with the main strike change on first active. Seven paired tracks cover ordinary throws, A/B and Sky Foundry. The stance advances its shuffle from saved travel while D is held, avoiding a frozen animation clock. Atlas scale stays fixed across each sheet; source gutters and anatomical landmarks determine the crops and pivots. Shield art does not extend hurtboxes; every pose uses three body boxes plus at most one extension.

`godot/tests/anvil_art_test.gd` checks all enabled actions in both facings, first-active timing, stance travel, capture/release drawing selection, rollback and render-state immutability. `python scripts/capture-anvil-art.py` records a native 60 FPS review with checked hit/block/whiff outcomes. The review is `exports/FightGuild-Anvil-Bull.mp4`.
