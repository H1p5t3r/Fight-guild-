# Tapper — Leo baseline and rolling stance

Design decisions recorded 2026-11-18. **Design specification only: Tapper's new stance and Leo-derived frame data are not yet implemented.** Shark and Fillet's implemented Drive mechanics are documented separately in [Drive mechanics](character-mechanics-drafts.md).

## Character direction

Tapper takes inspiration from Guilty Gear Strive Leo Whitefang: familiar neutral tools lead into a committed stance with repeatable high/low/throw pressure and no blocking. Tapper's visual identity is a Dempsey-style rolling motion and a rough close-range brawl. His stance entry uses a collar grab and headbutt. His original hooked staff remains part of the character design.

“Last Orders” was an assistant-proposed name, not a confirmed name. The earlier drinking/Brew-charge proposal is superseded by this stance direction.

## Non-stance baseline

The user requested that non-stance moves mirror **Strive Leo's frame data and utility**, with specials explicitly deferred for separate design.

Working scope: standing/crouching normals, command normals, aerial normals and ordinary throws. Record startup, active frames, recovery, advantage, guard level, move-specific cancel properties, vulnerability and functional purpose from a dated character-specific source. Preserve distinct close/far Slash behavior where the reference requires it; the current single 5S slot must not silently collapse two different tools. Verify move-specific hold/guard-point behavior against the same source before implementing it.

Working interpretation: Tapper's custom Drive and stance-entry animation are exceptions to the borrowed normal kit. His ordinary throw should retain its stance-entry function and the project's hard-knockdown rule. Outside stance, 2D remains the universal sweep. Existing global rules, including the five-frame minimum attack startup and unified non-stance gatlings, apply unless an explicit character exception is agreed. Any conflict with the verified reference should be recorded rather than presented as an exact copy.

Do not import Leo's specials as placeholders for Tapper's final kit. This decision does not itself approve copying movement speeds, health, damage units, physical pixel dimensions, or a different game's universal systems. Damage and spatial translation require separate tuning against Fight Guild's scale.

## Confirmed stance behavior

- Drive and the ordinary throw provide ways into the stance; the collar-grab/headbutt sequence establishes the stance's identity.
- Tapper cannot block while in stance.
- Stance normals can cancel into one another, overriding the ordinary universal route restrictions within this stance.
- S is a fast hook **mid**, intended to support tick throws and frame traps. **S can cancel into itself.**
- Hs is the **overhead**. The earlier assistant suggestion that Hs be an automatic stance-exit finisher is superseded.
- **2D exits stance** and is a cancel destination from stance normals. Within stance this is the exit action, rather than a sweep. The earlier assistant-proposed 4D exit is superseded.
- The stance has a high/low/throw mix that can return to stance offense and repeat.
- Replace the previously proposed P+K stance throw with a **command throw**: run toward the opponent, tackle them, land one strong punch, and return to stance offense.
- The command throw's exact motion input has not been selected. No proposed input is treated as approved.

## Pressure and throw rules

The intended decisions include S → S for pressure/frame-trap timing, S → command throw for a tick throw, normal → Hs for the overhead branch, normal → low for the low branch, and normal → 2D for stance exit. These are design routes, not assertions that a particular frame gap or guaranteed combo has already been established.

Current blockstun and post-stun throw immunity still apply unless an exception is explicitly authored; guard break retains its existing exception. The running throw therefore needs its run/grab timing tuned against those protections. Entering its run does not itself guarantee a successful grab.

The user explicitly confirmed S self-canceling. Self-cancel permissions for other stance normals, whiff-cancel permissions, cancellation windows, stance-exit recovery, and the exact low/P/K assignments remain to be set. A low K and short P check were earlier assistant proposals, not finalized move definitions.

Also open: whether the initial Drive is a blockable hit-grab or command grab, whether a blocked entry reaches stance, throw run limits/steering/air-target eligibility, the tackle's knockdown and spacing, and stance movement/evasive properties. The Dempsey animation alone does not establish invulnerability or armor. Preserve looping offense as the target when tuning these details.

## Reference availability and implementation gate

The supplied `GGST_Frame Data - Dustloop Wiki.mht` is the general [GGST/Frame_Data](https://www.dustloop.com/w/GGST/Frame_Data) page, revision 563708, captured 2026-11-15. It contains some character-comparison entries for Leo, but not his complete normal-move table. The supplied Damage and Mechanics pages describe shared systems. See the [saved-source review](research/strive-dustloop-2026-11-15.md).

On 2026-11-18 the connected environment's network policy was restricted and did not allow Dustloop. No web-search tool was available. No live Leo page or patch-specific normal timings were verified, and no frame values have been invented or applied.

Needed source: a saved MHTML/HTML/PDF copy of [GGST Leo Whitefang / Frame Data](https://www.dustloop.com/w/GGST/Leo_Whitefang/Frame_Data), plus the character's move descriptions where utility is not explained in the frame table. Save the page revision or patch label with the source. Once available, build a source-to-Tapper mapping and identify engine/editor support needed for each normal and stance action before claiming the baseline is implemented.
