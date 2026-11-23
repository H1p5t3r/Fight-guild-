# Playable-build improvement order

Work through these in order, finishing and pushing each step to
`feat/godot-combat-lab` before beginning the next. This records the user's approved
priority list, not a claim that the later items are implemented.

**Website freeze (2026-11-23):** Do not update or publish the move-editor website
until the user explicitly asks to resume. Continue improvements in the native
Godot game. Both jobs in `workshop-pages.yml` are paused; preserve these guards.
Do not treat permission for game/art changes as permission to resume the website.

1. **Combat impact feedback — complete (2026-11-23).** Resolved contact events and original
   sound effects now cover weapons, defense, counters, landing and walls in Godot
   and the Workshop preview source. The user delegated the impact choice; use
   B / Ink Snap from `art/effects/impact-v1/options.png` in Godot only. Eight impact
   families now hold through hitstop, then release into fragments; brief body tint
   and a reduced-motion-aware camera impulse add weight. Native checks and eleven
   recorded scenarios cover normal/block/FD/guard-break/counter, two-hit, airborne
   and mirrored contacts. Review: `exports/FightGuild-Impact-Review.mp4`.
   The Workshop source audio changes remain unpublished during the website freeze.
2. **Receiver animations and paired throws — next.** Strong reactions, readable knockdown
   and recovery, and convincing attacker/defender alignment.
3. **Spacing and combo audit.** Check the roster against standing, crouching and
   airborne targets, both corners, FD, repeat launchers and wall transitions.
4. **Movement transitions.** Consistent planted feet, body scale and transitions
   into/out of attacks; Hammer locomotion, Fillet air poses and Tapper stance.
5. **Input and controller support.** Remapping, device/deadzone handling, motion
   acceptance and buffered-action validation.
6. **Training and Workshop diagnostics.** Recording slots, defensive dummy choices,
   and clear explanations when a sequence cannot connect or cancel.
7. **Character rewards and counterplay.** Fillet bleed, Shark's pull, Tapper's stance
   loops and Hammer's once-per-string Drive.
8. **Repeatable sprite pipeline.** Approved references and choreography, registration,
   timing/coverage checks and a single review workflow.
9. **Online usability.** Easier connection, rematches and testing on real networks.
10. **Remaining roster design.** Anvil's identity and Tapper's eventual specials.

New sprite/animation directions retain the established options → user selection →
production process. Do not silently treat an unanswered art question as approval.
