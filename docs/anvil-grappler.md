# Anvil: Bulwark grappler prototype

This is the native Godot mechanics pass. The refined **C / Bull** body is selected, with less overall height and width than the first sheet while retaining its muscular torso. **Shield 1 / Guild Original is selected.** The base idle is **D / High Clamp**, with slightly narrower footing and a broad closed-jaw toothy grin. `art/characters/anvil-grappler-v1/high-clamp-hand-corrected.png` records the approved direction with the user's requested missing-finger correction. Neutral carry exposes the shield’s inner face, left-hand grip and straps; guard/Drive turns its armored face outward. The free right elbow stays bent roughly 90°, with an upright hand reaching to grab: four fingers and one opposing thumb. The approval sheets are in `art/characters/anvil-grappler-v1`; they are not runtime sprites. Existing runtime Anvil artwork remains provisional while the selected idle is carried into production sprites.

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

Ground command grabs do not catch airborne/prejump targets or ordinary hitstun, blockstun, landing lock and throw immunity. They cannot be manually teched. Their damage is paid once at the slam, followed by hard knockdown. The A/B staging is saved pair-root movement; final attacker/receiver artwork will follow the approved choreography using the selected High Clamp reference.

Sky Foundry never catches a grounded target. It can catch an airborne juggle; existing combo scaling carries through the entire capture. The super spends 50% at activation, including on whiff, and does not refund attacker Momentum on hit. The freeze stops both fighters, projectiles, round time, status timers and hitstop while input samples continue. It drives the existing screen-rip cut-in from saved simulation time, including on rollback. Its provisional invulnerability lasts through the catch window.

## Implementation and verification

- Schema/core version stays 27 with the existing 148 move fields; rules revision is 6. Character extension policy 2 is Anvil's cancel policy. Action types 7–12 select grappler grab, anti-air super, armored rush, brake, shield stance and shield descent.
- Armor carry, the super clock and initial capture height are snapshot state. Snapshot byte-size checks reject the old layout; the rules fingerprint prevents mixed-build matches.
- `scripts/author-anvil-kit.py` produces the native batch and starter tuning. Other fighters retain their preceding batch data.
- Generate with `python scripts/generate-combat-data.py --native-only` while the website is frozen. Browser editor files and deployment remain unchanged. The frozen web JSON adapter does not support Anvil policy 2 yet; use the native editor for this kit until web work resumes.
- Native C++ and Godot tests cover inputs in both directions/player slots, armor exhaustion and transfer, leg contacts, normal cancel restrictions, grabs, multi-hit descent, super cost/freeze/capture, damage scaling and rollback. A direct WASM-core test checks the same saved combat state without changing the frozen editor.

Remaining art work: hammer-free production sprites based on the selected High Clamp idle, attack clips timed to the stats, paired A/B grab clips, and the super's final choreography. Keep the largest motion between final startup and first active; use held poses and fixed body calibration, not independently resized frames.
