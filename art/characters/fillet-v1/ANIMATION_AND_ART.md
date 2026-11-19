# Fillet v1.0 — animation, movement and art implementation contract

## Deliver the complete playable character

Implement the complete Fillet animation set in this document. These are selected v1.0 production decisions. Author all 26 actions, their legal transfers, every locomotion/reaction state, five paired success sequences, and the normal-throw tech branch. Finish the playable procedural version in the same implementation pass if polished raster production is slower. Do not stop for another pose-selection round, leave attacks with only one generic active drawing, or make finished raster art a prerequisite for delivering the functioning moveset.

Use **`FILLET_SPEC.json`** for mechanics and named transitions, **`FINAL_MOVE_VALUES.json`** for the generated scalar view, **`FRAME_GEOMETRY.jsonl`** for the exact per-frame collision view, and **`MOVEMENT_ANIMATION.json`** for movement and paired state data. Keep all four consistent. Their numeric geometry and simulation events take authority over reference pictures, overview sheets and apparent blade trails. Implement this document's directed poses against those data; never silently resize a hitbox to fit a drawing. The latest implementation baseline is supplied under **`baseline/current_source/`**. c.S→f.S and the all-cast 2S sweep migration already exist on the current branch; extend that implementation rather than recreating the obsolete pre-migration input system.

This handoff supersedes historical “proposed,” “requires approval,” and “pending sprite pass” labels in v0.2 research. The selected **short-LEFT reverse-grip rising c.S** replaces the old right-hand version. The long-RIGHT knife stays low/ready during c.S and supplies f.S. Keep those two actions visually distinct.

## 1. Preserve Fillet's identity; build reusable production assets

Retain A / Stalker: wide staggered feet, forward knee bent, rear leg extended, low forward-loaded torso, mature athletic proportions, slender arms, strong legs, short swept black hair, red shoulder/corset, ivory apron and substantial gloves/boots. Use the existing selected model and appearance-v3 material treatment. Preserve the established palette: cool black hair `#111318`, charcoal cloth `#393039`, ivory `#DDD0B1`, crimson `#A63242`; use one consistent hard-edged shadow treatment. Do not replace the selected stance with the narrower historical B/F variants.

**Anatomical RIGHT always owns the long curved knife. Anatomical LEFT always owns the short curved knife.** The short knife is reverse-gripped for c.S's selected rising cut. Retain that physical grip through its adjacent poses; a grip change, where needed for another clip, must be depicted within that clip's existing startup. Catching actions use the left forearm/pommel/closed grip, with the short blade pointing clear of the receiver. A hand does not become empty to make a throw easier to animate. Never lengthen either knife, stretch a limb, or swap the attachments across facings.

Start with the current manifest-selected Fillet material/model assets and existing registration patterns:

- `art/characters/fillet.png` and `art/characters/design-decisions.json` define identity and the selected stance.
- `godot/assets/fighters/manifest.json`, Fillet entry, identifies `appearance-v3/fillet-ready.png`, `fillet-walk.png`, `fillet-run.png`, `fillet-active.png`, `fillet-windup.png`, `fillet-signatures.png` and the existing recovery assets. Resolve files from the current checkout/manifest rather than hardcoding an old atlas crop.
- `godot/scripts/fighter_art.gd` is the current atlas presentation integration point. `scripts/generate-combat-data.py` and the existing art registration scripts demonstrate deterministic data compilation. Extend their current equivalents on the implementation branch.

The older baseline has atlases, not a complete Fillet bone rig. Reuse a newer rig if the current branch provides one. Otherwise **create the deterministic procedural rig now**: root/pelvis, ribcage, head, two shoulder/elbow/wrist chains, two hip/knee/ankle/foot chains, long-right and short-left knife attachments, hair/apron layers, and the contact sockets specified below. Preserve lengths from one master rig and solve poses by joint rotation/position within those fixed lengths. Draw the existing character's colored silhouette/material masses, not generic stick figures. Bake that rig into an atlas or render the same deterministic pose data directly in both supported previews; either route must produce the complete animation set.

Use the selected master dimensions in **`CS_GEOMETRY_RESOLUTION.json`**: each upper/lower arm segment is 2400 raw = 24px, short-LEFT steel length is 2200 raw = 22px, long-RIGHT steel length is 4300 raw = 43px, and standing reference is 150px. Retain the exact stored blade polygons, grip offsets, wrist control keys and per-frame c.S rig; the nominal lengths are not permission to substitute a differently shaped weapon. In c.S the short knife's point remains downward while the hand rises, producing the selected reverse-grip rising cut. Its first-active sweep is real blade motion, not a persistent full-height effect. Build the rest of the pose rig around those fixed dimensions and the final action geometry.

Use named sockets `pelvis`, `chest`, `head`, `left_foot`, `right_foot`, `left_hand`, `right_hand`, `left_knife_root`, `left_knife_tip`, `right_knife_root`, `right_knife_tip`, `left_forearm_contact` and `receiver_contact`. Register sockets in root-local game units. Derive them directly from the authored procedural pose; for later raster replacement, measure and store them during registration. That work belongs to Codex's production pass and does not require the user to supply measurements.

### Facing, scale and collision

Author/export two facing variants from the same anatomical rig. Mirror root-space coordinates where appropriate, but recompute near/far limb layering and use the correct front/back hand shapes. Do not obtain the entire left-facing character by swapping knife IDs or flipping an unrelated raster. The anatomical right hand remains `right_hand` even when it appears on the far side. In j.Hs and the back throw, preserve those IDs while the torso turns.

Keep the established **150-world-pixel standing reference scale**. A bent stance is visibly shorter; do not scale a crouched or prone drawing up to 150px. Use one fixed master body-height calibration and a foot/root pivot per frame; larger source cells accommodate weapon reach without changing character scale. Position the sprite from the simulation root. Locomotion/pair render offsets are `[0,0]`. The permitted attack-only ≤4px internal body settle deforms joints inside the registered anatomical envelope; it is not an extra root offset or a second application of gameplay travel.

Body hurt regions correspond to flesh/clothed body masses and extended limbs; knives, cloth tails, hair and effects do not create extra hurt regions. When a hurt mask disables a region, keep the body visible; do not make it disappear to visualize invulnerability. Hit rectangles remain authored gameplay geometry. Place the relevant knife/boot/contact silhouette in the intended corridor, show vulnerable limbs where their extension boxes exist, and treat FX as non-authoritative decoration.

### Registered Stalker standing envelope and foot continuity

Use the registered c.S master rig's **same broad Stalker base anatomy** for the final ready profile and every standing attack key that previously used the old default standing body. This includes f.S, Crown's standing load, Heel's shared standing frames 1–5 and Skim's standing entry/capture/recovery. The final frame geometry contains these replacements; do not retain the old narrow default behind the new drawings.

| Standing body region | Exact raw rectangle `[left,bottom,right,top]` | World pixels |
|---|---|---|
| Legs | `[-5400, 0, 6000, 6200]` | `[-54, 0, 60, 62]` |
| Torso/arms | `[-3600, 5200, 3500, 11800]` | `[-36, 52, 35, 118]` |
| Head | `[500, 11800, 3200, 14600]` | `[5, 118, 32, 146]` |

This shared envelope accommodates the wide planted stance and normal support-phase variation across c.S→f.S and other standing transfers. Preserve the incoming planted foot's identity and contact point: solve its leg by deterministic IK relative to the **actual moving gameplay root**, then collect the free foot within the destination's existing startup. Do not first snap both boots into a narrower idle pose. Retain the planted contact only for its remaining authored support portion; release/pivot it at the natural support transition before the fixed limb/envelope limit is exceeded. A foot is not pinned in world space for an entire moving attack. Once it lifts, the next authored plant becomes the contact anchor. Save or deterministically derive the anchor/support phase so rollback reproduces the same placement.

The free-foot collection and hip/shoulder preparation run concurrently on destination frame 1 onward. They add **no root lunge, displacement correction, extra step duration, startup delay or attack cancel padding**. Preserve the two registered knife hands and the low-ready long RIGHT while short LEFT retracts from c.S. Keep the destination's specific extension boxes and exact weapon/contact path; the broad base does not grant extra attack reach. Keep crouch and air profiles, explicitly specialized body shapes, 6P's authored protection masks and all per-action pushbox timelines unchanged unless the final numeric data explicitly selects them. The standing hurt envelope is not a request to widen the gameplay pushbox.

## 2. Drive all motion from saved simulation state

Use three explicit clocks:

| Clock | Advances | Use |
|---|---|---|
| World/input tick | Each 60Hz simulation step, including hitstop | Input edges/history and the ordinary 5-world-tick buffer; continuous FD payment follows the shared engine rule |
| Unfrozen combat tick | Pauses during shared hitstop and stage travel | Bleed duration/growth, projectile simulation, shared paired clock |
| Fighter action tick | Also pauses on that fighter's held counter-slow ticks | Attack age, pose age, stun, movement, dash stages, landing and individual recovery |

Select body poses solely from those saved clocks/phase counters and actual travel. Render refresh or a tween must not progress a body during hitstop, introduce an extra anticipation tick, move the root independently, or finish recovery early. Hair/apron follow-through must also be a deterministic function of the saved pose/clip phase; do not attach free-running cloth time to the renderer.

An action with startup S, active A and recovery R uses pre-active frames `1..S−1`, active `S..S+A−1`, recovery `S+A..S+A+R−1`; total `S−1+A+R`. Frame 1 is the accepted-input tick. Retain the last recovery drawing on that last locked tick. Neutral or a newly accepted action starts on the following legal tick. Cancel bounds refer to **completed source frames**, so an accepted cancel after source frame N displays destination frame 1 on the next tick. The new clip replaces the old clip; no transition padding is appended.

