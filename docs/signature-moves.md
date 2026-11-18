# Fillet and Shark: first signature moves

These are playable starting values. Startup minimums are 2f for grabs, 3f for P normals, and 5f for other attacks; none grants invulnerability. The existing normal/Drive buttons and universal 2D / 4P+K / 6P+K remain available.

| Fighter | Input | Action | Startup / active / recovery | Damage |
| --- | --- | --- | --- | --- |
| Fillet | 236K | Traveling knife spiral; both knives lead the low rotation | 14 / 12 / 20 | 60 |
| Fillet | 236S | Upward knife slash, rekka starter | 12 / 3 / 22 | 35 |
| Fillet | 236S > 6S | Mid stab | 8 / 3 / 20 | 30 |
| Fillet | 236S > 2S or 236S > 6S > 2S | Low knife slice; soft knockdown | 9 / 4 / 26 | 45 |
| Shark | 214S | Ground hook aimed 45° upward | 20 / 8 / 26 | 25 |
| Shark | j.214P | Air hook aimed 45° downward | 18 / 8 / 26 | 25 |
| Shark | P after the matching hook hits | Ground/air short-blade stab | 8 / 5 / 20 | 45 |

Directions are relative to facing. `>` means a new button press during the preceding move; holding S or P never repeats an attack. Fillet can follow up after hit/block contact, or after the active frames finish on whiff, until its authored follow-up window closes (12 frames after the last active frame by default). The full route and the shortcut both end in the same low. Shark's P follow-up requires an unblocked hook hit and the matching ground/air state; block or whiff does not unlock it. Universal same-button command-normal cancels still apply to the new attacks.

With simplified controls enabled at character select, hold the modifier and use **6K / 6S** for Fillet's starters, **4S / j.4P** for Shark's hooks. Follow-up directions remain **6S / 2S** for Fillet and **P** for Shark. Traditional motions work in either control mode. Development's Controls guide lists the keyboard/controller bindings.

## Hook and movement behavior

The hooked spear travels from the hand to a **250px forward endpoint**, rising or falling one pixel per horizontal pixel. Eight narrow rectangles follow the spear itself; the tether has no hitbox or hurtbox. This makes the ground version an angled aerial catch and the air version a downward catch, rather than a full rectangular sweep. The visible spear reads its endpoints from the authoritative core, including hitstop and rollback. It extends during eight active ticks and retracts during the first eight recovery ticks. The pose holds for that retraction; this is procedural weapon travel, not additional generated animation frames.

On hit, the victim is reeled toward the attacker over ten unfrozen ticks, ending at pushbox separation plus 5px. Body separation and stage bounds still apply. The target cannot act or tech during the reel. Interrupting the attacker releases the victim; a follow-up hit replaces the reel with its own reaction. The hitstun permits the stab to combo from a normal jump. Timing, range, thickness, pull duration/gap and follow-up conditions are editable.

**Fillet, Shark, Hammer, Smoke and Tapper run forward; Anvil provisionally uses a step dash.** Start with 66 (two fresh forward presses within ten ticks) or Dash. Hold forward or Dash to maintain a run. Releasing both, crouching or guarding stops the run. Back + Dash produces a backward step; step direction is fixed for the burst. There is no air dash or dash invulnerability. Jumping from a run/step retains horizontal speed.

Attacks inherit horizontal velocity, multiplied by their **Carry speed %** (100% by default). Character-specific **Attack drag** slows that inherited velocity each unfrozen attack tick. **Active travel** adds the move's own forward speed during active frames; Fillet's spiral starts at 11px/tick. Run/step speed remains available for the button-buffer window (five ticks by default) while directions form a motion command. Starting an attack consumes that retained speed once; it expires after the window and is cleared by hits, guard and blocked movement. Hitstop pauses both movement and this carry window. Pushboxes and stage bounds prevent movement through another body or the wall.

## Editing and art

In **Development**, select a move and expand **Input & advanced rules** for signature pose, follow-up source slots, active travel, inertia and hook settings. **Run, step dash & inertia** edits the selected character's movement profile. Disabled reserved slots are shown explicitly in the editor; the other fighters do not gain these specials. Slot layout is stable at 32 per fighter, with 157 enabled moves across the cast.

**Sprite review → Signature attack** shows each pair with body/strike overlays and mirrored facing. Fillet and Shark each have four windup and four active drawings. The spear is a separate generated layer. Sources remain unchanged; manifests record regions, foot anchors, scales and checksums, and `signature-generation.json` records prompts and cleanup provenance. The sixteen new body poses use three hurtboxes plus at most one arm extension; blades, spear, rope and smears never add hurt area.

Schema 7 introduced the signature configuration and preserves schema 1–6 edits, supplies new fields/slots and movement defaults, and includes these settings in online compatibility fingerprints. Existing Fillet 236S timing/geometry edits are retained during migration; use **Restore default move set** to adopt the complete newly tuned starter. Save/export applies to the whole set. Visuals remain provisional windup/active studies; dedicated run poses and impact/follow-through/recovery drawings remain in the sprite pipeline backlog.

Schema 8 adds [cancel windows, scaled combo damage and landing recovery](combat-tuning.md). The full Fillet rekka now deals 89 damage, its shortcut 70, and either Shark hook-to-stab 52 against the default fighters. Air hook/stab landing recovery is 12f/10f. Earlier saves retain their legacy balance until defaults are restored.