Hitbox keys use active-relative frames; hurtbox keys use absolute action frames. Build the actual pose-key set from the union of: the directed anchors below; every hurt-profile/extension transition; every hitbox-shape transition; root-track/facing boundaries; low-crush/profile boundaries; and release/landing events. Add drawings or procedural joint keys at those boundaries **without adding gameplay ticks**. Hold a resolved key until the next key unless an explicit deterministic per-tick rig track is authored. For example, f.S's arm must already be out on frame 7 even though its original anchor list had labels at 4 and 8.

For each strike, draw anticipation, pre-contact, active, follow-through, recovery, retraction and last-locked poses. The contact insert is conditional: freeze the exact resolved contact pose for the declared shared hitstop, then resume the same clip clock. Whiff has no impact hold or hit spark. Block can add a small local wrist/shoulder compression within the same geometry; it cannot add root recoil or reduce recovery. A strike/reaction interrupt replaces the action immediately. Counter slow holds the already resolved pose on held ticks; it does not play a slow renderer tween.

### Input and interrupt ordering to preserve

Process a **fresh or still-buffered valid Up before grounded FD**, when a jump is otherwise legal. Do not consume Up merely because FD was requested. Consume the accepted jump edge, exit FD, suppress grounded FD payment on that accepted-jump tick, and enter prejump immediately. Preserve the 5-world-tick buffer and existing no-held-Up-auto-jump rule. This gives command-grab defense a visible accepted prejump instead of making continued FD silently swallow a valid fresh jump. It does not grant jump cancels to actions that lack them.

Resolve current mechanics before selecting presentation: stage-travel/round state; confirmed pair/tech state; release recovery; actual hit/block/down/wake/landing reaction; live attack; committed dash/prejump; then free locomotion/turn/stop/idle. If two states can exist simultaneously, use the final combat state selected by core, not a renderer guess based on the last button. A valid attack/jump interrupt discards a decorative turn, crouch transfer, stop or empty-landing clip immediately.

## 3. Locomotion and all neutral transfers

Neutral lead foot is anatomical left, with the right foot rear. On a moving entry, preserve the actual current support foot: never insert an extra planting step just to reach the neutral convention. Track support identity and gait phase explicitly. For a kick that needs the right leg free, transfer support within that attack's existing preparation; do not add a delay or relabel the legs.

### Idle, crouch, walk, run and stop

| Clip | Exact keys/clock | Directed body action and legal transfer |
|---|---|---|
| Idle | 48 actor ticks: I0 1–12, I1 13–24, I2 25–36, I3 37–48; loop | I0 low exhale; I1 small ribcage rise; I2 returns through the exhale; I3 settles. Feet and knife registration remain fixed. Reset to I0 on entry; any legal input replaces it. |
| Crouch entry | CE0 tick 1, CE1 tick 2 | CE0 lowers hips over the planted foot; CE1 completes the compact seat. Crouch guard/push/hurt state applies immediately on tick 1. Both drawings must already fit that state; no standing head is left behind for a visual blend. Fully interruptible. |
| Crouch hold | CH0 1–16, CH1 17–32; loop | Asymmetric compact brace, short LEFT close, long RIGHT low/rear; small breathing change only. Root is stationary unless actual mechanics move it. |
| Crouch exit | CX0 tick 1, CX1 tick 2 | Open the hips and recover Stalker. Standing guard/push/hurt state applies immediately on tick 1; attacks/jump can interrupt before tick 2. |
| Forward walk | WF0–WF7; each covers 1900 raw travel, cycle 15200 = 152px | Alternate two real gait halves; front knee accepts weight, rear heel lifts, pelvis passes over the support, then the opposite leg repeats. Knives stay controlled; no exaggerated arm swing. |
| Backward walk | WB0–WB7; same 152px cycle | Separate retreating drawings played forward in order: rear foot reaches back, accepts weight, front foot collects. Remain opponent-facing. Do not reverse the forward-walk playback. |
| Run | R0–R7; each covers 3360 raw travel, cycle 26880 = 268.8px | Distinct contact/compression/drive/flight and the other leg's full repeat. Torso inclines from hips; long RIGHT trails low, short LEFT stays close. Do not lock one leg into a repeated half-cycle. |
| Stop settle | SS0 tick 1, SS1 tick 2, SS2 ticks 3–4 | Stop gameplay movement immediately when the locomotion rules do. SS0 catches weight over the current support, SS1 collects the free foot, SS2 settles Stalker. Use ready collision and **zero gameplay lock**. A fresh action wins immediately; hold no invisible extra skid. |
| Turn | T0 tick 1, T1 tick 2 | T0 pivots hips/shoulders over current support; T1 reaches new-facing Stalker. Facing changes on the eligible free tick before relative input interpretation. No action delay. Keep the physical knife hands intact. |

Use **actual voluntary distance after wall/push resolution**, not input duration or absolute stage x, to advance walk/run gait. Zero travel freezes its phase. Preserve normalized phase and support identity between walk/run, between speeds, and on a direction reversal; choose the corresponding backward key instead of reversing time. Preserve the phase across the four-tick stop and reset after six idle actor ticks. Hit/round reset discards the old locomotion continuation. Idle begins logically as soon as a stop is free; stop-settle is a presentation overlay on that legal state.

Use the following repeatable eight-key support schedule for each gait: 0 left contact, 1 left compression, 2 left drive/right passing, 3 right preparation, 4 right contact, 5 right compression, 6 right drive/left passing, 7 left preparation. Backwalk uses the same alternating support identities with the retreating free-foot trajectory. For run keys 3 and 7, represent a brief flight silhouette while gameplay remains a grounded run; do not create root y, jump immunity or a new collision state.

### Backdash, jump and air dash

| Clip | Exact key ranges | Directed pose and control contract |
|---|---|---|
| Backdash | BD0 1–2; BD1 3–4; BD2 5–6; BD3 7–8; BD4 9–10 | Load rear support; withdraw hips with guarded knives; rear plant; front foot follows; Stalker settle. Root y remains 0. Travel is −850 raw/tick (−977 with bleed) in locked entry facing. Frames 1–4 reject attack/jump/guard/FD. Frames 5–10 permit legal attack/jump/FD and back guard. It has no invulnerability, semi-air or low crush. A legal cancel inherits the real velocity under destination inertia. |
| Prejump | PJ0 1–2; PJ1 3–4; takeoff on next tick 5 | Compress over current support, then extend legs while feet remain at the actual ground root. Accepted input tick is tick 1/PJ0. No attack/guard/FD. Ground-throw immunity follows the accepted prejump state; it is not caused by a drawn hop. Same-direction incoming momentum can continue horizontally. |
| Early ascent | JA0 while raw `vy > 600` | Gather knees after actual takeoff; pelvis follows the ballistic root. Long RIGHT low/outside thigh, short LEFT close. |
| Late ascent | JA1 while `0 < vy <= 600` | Open the tuck slightly as upward speed falls; no hovering pose timer. |
| Apex | JP while `−85 <= vy <= 0` | Brief balanced airborne silhouette selected from velocity, not a fixed pause. Gravity continues. |
| Early descent | JD0 while `−600 <= vy < −85` | Lower the feet toward eventual landing; retain the current forward/backward travel. |
| Fast descent | JD1 while `vy < −600` | More prepared leg extension and torso brace; no change to fall speed. |
| Air-dash pause | ADP0 overall 1–2; ADP1 3–4 | Compact arrest, then align body to saved dash direction. `vx = vy = carry = 0`, gravity paused; no attack, jump, ordinary guard or FD. Inputs still sample/buffer. |
| Air-dash burst | ADB0 overall 5–6; ADB1 7–8; ADB2 9 | Drive body forward; trail legs/knives; gather into descent. Five burst ticks at raw vx 2000, or 2200 with bleed, in the saved direction. Set burst velocity before checking frame-5 inputs; legal attack/FD can replace it, ordinary air guard is allowed. No additional air jump or second dash. |
| Natural post-dash coast | From overall tick 10 | Before inputs, cap both vx and carry to raw 650/715 while preserving sign, then use airborne ascent/apex/descent poses. Do not continue the 2000/2200 burst offscreen. Expiring bleed clamps to 650. A run jump that did not naturally finish an air dash does not receive this cap. |

Fillet has no additional air jumps and one forward air-dash use per airtime. Air-jump-cancel flags do not create an extra quota. j.P/j.K/j.S may use a legal forward air-dash cancel if the shared use remains. Natural dash completion resumes gravity after final-burst integration; downward displacement starts on the following tick. An attack accepted during burst uses the burst vx through its own inertia and attack friction; it does not apply the later natural-coast clamp first.

### Landing, FD and locomotion interruption

| State | Keys/clock | Required result |
|---|---|---|
| Empty landing | EL0 contact tick, EL1 next tick; decorative | Toe/heel absorption then ready. Zero added gameplay recovery; a legal grounded input immediately replaces the drawing. Reset air quotas once on actual floor crossing. |
| Air-action landing | L locked actor ticks; AL index `floor((t−1)×3/L)` | AL0 compresses into crouch, AL1 gathers knives/feet, AL2 readies the rise. Use L=3 for j.P or a previously completed air action; L=4 for landing during j.K/j.S; L=6 for j.Hs. L3 ranges 1/2/3; L4 ranges 1–2/3/4; L6 ranges 1–2/3–4/5–6. No attack/jump/guard/FD until L+1. |
| Floor vs air attack | Simulation event, before contact | Floor crossing cancels the air normal before same-tick attack detection; display landing instead of a last grounded slash. No invented landing hit. |
| Ground FD | Actual legal FD state | Stop locomotion and clear carry. Use the correct standing/crouch guard shape with a separate shield effect. Fresh accepted Up exits it into prejump before grounded FD processing. |
| Air FD | Actual legal FD state | Cancel dash, retain actual horizontal vx, resume gravity and use air guard; no added hovering. |
| Hit | Immediate reaction event | Discard attack/locomotion/turn/stop and their continuation token. Display actual hit reaction at once; no easing out of the old move. |

Bleed scales voluntary walk/backwalk, run cap/acceleration and ground step/backdash by 115%, and forward air-dash speed by 110%, with integer truncation. Base walk/backwalk is 380 raw/tick, run cap 1120, acceleration 120, backdash 850; eligible bleed values are 437, 1288, 138 and 977. Attack inertia percentages, attack friction 90, authored root tracks, gravity 85, jump vertical velocity 1450, horizontal jump steering 380, pushback and grab reach are unchanged. Use the faster physical travel to drive gait naturally; do not speed the attack clips or apply a second bleed multiplier to carried velocity.

At attack entry choose the larger-magnitude eligible current/carry vx, consume carry, apply the move's inertia percentage with truncation toward zero and clamp ±4000 raw. Translate by that vx plus the authored travel; then drag vx toward zero by 90 raw each advancing attack tick. The saved carry timer 5 includes its source movement tick and is usable over the next four eligible ticks. Do not repeatedly restore old run speed on later gatlings. Held forward after recovery produces walk; a valid dash input is required to run again.

## 4. Hit, block, knockdown, wake and special reactions

| State | Required keyed animation and transfer |
|---|---|
| Stable block | B0 contact/first four unfrozen actor block ticks: closed forearms and braced hip. B1 from tick 5: settled guard. Reset B0 on every new block contact. Preserve grounded crouch vs stand and air silhouette; do not force every guard into standing height. |
| Pressure block | BP0 first four block ticks: visibly compressed brace. BP1 after: held pressure posture. This expresses computed disadvantage; it adds no extra stun or root push. |
| Guard break received | GB0 first four ticks: open elbows/chest, feet losing their brace. GB1 afterward: stagger. Use existing shared broken-guard recovery rules, not a defensive backdash animation. Fillet's kit does not acquire a guard-break move merely because this receiver clip exists. |
| Ordinary grounded hit | Immediate HR impact: chest recoils away from actual attack, head follows, knives remain attached and clear. Settle only as actual hitstun advances; root follows budgeted hit motion. On stun end, choose legal input/guard/neutral immediately. |
| Counter hit received | Hold the exact HR contact pose through the shared freeze, then advance only on receiver action ticks. Do not use renderer time to shake limbs into a new hurt shape. Any screen impact is a separate non-collision layer. |
| AirReel | Air HR variant, hips displaced by actual vx/vy; arms and apron trail but keep knife attachments. Remain in AirReel until actual landing or another state; expiring hitstun alone does not resume jump idle. |
| WallSplat | Hold the wall-contact pose at actual wall x/y, with current minimum height where applied; no fake slide before the timer/physics releases it. Continue into the actual falling state afterward. |
| Reel/pull received | Aim torso/feet toward the saved pull owner while the engine supplies the root path; no independently chasing render socket. |
| Crumple received | Collapse through torso/knees for the real crumple timer, then follow its recovery transition. Do not append a new knockdown. |
| Hard down | HD face-down/prone orientation; body lies along the authored hard-down profile with weapons held clear. Hold for the exact move-authored down timer. |
| Soft down | SD face-up/supine orientation; knees/torso differ from HD and use the soft-down profile. Preserve actual side/orientation into wake or Wound. |
| Wake | Five directed poses: WK1 elbow/forearm brace; WK2 seated-to-knee gather; WK3 weight over feet; WK4 rise; WK5 ready. For duration D>1, index `floor(elapsed×4/(D−1))`, elapsed 0..D−1; D=1 uses WK5. Map anatomy WK1→profile0, WK2→profile1, WK3→profile2, WK4/WK5→profile3 of supplied wake profiles; the final ready profiles coincide. No action before the true unlock. |
| Paired recovery received | Use the role-specific sequence in section 7; ordinary throw/cashout does not enter HD/SD or append wake. |
| Wall-break travel | StageTravel owns the cinematic path and pauses ordinary combat. Do not let an attack/recovery clip keep ticking beneath it. Resume from the actual reset state. |
| Round resolved | Hold the resolved state until the existing scene ceremony takes ownership; do not keep walking or restart attack loops behind the result. |

Guard/FD and strike interruptions are state-specific. A drawn closed guard does not permit guarding during locked landing or paired recovery. Conversely, a decorative stop/crouch/turn does not delay a legal guard. Victim throw grace and wake timing come from core; an animation frame cannot add or remove them.

## 5. Attack production rules and exact key schedule

Build **all 26 clips** below. A named follow-up gets its own action age and clip only after the legal source contact/window. 236S branches share **the same standing compact load on local frames 1–5**, with the same feet, root and ≤4px internal settle; **diverge on local frame 6** into Crown's tall weapon preparation or Heel's crouching drop. Use standing body/push for both through frame 5 and switch Heel to its crouched data at 6. Neither branch gets an airborne root, a low-crush flag or an extra anticipation tick. This is the selected choreography; do not claim it proves an unreactable mix.

The table lists entry, anticipation, pre-contact, first-active, active finish, recovery entry, retraction and last-locked anchors. The two 2-frame-startup throws combine entry/anticipation/pre-contact on frame 1. Add the collision-boundary keys described in section 2. These are mandatory key destinations; do not return to ready during an unfinished recovery.


| Action | Entry | Load | Pre-contact | Active | Active finish | Recovery | Retract | Last locked |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `5P` | 1 | 2 | 4 | 5 | 7 | 8 | 11 | 16 |
| `5K` | 1 | 3 | 6 | 7 | 9 | 10 | 15 | 22 |
| `c.S` | 1 | 3 | 6 | 7 | 11 | 12 | 17 | 23 |
| `5S` | 1 | 4 | 8 | 9 | 11 | 12 | 20 | 29 |
| `5Hs` | 1 | 6 | 12 | 13 | 16 | 17 | 27 | 38 |
| `2P` | 1 | 2 | 4 | 5 | 6 | 7 | 11 | 16 |
| `2K` | 1 | 3 | 5 | 6 | 8 | 9 | 13 | 19 |
| `2S` | 1 | 6 | 11 | 12 | 15 | 16 | 26 | 38 |
| `2Hs` | 1 | 7 | 13 | 14 | 18 | 19 | 30 | 42 |
| `6P` | 1 | 4 | 8 | 9 | 12 | 13 | 22 | 32 |
| `6Hs` | 1 | 9 | 17 | 18 | 21 | 22 | 33 | 46 |
| `j.P` | 1 | 2 | 4 | 5 | 7 | 8 | 12 | 17 |
| `j.K` | 1 | 3 | 6 | 7 | 10 | 11 | 16 | 23 |
| `j.S` | 1 | 5 | 9 | 10 | 13 | 14 | 21 | 30 |
| `j.Hs` | 1 | 6 | 12 | 13 | 17 | 18 | 28 | 39 |
| `236P` | 1 | 6 | 11 | 12 | 14 | 15 | 22 | 30 |
| `236S` | 1 | 4 | 8 | 9 | 11 | 12 | 20 | 29 |
| `236S>6S` | 1 | 10 | 20 | 21 | 23 | 24 | 34 | 45 |
| `236S>2S` | 1 | 8 | 15 | 16 | 18 | 19 | 30 | 42 |
| `236K` | 1 | 13 | 26 | 27 | 29 | 30 | 41 | 53 |
| `623Hs` | 1 | 5 | 10 | 11 | 15 | 16 | 29 | 44 |
| `4P+K` | 1 | 1 | 1 | 2 | 3 | 4 | 19 | 35 |
| `6P+K` | 1 | 1 | 1 | 2 | 3 | 4 | 19 | 35 |
| `5D` | 1 | 12 | 23 | 24 | 25 | 26 | 35 | 45 |
| `236D` | 1 | 11 | 21 | 22 | 23 | 24 | 38 | 53 |
| `214D` | 1 | 11 | 21 | 22 | 23 | 24 | 38 | 53 |

### Per-action production direction

Read each clip together with its exact geometry rows. The sequence paragraph supplies anticipation, contact, follow-through and retraction; the schedule above binds it to the action clock. Contact freezes the resolved pose; whiff keeps the clock moving. Every clip gets both facing variants and a last-locked drawing. Incoming support phase is preserved unless the action explicitly transfers support within its existing preparation.

#### 01. `5P` — Short check

**Entry, support and hands.** Start from Stalker/current support; move the short LEFT hand while long RIGHT stays low at the rear hip. Keep the body compact rather than stepping in.

**Sequence.** Draw the left shoulder inward, then send a short chest-height horizontal cut. Finish with the elbow just in front of the ribs; retract along the same short line, elbow before wrist.

**Collision and contact read.** Show the forward forearm whenever its hurt extension exists. Do not illuminate the right knife or add reach with a trail. Whiff passes cleanly; contact holds the same compact silhouette.

**Transfers.** The returning left arm leaves space to lower into 2P/2K, free the right leg for 5K, or close the shoulder into 6P. Use only the listed contact routes; no Wound or grab bridge.

**Movement binding:** entry inertia 40%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 02. `5K` — Step kick

**Entry, support and hands.** Collect the right knee; the left leg becomes support within the existing preparation. From run preserve incoming support first, then make that visible transfer. Short LEFT stays by the chest; long RIGHT stays outside the right hip.

**Sequence.** Fold the right knee compactly, extend the boot into the low-middle corridor, hold the shin through the active finish, then fold the knee before setting the boot back into Stalker.

**Collision and contact read.** The boot owns the hit. Keep the extended shin visibly vulnerable through recovery; knives remain inactive. Contact checks ankle/hip locally; whiff requires the same deliberate withdrawal.

**Transfers.** The collecting knee can plant for 6P/6Hs or a listed special. A gated bleed-grab entry plants for Vault or lowers for Skim only after its legal gate.

**Movement binding:** entry inertia 60%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 03. `c.S` — Inside cut

**Entry, support and hands.** Use the selected short LEFT knife in reverse grip. Start inside the two-hand gap with current feet grounded; the long RIGHT stays low/ready throughout. Transfer weight toward the left support without a new approach step.

**Sequence.** Close the left elbow toward the lower chest, then unfold one close rising diagonal with the short reverse-gripped blade. Finish the LEFT forearm high in front of the near shoulder, not a long outward reach. Retract left elbow toward the sternum.

**Collision and contact read.** Match the final v1 c.S geometry, including its left-arm exposure keys. The rising cut remains the defined mid strike, not an extra overhead or second hit. Whiff completes one small crescent; contact freezes the same hand identity.

**Transfers.** For c.S→f.S, withdraw short LEFT toward the chest while the low-ready long RIGHT begins f.S preparation. For heavies/sweep use the destination startup; for a legal jump compress knees immediately. Never animate the old raised-RIGHT c.S bridge.

**Movement binding:** entry inertia 65%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 04. `5S` — Long knife

**Entry, support and hands.** Keep current support; from neutral load the forward left leg, and from run avoid an extra planting step. Long RIGHT starts low/ready; short LEFT folds near the sternum, including after c.S.

**Sequence.** Draw the right elbow beside the waist, open the shoulder into a narrow horizontal extension, keep the reaching forearm visible through follow-through, then recover elbow and wrist to the low rear ready line.

**Collision and contact read.** Expose the arm on frame 7, retain full extension through 11, shorten it on 12–19 and retract on 20. Show the front reach contracting on the final active frame. No root lunge, stretched blade or instantly hidden arm. Whiff reads as an unsupported reach.

**Transfers.** Fold the right arm inward for the three listed heavies or special startup. A delayed bleed-grab bridge leads with the left forearm while the right hand retains its knife.

**Movement binding:** entry inertia 60%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 05. `5Hs` — Crosscut

**Entry, support and hands.** Brace over current support, normally left, and let the right foot pivot with the hips. Gather f.S's right extension or c.S's high LEFT finish into an asymmetrical two-hand preparation.

**Sequence.** Separate elbows, then cross the long RIGHT lower/forward diagonal with the shorter LEFT upper diagonal. Make one clear X contact. Hold the open chest/right shoulder commitment; uncross LEFT upward first and withdraw RIGHT low.

**Collision and contact read.** One visual cross equals the one authored hit group. Keep both weapon lengths distinct and the chest/forearm visible through exposure. Contact holds the X; whiff carries the local torso arc without extra travel.

**Transfers.** Use the X finish to coil into 6Hs or a listed special. A gated grab collects the left forearm from the upper diagonal. No flowing cut-to-Wound.

**Movement binding:** entry inertia 50%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 06. `2P` — Low stance check

**Entry, support and hands.** Enter the crouch profile immediately; keep current support while compressing. Rear right leg bears most weight. Short LEFT works at crouching torso height; long RIGHT stays low/rear.

**Sequence.** Gather LEFT beside the bent knee, make a small horizontal check, leave only the arm outside the low body, then fold the elbow straight back into crouch.

**Collision and contact read.** This is a crouching mid, visibly different from the ankle kick. No floor-cut arc, body launch or low classification implied by posture. The arm remains visible while exposed; contact checks the wrist only.

**Transfers.** Remain low for 2P/2K; rise only within the destination preparation for listed standing routes/specials. Do not insert idle or imply direct sweep/grab access.

**Movement binding:** entry inertia 35%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 07. `2K` — Ankle check

**Entry, support and hands.** Enter crouch immediately, supported by the folded left leg; extend the anatomical right boot. Keep short LEFT above the supporting knee and long RIGHT outside the rear hip.

**Sequence.** Draw the right knee in, extend the boot near the floor, retain the shin through follow-through, then fold the leg beneath the body. Keep hips behind the low extension.

**Collision and contact read.** No new slide, full spin or recovery low-profile bonus. The leg remains a visible challenge point; both knives are inactive. Whiff withdraws the boot; contact does not add a skid.

**Transfers.** Collect the leg before 6P/6Hs, a listed special or a gated grab entry. Preserve the final named routes; do not infer 2K→2S from its low silhouette.

**Movement binding:** entry inertia 45%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 08. `2S` — Sweep

**Entry, support and hands.** Use the crouched entry and existing support, normally left. Long RIGHT owns the floor-level crescent; short LEFT stays high close to the torso.

**Sequence.** Gather the long blade beside the low hips, sweep one lateral crescent, leave the right forearm extended across the front, then recover elbow before unwinding back to crouch.

**Collision and contact read.** Show a committed single low strike. The trail adds no rear/circular coverage or slide. A hit makes the target fall through actual mechanics; Fillet still completes her own recovery.

**Transfers.** No outgoing cancel. Finish the low recovery and take the next neutral input normally; do not draw a direct Wound continuation or imply sufficient Wound time from animation.

**Movement binding:** entry inertia 35%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 09. `2Hs` — Rising scissors

**Entry, support and hands.** Start inside the crouched profile with both feet on the floor. Right rear leg loads the rise; long RIGHT begins low, short LEFT nearer the ribs.

**Sequence.** Open two unequal upward blade lines into a scissors silhouette. Raise chest/elbows through the authored body profile while the feet stay grounded; hold the tall commitment, then lower RIGHT and collect LEFT into the crouched exit.

**Collision and contact read.** There is no vertical root track. Never turn the target-launching move into Fillet jumping, an invincible reversal or a second attack. Whiff leaves the high arms and lower body readable.

**Transfers.** Only listed special contact routes replace the raised finish. Otherwise complete the lowering recovery; no jump, ordinary-normal, Wound or grab exit.

**Movement binding:** entry inertia 25%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 10. `6P` — Shoulder guard cut

**Entry, support and hands.** Turn the short-knife LEFT shoulder toward the opponent over current support. Long RIGHT stays tucked low; both lower legs remain visible.

**Sequence.** Draw the head behind the left shoulder, open a compact upward-forward LEFT cut, finish shoulder-forward, then lower elbow and reopen Stalker as the protection window actually ends.

**Collision and contact read.** Use the exact hurt-mask window; do not depict full-body armor, a force field, low immunity or a hop. Exposed legs remain plausible targets. Whiff holds the compact shoulder pose before release.

**Transfers.** Unwind into listed specials on legal contact; no extra normal/jump/grab route. Releasing the pose cannot extend the protection.

**Movement binding:** entry inertia 30%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 11. `6Hs` — Chasing cleave

**Entry, support and hands.** Start a measured chase step using the authored root travel; rear right leg drives into left support. Long RIGHT coils low, short LEFT stays higher/closer.

**Sequence.** Turn the right shoulder back, cut a broad forward diagonal as the lead foot accepts weight, let the rear heel follow the real root, then collect elbow and rear foot before restoring the high LEFT guard.

**Collision and contact read.** Use only 1px per pre-active tick and 1.5px per active tick plus the stated inertia. No leap, second stride or knife stretch. Whiff is visibly committed at the advanced location.

**Transfers.** Listed specials inherit the heavy finish. Gated grabs gather the moving base into their distinct preparation; no free dash/jump/Wound exit.

**Movement binding:** entry inertia 35%; instant advance 0 raw; pre-active travel 100 raw/tick; active travel 150 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 12. `j.P` — Air check

**Entry, support and hands.** Enter from the actual ascent/apex/descent/dash or legal air cancel. No support foot: keep pelvis centered, knees lightly gathered, long RIGHT near the thigh and short LEFT at chest height.

**Sequence.** Fold the left elbow, make a compact horizontal airborne check, hold the arm while hips continue their real trajectory, then collect into the ordinary air tuck.

**Collision and contact read.** No hover, propulsion or full aerial spin. Forearm exposure stays readable. Contact freezes the whole resolved air pose; afterward resume actual vx/vy.

**Transfers.** Fold into listed j.P/j.K contact routes or an eligible unused air dash. Landing replaces the attack under the landing contract; never finish with a grounded slash.

**Movement binding:** entry inertia 70%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 13. `j.K` — Descending kick

**Entry, support and hands.** Retain the real air path; gather the right knee toward the torso while the left knee balances it. Long RIGHT remains outside/above the right thigh, short LEFT near the chest.

**Sequence.** Extend the right boot down-forward below the torso, keep the shin readable during follow-through, then fold the knee into the air silhouette or actual landing state.

**Collision and contact read.** No dive acceleration, bounce or extra low strike. Keep knives clear of the kicking line and the leg visible as vulnerable. Contact compresses locally without kicking Fillet upward.

**Transfers.** Collect the knee into j.S preparation or a legal unused air dash; no grounded continuation until actual landing recovery releases.

**Movement binding:** entry inertia 70%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 14. `j.S` — Falling knife

**Entry, support and hands.** Use the current airborne torso angle, especially j.K's collected knee. Long RIGHT prepares above/near the torso; short LEFT remains a smaller close frame above its path.

**Sequence.** Draw a down-forward long-knife diagonal through the forward/below-root volumes. Finish RIGHT in front of the hips; recover elbow upward while legs prepare for the actual floor arrival.

**Collision and contact read.** Do not add a root dive, float, victim tether or ground scrape. Show the forearm extension and landing commitment. Contact holds only the declared freeze.

**Transfers.** Carry the lowered RIGHT finish into j.Hs's torso turn, or gather for a legal unused air dash. Floor contact wins before a supposed final airborne hit.

**Movement binding:** entry inertia 65%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 15. `j.Hs` — Turning scissors

**Entry, support and hands.** Begin a compact torso turn around the current air root, often from j.S. Long RIGHT supplies the large arc and late rear silhouette; short LEFT remains the smaller inner/front accent.

**Sequence.** Separate elbows, show the broad initial front shape, then bring the long RIGHT clearly behind the torso on the authored late-rear key. Collect both elbows and knees into landing readiness during recovery.

**Collision and contact read.** Rear coverage is phase-specific, not a circular aura. Keep one hit group, unchanged flight and fixed facing; use front/back body layering instead of a gameplay facing flip. Whiff still completes the committed turn.

**Transfers.** No outgoing cancel. Finish air recovery or enter its six-tick landing lock when the floor arrives first.

**Movement binding:** entry inertia 60%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 16. `236P` — Needle check

**Entry, support and hands.** Gather a narrow two-hand bracket from current support/inertia. Long RIGHT supplies the straight mid line; short LEFT stays higher and close, framing it.

**Sequence.** Compress the right elbow inside the torso silhouette, extend the blade in one narrow check, hold briefly, then return elbow to the bracket and reopen Stalker.

**Collision and contact read.** Distinct from f.S: a compact squared special check rather than a long shoulder reach. No projectile, beam, automatic dash or blade extension. Keep the reaching arm exposed.

**Transfers.** No outgoing cancel. Whiff returns without a rekka flourish; hit/block supplies only the declared contact hold and local checked shoulder.

**Movement binding:** entry inertia 45%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 17. `236S` — Opening cut

**Entry, support and hands.** Let authored forward motion carry the closing step; preserve current support and blade position from a normal cancel. Long RIGHT leads, short LEFT stays close/high with forearm free for later legal grab approach.

**Sequence.** Coil RIGHT low, unfold a mid diagonal, and finish blade at the middle of its range so either branch can begin. If no branch is selected, recover the elbow and let the rear foot catch the actual root.

**Collision and contact read.** The branch-ready pose must keep advancing; no indefinite hold or fake second active swing. Preserve arm exposure. Whiff runs to recovery with no follow-up cue.

**Transfers.** Only actual contact/window enters Crown/Heel. On branch frame 1 use their common standing compact load for five ticks; split on their frame 6. A gated grab instead leads with LEFT. No whiff branch or Wound.

**Movement binding:** entry inertia 65%; instant advance 0 raw; pre-active travel 200 raw/tick; active travel 100 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 18. `236S>6S` — Crown cut

**Entry, support and hands.** Enter only from the legal Opening cut follow window. Preserve its feet/root. Frames 1–5 use the shared standing compact load: short LEFT near chest, long RIGHT collected at the waist.

**Sequence.** At frame 6 lift the RIGHT elbow/blade into a tall grounded coil; continue anticipation to the listed pre-contact key. Bring the long blade down through the overhead corridor, finish low-forward, then collect it back into Stalker.

**Collision and contact read.** Both feet/root stay grounded. No hop, low crush, rear coverage or second lower strike. The early shared load ends at frame 6; do not disguise the tall branch afterward.

**Transfers.** No outgoing cancel. Whiff finishes the arc; hit uses the actual target knockdown; block checks the elbow locally. Complete recovery before any neutral Wound attempt.

**Movement binding:** entry inertia 20%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 19. `236S>2S` — Heel cut

**Entry, support and hands.** Enter only from the legal Opening cut follow window. Frames 1–5 exactly share Crown's standing compact load, feet/root and body profile. Long RIGHT is collected at waist, short LEFT near chest.

**Sequence.** At frame 6 drop into the authored crouch and lower RIGHT behind the front knee. Make a tight floor-level long-knife crescent, leave the low arm extended, then collect elbow and reopen crouched hands.

**Collision and contact read.** Do not start the low profile before frame 6. This is a blade cut, not a foot sweep, long slide or blanket immunity. Keep the real low body/forearm exposure; whiff requires a visible low withdrawal.

**Transfers.** No outgoing cancel. Delay belongs to Opening cut's real window, not a frozen branch animation. Do not flow into Wound or another rekka.

**Movement binding:** entry inertia 20%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 20. `236K` — Passing cut

**Entry, support and hands.** Compact both arms before the finite pass; long RIGHT folds low along the body, short LEFT close to chest. Current action has zero incoming inertia; follow only its scripted root.

**Sequence.** Use short traveling foot poses on frames 9–20, then plant. Make the single target-relative facing update after frame 20. Unfold RIGHT for the post-pass mid cut, finish toward the opponent, then collect feet and blade in place.

**Collision and contact read.** Travel is harmless and vulnerable. No vanish, damaging travel trail, extra displacement, second facing correction or automatic cross-up. If travel did not cross, retain the correct actual side.

**Transfers.** No outgoing cancel. Whiff displays the missed cut at the final pass location; contact freezes only the cut, never the crossing itself.

**Movement binding:** entry inertia 0%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. Use the scripted root track below; do not add motion from the drawing.

#### 21. `623Hs` — Rising carve

**Entry, support and hands.** Use a standing grounded base from current support/cancel. Long RIGHT coils near the lower torso; short LEFT opens a small inner counter-shape.

**Sequence.** Gather the shoulders and right elbow, unfold the tall upward RIGHT carve, hold the high arm and stretched torso, then lower shoulder/elbow through the long recovery before settling knees.

**Collision and contact read.** Root and feet stay grounded. No reversal leap, invincibility flash, guard shell or invented air landing. The opponent may launch; Fillet does not. Whiff visibly leaves front/lower body open.

**Transfers.** No outgoing cancel. Do not bridge to an air normal, extra rising hit or Wound before normal release.

**Movement binding:** entry inertia 20%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 22. `4P+K` — Back throw

**Entry, support and hands.** From legal grounded neutral, compress the already raised LEFT shoulder on frame 1. Keep short LEFT closed-gripped, catching with forearm/pommel; long RIGHT remains low and clear. No approach step.

**Sequence.** Present the compact latch on active frames. On confirmed capture switch immediately to the Back throw pair; only that pair turns/exchanges sides. On whiff hold the unsupported forearm, retract it, settle feet without a side swap.

**Collision and contact read.** No weapon hitbox, striking fallback, shield or defensive evasion. Never move a receiver before actual capture. Keep both knives attached through the turn.

**Transfers.** No outgoing cancel. Success replaces the remaining action; an accepted normal tech uses the separate break branch instead of finishing the throw.

**Movement binding:** entry inertia 0%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 23. `6P+K` — Forward throw

**Entry, support and hands.** From legal grounded neutral, use the high LEFT forearm immediately within the very short startup. LEFT retains the short knife pointed clear; long RIGHT stays low. Stop run carry according to the zero-inertia action.

**Sequence.** Latch compactly on active frames. Confirmed capture enters Forward throw; a miss finishes the small empty-space reach and returns elbow to the high guard through full whiff recovery.

**Collision and contact read.** Do not draw the catch as a damaging knife normal, extra lunge, Wound mark or floor-slam setup. On success the receiver finishes standing, not downed.

**Transfers.** No outgoing cancel. Normal tech breaks the contact lock visibly. Neither a completed throw nor the visual recoil implies a Wound/cashout chain.

**Movement binding:** entry inertia 0%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 24. `5D` — Wound

**Entry, support and hands.** Enter standalone after prior recovery; match the low profile immediately, left foot planted and right knee/hip lowered. Long RIGHT is the small low marking motif; short LEFT stays held down/outward with forearm available.

**Sequence.** Gather RIGHT near the floor deliberately, present the low contact shape only during active time, and enter the Wound pair only on a valid current Downed overlap. Whiff finishes the small gesture alone and retracts beside the knee.

**Collision and contact read.** No direct damage slash, floor shockwave, chase, expanding radius or standing/air/waking catch. Preserve receiver prone/supine orientation on success. The persistent bleed cue begins only at pair release.

**Transfers.** No cancel into or out of Wound. Successful +0 restand returns both to free standing states; the next attack is a fresh accepted action.

**Movement binding:** entry inertia 0%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. No separate scripted root track. Inherited vx may still translate the root.

#### 25. `236D` — Vault cashout

**Entry, support and hands.** Enter from legal bleed neutral or the designated delayed contact cancel. Compress over right rear leg; LEFT forearm/pommel leads while still holding the short knife, long RIGHT trails low and clear.

**Sequence.** Use the shallow hop root exactly, with left knee leading. Land by frame 21; present the grounded upright latch on 22–23. Success enters Vault cashout pair. Failure leaves the arm out at the finite endpoint, then retracts into Stalker.

**Collision and contact read.** Remain strike-vulnerable. Low-crush approach ends after 21; no special evasion on capture 22–23. No aerial latch, second hop, landing recapture, drift beyond the approach, or chase of a jumping target.

**Transfers.** No outgoing cancel. Consume owned bleed only on confirmed capture; the capture pose precedes the single later cashout impact. Whiff has no lock or cashout flash.

**Movement binding:** entry inertia 0%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. Use the scripted root track below; do not add motion from the drawing.

#### 26. `214D` — Skim cashout

**Entry, support and hands.** Enter in the standing action profile, preserving legitimate low-source identity without an early low-profile benefit. Fold arms in anticipation; LEFT forearm leads, short knife still held, long RIGHT lies trailing beside the right hip.

**Sequence.** At frame 6 flatten into the actual ≤52px approach profile over the folded left leg with right boot trailing. Rise into the fully standing body/push profile on frame 22 and present the upright latch on 22–23. Success enters Skim cashout pair; whiff retracts LEFT and collects the trailing foot while remaining standing for all recovery.

**Collision and contact read.** Do not flatten before the real profile window or keep it through capture. Lows can intersect exposed legs/arm. No burrow, translucency, damaging low hitbox, follow-up sweep or blanket mid/high immunity.

**Transfers.** No outgoing cancel. A jumped-out attempt completes whiff without following the receiver. Success alone changes status and enters the upright paired finish.

**Movement binding:** entry inertia 0%; instant advance 0 raw; pre-active travel 0 raw/tick; active travel 0 raw/tick; attack friction 90 raw/tick. Use the scripted root track below; do not add motion from the drawing.

### Exact exceptional root/facing tracks

- **236K Passing cut:** frames 9–20 advance +1250 raw per tick in entry facing (12 ticks, 150px maximum before stage clamps). Pass through opponent push only during that authored travel; walls still clamp. After completing frame 20, compute one target-relative facing update and lock it through recovery. Draw the foot plant/torso turn at that boundary; no additional root displacement or facing correction comes from the art.
- **236D Vault / 214D Skim:** frames 6–20 advance +1200 raw per tick (15 ticks, maximum 180px), stopping at the opposing pushbox without pushing it. No extra reach from the left forearm drawing. The local capture extension is defined in the final mechanics data. Both latch failure from acceptance if the target is already airborne/prejump, and on any accepted jump/prejump/airborne transition through the final capture tick. Once failed, draw the same committed attempt and whiff even if the target lands; do not chase, aim upward or rearm. The whiff stays at the finite approach endpoint.
- **Vault vertical root:** y=0 on frames 1 and 5; y=2200 raw on frames 10 and 15; y=0 on frames 21 and 22. Interpolate in integer raw units on frames 6–21; these samples replace gravity only for this scripted approach. It is grounded before capture. Do not append a generic air-action landing lock.
- **Skim vertical root:** y remains 0. The low silhouette is actual body profile change on frames 6–21, not a hidden root dip. Its push height is standing 138px on frames 1–5, low 52px on 6–21, and standing 138px again from 22 through all recovery. Body hurt geometry is standing on capture frames 22–23 with the reaching arm, then standing without that extension from 24. Draw the upright exposure at 22; there is no old crouched-capture variant or frame-39 recovery rise.
- **2Hs / 623Hs:** no vertical root track. Draw rising chest/arms with feet grounded. A target launch does not launch Fillet.

## 6. Legal transfers and buffer-visible bridges

Use final **named route lists**, never a guessed path because two drawings look compatible. Preserve the existing c.S→f.S dispatcher bypass at close range. Normal/special windows below are inclusive **completed source action frames**. All require actual hit or block unless final mechanics explicitly provide a different condition. A branch delay continues source animation/recovery; it does not hold a loaded pose indefinitely.


| Source | Normal targets/window | Special targets/window | Contextual follow | Jump/air dash | Bleed grab window |
|---|---|---|---|---|---|
| `5P` | `5P`, `2P`, `5K`, `2K`, `6P` / 5–13 | `236P`, `236S`, `236K`, `623Hs` / 5–13 | None | None | None |
| `5K` | `6P`, `6Hs` / 7–15 | `236P`, `236S`, `236K`, `623Hs` / 7–15 | None | None | `236D`, `214D` / 7–15 |
| `c.S` | `5S`, `5Hs`, `2Hs`, `6Hs`, `2S` / 7–17 | `236P`, `236S`, `236K`, `623Hs` / 7–17 | None | 7–15; quota/state required | `236D`, `214D` / 7–17 |
| `5S` | `5Hs`, `2Hs`, `6Hs` / 9–17 | `236P`, `236S`, `236K`, `623Hs` / 9–17 | None | None | `236D`, `214D` / 9–17 |
| `5Hs` | `6Hs` / 13–22 | `236P`, `236S`, `236K`, `623Hs` / 13–22 | None | None | `236D`, `214D` / 13–22 |
| `2P` | `5P`, `2P`, `5K`, `2K`, `6P` / 5–12 | `236P`, `236S`, `236K`, `623Hs` / 5–12 | None | None | None |
| `2K` | `6P`, `6Hs` / 6–14 | `236P`, `236S`, `236K`, `623Hs` / 6–14 | None | None | `236D`, `214D` / 6–14 |
| `2S` | None | None | None | None | None |
| `2Hs` | None | `236P`, `236S`, `236K`, `623Hs` / 14–24 | None | None | None |
| `6P` | None | `236P`, `236S`, `236K`, `623Hs` / 9–18 | None | None | None |
| `6Hs` | None | `236P`, `236S`, `236K`, `623Hs` / 18–27 | None | None | `236D`, `214D` / 18–27 |
| `j.P` | `j.P`, `j.K` / 5–13 | None | None | 5–11; quota/state required | None |
| `j.K` | `j.S` / 7–16 | None | None | 7–14; quota/state required | None |
| `j.S` | `j.Hs` / 10–19 | None | None | 10–17; quota/state required | None |
| `j.Hs` | None | None | None | None | None |
| `236P` | None | None | None | None | None |
| `236S` | None | None | `236S>6S`, `236S>2S` / 9–17 | None | `236D`, `214D` / 9–17 |
| `236S>6S` | None | None | None | None | None |
| `236S>2S` | None | None | None | None | None |
| `236K` | None | None | None | None | None |
| `623Hs` | None | None | None | None | None |
| `4P+K` | None | None | None | None | None |
| `6P+K` | None | None | None | None | None |
| `5D` | None | None | None | None | None |
| `236D` | None | None | None | None | None |
| `214D` | None | None | None | None | None |

For a bleed-grab cancel, additionally require currently owned bleed and **five completed attacker action ticks after the last contact**. Shared hitstop does not count. Example: f.S contact on source frame 9, complete frames 10–14, then start the grab on would-be frame 15; this is not an immediate unblockable gatling. Destination startup, target stun/throw grace, accepted jump, range and the command's failure latch still govern capture. Show the waiting source pose advancing, then the real destination entry with no extra bridge frame. No normal throw cancel is legal.

No action cancels into Wound. No unspecified whiff cancel, ground dash cancel or RC is enabled. With zero extra air jumps, an air jump-cancel flag can only yield an actually available permitted action; do not animate a second jump to explain a flag. The named air-dash route also needs its unused shared quota. Normal self-loops exist only where named and enabled; a visible retraction does not authorize another button automatically.

## 7. Five complete paired guides

### Common paired-state implementation

**C0** is confirmed capture. Save immutable owner, receiver, entry facing, entry owner root, incoming receiver root/orientation, action serial and any grey snapshot. Success **replaces** the remaining startup/active/recovery action. Apply the declared capture freeze, then run C1..CN on the shared unfrozen clock, then release freeze, then each role's independent recovery. Do not finish an old active frame again or append the old whiff recovery. Inputs still sample; only the normal-throw tech handler accepts its specialized capture input.

Clear carry, independent movement and pre-existing individual counter slowdown on capture. During the pair both roles are excluded from independent strikes/projectiles/throws, ordinary guard/FD, and ordinary inter-actor push resolution. This starts only after success: a connecting simultaneous strike still defeats the attempted capture. No separate damaging knife hitbox exists during a pair; visible cut accents do not create extra health events or hitstop.

The root tables use **pixels relative to the owner's C0 root**, x oriented by captured entry facing and y upward; multiply by 100 for raw integers. `g0` is the saved receiver's actual signed relative root at C0. Between listed keys use `a + trunc_toward_zero((b−a)×(C−Ca)/(Cb−Ca))` in raw units, evaluated from the stored endpoints each tick rather than accumulating rounding error. The first segment normalizes actual contact spacing by C4. These are physical scripted roots, not renderer offsets.

For each tick, compute both intended roots, then translate the **whole pair by one common minimal x correction** so both fit the stage using their actual push half-widths. Do not shrink the requested gap or change side order to fit a corner. If roots are xa/xb with half-widths ha/hb, allowed correction is `[max(ha−xa,hb−xb), min(stageMax−ha−xa,stageMax−hb−xb)]`; clamp zero into that interval. Render feet at the corrected roots. The same result must survive rollback.

Keep forearm contact through the listed lock phase; derive the hand/receiver sockets from the keyed rig. While upright at the canonical 60px root gap, use owner `left_forearm_contact = [28,88]px` and receiver `receiver_contact = [32,88]px` in its opposite-facing local coordinates; they coincide in world space. During C1–4 use the actual moving roots to solve reachable contact sockets and gather the receiver into that hold. Never stretch arms to enforce an obsolete contact point. For receivers with different proportions, bend/turn their own rig and choose the matching torso/forearm socket while retaining scale; do not resize the entire receiver.

Wound uses corresponding contact heights 32/45/68/88px as the receiver rises. Back throw uses turning socket keys as roots exchange: close the local forward contact offsets toward zero by C16, where the two root x coordinates coincide, then release at C17. Use front/back depth ordering to show the turn, not a teleport or early gameplay facing flip. When a lock ends, stop following the released socket immediately. Both knives stay with Fillet's physical hands.

At final C, apply the single declared status/health event, ground both, zero vx/vy/carry/knockback, reset air quotas once, and restore ordinary ready anatomy/push for release recovery. Role recovery cannot guard or act, but can be interrupted by a real strike after pair protection ends. Use actual reaction immediately on interruption. Do not append a launch, downed state or wake timer. Victim throw grace 5 begins at its first unlocked tick. The owner does not gain extra throw grace from this sequence unless another shared rule supplies it.

### 7.1 Wound — `wound_otg_restand`

Only a valid current Downed target can enter; preserve its prone/supine orientation. Capture freeze **4**, pair **20**, release freeze **0**, owner/receiver recovery **0/0**. Apply owned bleed only on **C20**; zero direct damage. Both are free on the next advancing tick, at a **120px** root gap and +0. There is no tech branch.

| Key/phase | Owner root | Receiver root | Owner pose / contact path | Receiver pose / transfer |
|---|---|---|---|---|
| C0 | (0,0) | (g0,0) | Preserve the actual low Wound contact pose through capture freeze; long RIGHT is low. | Hold the actual downed orientation; no premature standing pop. |
| C1–4; endpoint C4 | (0,0) | Interpolate g0→60; endpoint (60,0) | Kneel alongside; left forearm contact gathers to height 32. Short LEFT remains closed/downward; RIGHT stays low. | Slide only by the scripted root into the paired prone/supine fit; torso remains down. |
| C5–8; C8 | (0,0) | (60,0) | Small stylized RIGHT marking gesture; left forearm steadies the torso at height 45. No extra damaging event. | Brief torso reaction, still supported low; do not start a separate hitstun timer. |
| C9–12; C12 | (0,0) | (60,0) | Rise through knees/hips; contact height 68; long RIGHT returns clear. | Roll/gather onto knee in the incoming down orientation, following the contact height. |
| C13–16; C16 | (0,0) | (60,0) | Stand into Stalker; retract both weapons; contact height 88. | Regain feet, torso meeting the upright socket; no free action yet. |
| C17–20; endpoint C20 | Interpolate to (−30,0) | Interpolate to (90,0) | Release forearm at C17, take a real 30px scripted backstep and settle ready. | Release contact, move the scripted 30px away, face owner and reach ready. |

Do not show the persistent bleed status or speed boost before C20. A small nonpersistent gesture cue during the pair is not damage or applied status. The Wound's failed attempt stays in its standalone low whiff clip and never moves the receiver.

### 7.2 Forward throw — `normal_throw_forward`

Capture freeze **6**, pair **24**, release freeze **8**, owner/receiver recovery **12/14**; final gap **120px**, +2 owner advantage if uninterrupted. One **45-damage** event at C24. Preserve owned bleed: no apply, refresh, consume or cashout. Normal tech is permitted as below.

| Key/phase | Owner root | Receiver root | Owner pose / contact path | Receiver pose / transfer |
|---|---|---|---|---|
| C0 | (0,0) | (g0,0) | Compact LEFT forearm latch; long RIGHT low/clear. | Actual grounded captured contact pose. |
| C1–4; C4 | (0,0) | g0→60; endpoint (60,0) | Establish upright forearm/pommel hold at 88px contact height. | Gather into upright recoil without scaling the rig. |
| C5–8; C8 | (0,0) | (60,0) | Draw the forearm close to torso; bend knees slightly. | Fold toward the contact while feet follow the locked root. |
| C9–12; C12 | (0,0) | (60,0) | Turn hips/shoulders with right blade held outside receiver. | Follow the controlled torso turn, retaining contact. |
| C13–16; C16 | (0,0) | (60,0) | Coil the release over planted support; no side exchange. | Shift weight toward the away foot; lock still active. |
| C17–20; C20 | (−15,0) | (75,0) | Release LEFT at C17, open the forearm and begin real backward separation. | Recover feet under torso as contact ends; follow scripted away displacement. |
| C21–24; C24 | (−30,0) | (90,0) | Complete the shove/cut accent and disengage, keeping knives attached. | One final release impact; remain standing at the exact endpoint. |

After the release freeze, owner R1–4 recoils blades inward, R5–8 recovers feet, R9–12 settles Stalker, then acts on R13. Receiver R1–5 staggers, R6–10 braces, R11–14 recovers facing, then acts on R15. Neither role is knocked down. The independent recovery silhouettes must remain visible until each role's actual unlock.

### 7.3 Back throw — `normal_throw_backward`

Use the same **6 / 24 / 8** capture/pair/release clocks, **12/14** recovery, **45** release damage and **120px** gap as forward throw. Keep contact through C16, release at C17, exchange sides by scripted roots and flip both gameplay facings **once at C24**. A successful tech before then retains original side order instead.

| Key/phase | Owner root | Receiver root | Owner pose / contact path | Receiver pose / transfer |
|---|---|---|---|---|
| C0 | (0,0) | (g0,0) | Same compact left-forearm capture; no pre-success turn. | Actual grounded captured contact. |
| C1–4; C4 | (0,0) | g0→60; endpoint (60,0) | Gather the upright hold; right long blade held clear. | Upright recoil into the 60px hold. |
| C5–8; C8 | (0,0) | (60,0) | Draw receiver toward torso with knees loaded. | Forward fold following forearm lock. |
| C9–12; C12 | (0,0) | (60,0) | Begin hip/shoulder yaw without a gameplay facing update. | Turn as a coupled receiver; keep its own anatomy. |
| C13–16; C16 | Interpolate to (30,0) | Interpolate to (30,0) | Travel through the turn; bring forearm contact offset toward center as roots meet. Show one body in front and the other behind. | Cross through the complementary depth layer; reduce contact offset to meet the turning owner. |
| C17–20; C20 | (60,0) | (0,0) | Release at C17 and continue the scripted side exchange; right blade remains attached/clear. | Open from lock and regain feet on the other side. |
| C21–24; C24 | (90,0) | (−30,0) | Complete separation, then switch gameplay facing once at C24 to face receiver. | One release impact, upright endpoint, opposite-facing owner. |

Use the same post-release R1–12 owner and R1–14 receiver keys as forward throw, authored in the new facing. Never apply a second root side swap on the release event: the path has already exchanged them. Do not mirror only the weapons to fake the turn.

### 7.4 Vault cashout — `236D_hop_cashout`

Capture occurs **grounded** after the hop has landed; no air catch. At C0 snapshot grey and consume owned bleed/speed immediately. Capture freeze **6**, pair **28**, release freeze **8**, owner/receiver recovery **16/18**, final gap **170px**, +2 if uninterrupted. Deal **55 + saved grey** once at C28 (grey cap 160). There is no tech.

| Key/phase | Owner root | Receiver root | Owner pose / contact path | Receiver pose / transfer |
|---|---|---|---|---|
| C0 | (0,0) | (g0,0) | Landed upright LEFT forearm latch; long RIGHT low/rear. Hold this grounded contact through freeze. | Grounded captured flinch; no lifted/airborne latch. |
| C1–4; C4 | (0,0) | g0→60; endpoint (60,0) | Collect the landed legs into a stable upright hold. Keep LEFT contact continuous while RIGHT stays clear. | Gather into the upright 88px socket and place both feet. |
| C5–8; C8 | (0,0) | (60,0) | Brace LEFT forearm near shoulder; hold the long RIGHT distinct. | Compress torso toward owner while rooted. |
| C9–12; C12 | (0,0) | (60,0) | Coil torso into unequal blade preparation, keeping the forearm lock. | Controlled captured turn follows the coil. |
| C13–16; C16 | (0,0) | (60,0) | One stylized long-RIGHT draw-cut accent; left forearm remains the stabilizing contact. | Strong local recoil without an extra hit, freeze or damage event. |
| C17–20; C20 | (0,0) | (60,0) | Short-LEFT accent within the closed grip; prepare to release, without losing the lock early. | Hold follow-through and begin gathering feet. |
| C21–24; C24 | (−27.5,0) | (87.5,0) | Open forearm at C21; begin scripted retreat with blades collecting inward. | Contact ends immediately; recover feet and move away on the root path. |
| C25–28; C28 | (−55,0) | (115,0) | Complete total 55px retreat into Stalker; one cashout release cue at endpoint. | Complete total 55px away displacement; one standing release impact. |

After release freeze: owner R1–4 recoil, R5–8 collect knives, R9–12 recover feet, R13–16 settle; act R17. Receiver R1–6 stagger, R7–12 brace, R13–18 recover facing; act R19. The two visible blade accents are choreography inside one pair, not separate hits or meter events.

### 7.5 Skim cashout — `214D_slide_cashout`

Use the exact same **6 / 28 / 8** clocks, **16/18** recoveries, C0 consume/snapshot, C28 **55 + saved grey**, **170px** endpoint and no-tech rule as Vault. The approach and the first pair keys must remain visibly distinct.

| Key/phase | Owner root | Receiver root | Owner pose / contact path | Receiver pose / transfer |
|---|---|---|---|---|
| C0 | (0,0) | (g0,0) | Standing post-skim latch, fully out of the ≤52px approach. LEFT forearm leads; RIGHT stays trailing; the rear foot has not yet collected. | Grounded upright captured flinch at actual contact height. |
| C1–4; C4 | (0,0) | g0→60; endpoint (60,0) | Collect the trailing foot and unwind the forward shoulder into the stable upright hold. Preserve the standing head/body profile; do not replay a crouch-to-stand rise or Vault's hop landing. | Gather into the upright socket while feet remain at scripted roots; follow the shoulder unwind rather than a vertical lift. |
| C5–8; C8 | (0,0) | (60,0) | Upright LEFT forearm brace; long RIGHT remains identifiable. | Torso compresses toward owner. |
| C9–12; C12 | (0,0) | (60,0) | Coil the upright torso with both knives anatomically fixed. | Controlled captured turn. |
| C13–16; C16 | (0,0) | (60,0) | Long-RIGHT draw-cut accent with contact still held. | Local recoil; no separate health/freeze event. |
| C17–20; C20 | (0,0) | (60,0) | Short-LEFT accent/release preparation; maintain lock through C20. | Held follow-through, feet gather. |
| C21–24; C24 | (−27.5,0) | (87.5,0) | Release LEFT at C21 and retreat along the real root track. | Regain feet; contact socket stops driving pose. |
| C25–28; C28 | (−55,0) | (115,0) | Complete the 55px retreat and cashout release pose. | Complete away displacement and standing final impact. |

Use the same owner R1–16 and receiver R1–18 recovery keys as Vault. Sharing this settled finish is intentional; do not share the approach, the standing-but-trailing capture-entry posture, or C1–4 foot/shoulder collection.

### Normal-throw tech and simultaneous ground-capture break

Check the ordinary throw tech window at the start of each shared C1–C6 tick before advancing that tick's pair track. Use the actual accepted P+K edge/chord rules and the ordinary five-world-tick history; a chord held long before capture does not auto-tech and freeze does not extend the history. Wound and command cashouts cannot be late-teched. For two simultaneous valid ground captures, including normal/command combinations, enter the same symmetric break outcome at C0 without consuming bleed. This clash does not create a late-tech permission for command grabs. Preserve the final engine adapter for other characters' ordinary throws; do not replace their authored finish with Fillet's 24-tick choreography.

At accepted **T0**, release the forearm socket immediately, preserve current side order and pair midpoint, place roots **120px apart** with the whole-pair wall clamp, zero motion/carry, then freeze both for **6** ticks. There is no damage or bleed change. After freeze, T1–4 shows arms disengaging and symmetric recoil; T5–8 plants feet; T9–12 reaches ready; both act on T13. Restore ordinary hurt/push at T1. Strike interruption is legal during this recovery and replaces that role's pose; there is no new strike immunity. Both receive throw grace 5 on unlock. A back-throw tech does not complete its side switch.

## 8. Manifest, runtime and playable fallback work order

1. **Inspect the current implementation baseline and extend its art API.** Preserve existing other-character assets. Add stable clip IDs for all 26 action IDs, locomotion/reactions, pair owner/receiver roles and tech. Keep input labels separate from file-safe IDs (`5S` is displayed f.S; `236S>6S`/`236S>2S` are distinct clips). Disabled old D/sweep slots must not alias a new clip accidentally.
2. **Build the Fillet master rig and exact key catalog.** Freeze anatomical segment/weapon lengths, palette and pivot calibration. Create both facings and a support-foot variant or deterministic support-foot solver for moving entries. Add pose keys at every final geometry/event boundary, not only the eight headline anchors. Give each pose an action/role/phase ID and root-local socket map.
3. **Use deterministic procedural poses for the first complete playable pass.** Render or bake the character with its actual costume/knife shapes, fixed root and the directed limbs above. Author every required clip/receiver role, including whiff recovery and post-release states. When a polished raster frame is absent, automatically select this matching procedural pose; do not fall back to an unrelated generic slash or standing idle during recovery. Missing cosmetic raster assets must not crash or disable a move.
4. **Integrate the exact simulation outputs.** Expose action age, last resolved collision frame, facing lock, gait phase/support, landing/reaction/role recovery counters, pair ID/tick, capture/release event serial and contact result to both renderer and workshop. Keep collision in the core/data. Animation selects from that resolved state and does not compute a separate combat outcome.
5. **Register atlas/procedural metadata.** Each baked frame needs file/region, logical pivot, fixed body-height calibration, facing, clip/key ID, socket map and optional separate effect layer. Store action/role ranges or exact key indices outside legacy `artPose` fallback. Extend `FighterArt`, browser preview and manifest loader together. Use a schema version and clear fallback semantics so old saved batches still load with explicit defaults.
6. **Make paired receiver adapters for every supported opponent.** Reuse each receiver's own scale, costume, weapons and existing recovery identity; solve the named shared sockets through its own rig. A paired role cannot turn another fighter into a Fillet silhouette. Preserve prone/supine source orientation for Wound and a grounded source for commands.
7. **Keep effects separate and contact-driven.** No released slash trail in windup; no hit burst on whiff. Trails disappear at the active boundary unless explicitly harmless fading art; they never alter geometry. Emit one final cashout/throw health-impact cue at release, one Wound status cue at C20, and one immediate bleed removal cue at confirmed cashout C0. Do not generate meter/health from VFX callbacks. Avoid transition smear frames and full-screen flashes that hide the committed recovery.
8. **Bake/export without changing the rig contract.** Produce transparent, unclipped regions with gutters; retain logical pivots when trimming neighboring atlas bleed. Keep master rig/pose inputs reproducible. Polished replacement PNGs use the same clip IDs, sockets, scale and frame ranges, so substitution does not change combat. Do not scale a whole frame to force its weapon tip into a box.
9. **Run the finite acceptance pass below and ship the playable result.** Correct observed alignment/continuity failures directly. Do not send the user a new list of poses to approve before implementation or leave the move kit unfinished because some frames still use the procedural production path.

### Suggested pose/clip metadata (presentation only)

```json
{
  "clip_id": "fillet_5S",
  "action_id": "5S",
  "clock": "actor_action",
  "facing_variants": ["right", "left"],
  "support_variants": ["left", "right"],
  "geometry_source": "FRAME_GEOMETRY.jsonl",
  "pose_keys": [
    {"frame": 1, "pose": "entry", "root_render_offset_raw": [0, 0]},
    {"frame": 7, "pose": "arm_exposure", "root_render_offset_raw": [0, 0]},
    {"frame": 9, "pose": "active", "root_render_offset_raw": [0, 0]},
    {"frame": 12, "pose": "recovery_extension", "root_render_offset_raw": [0, 0]},
    {"frame": 20, "pose": "retract", "root_render_offset_raw": [0, 0]},
    {"frame": 29, "pose": "last_locked", "root_render_offset_raw": [0, 0]}
  ],
  "missing_raster_policy": "render_matching_procedural_pose"
}
```

This example demonstrates the schema relationship, not a replacement for the complete key catalog; include frame 4/8/11 anchors and all other final boundaries when generating the actual clip. Socket coordinates live in each pose record, with the right/left weapon attachments typed independently. Derive every facing variant from the same immutable anatomical ownership.

### Required saved animation state

Snapshot/replay action serial and resolved frame/key; locomotion clip and idle/stop/turn age; distance accumulator/normalized gait phase/support foot; facing lock and dash direction/speed snapshot; natural-dash coast pending/mode; prior-air-action landing flag and landing age; pair owner/receiver/action/entry origin/facing/tick, receiver source posture and grey snapshot; per-role release recovery; tech branch clock; and any deterministic secondary-pose phase. Store only what cannot be derived identically from other saved state. Never leave a render-only timer determining the gameplay-facing pose after rollback.

## 9. Acceptance owned by Codex

Complete these checks and repair failures within implementation; they are not another user audit request.

- **Coverage:** 26 action clips, both facings, all mandatory geometry-boundary keys, both support-foot entries where relevant, all locomotion/reaction states, five pair owner/receiver guides and tech. No nonexistent `2D` clip silently selected for the migrated `2S` sweep.
- **Clock fidelity:** frame-step a whiff, hit, block, counter freeze/slow, earliest/latest legal cancel, airborne floor cutoff and final recovery tick. A frozen actor holds its body; a source cancel begins destination frame 1 without padding; no ready pose appears before release.
- **Hand/scale consistency:** compare c.S→f.S and every throw in both facings. Short LEFT performs c.S, long RIGHT remains low/ready until f.S, neither weapon changes length, and root/body-height remain calibrated. Check j.Hs and back throw front/back layering.
- **Movement continuity:** show both halves of walk/run, phase-preserving walk↔run and reversals, stop→attack with the real carry window, backdash cancel at frame 5, run jump, burst cancel and natural post-dash coast. Feet must not skate because the renderer added or missed displacement.
- **Geometry-readable weakness:** display debug hit/hurt/push with each required exposure key, especially f.S 7/12/20, branch shared 1–5 then split at 6, 6P protection ending, Skim low entry 6/standing capture 22/standing recovery 24 and Vault landing 21/capture 22. Correct art to data; do not remove an exposed limb from the drawing.
- **Pair alignment:** execute every guide midstage and at both corners against each receiver profile. Check C0 freeze, C4 normalization, contact release C17/C21, back-throw cross/depth order and C24 facing, final gaps, event count, role recovery and accepted tech. No detached contact hand or ghost receiver movement after unlock.
- **Input readability:** fresh buffered Up exits eligible grounded FD into prejump before a grab; continued held Up does not invent another edge. A jumped-out command completes whiff and does not recapture on landing.
- **Runtime parity:** native game, browser/workshop and rollback replay select the same clip/key, sockets, roots and geometry. Invalid or missing polished raster entries use the exact matching procedural pose. Produce one compact automated contact-sheet/pose-timeline report and representative gameplay capture as implementation evidence, then deliver the playable build.

The implementation is complete when the entire kit is playable, deterministic, visually distinct and aligned to its exact mechanics through the production procedural path, with polished raster art substituted wherever available. Raster polish can continue without reopening core design choices or blocking the completed moveset.
