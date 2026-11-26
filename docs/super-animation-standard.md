# Super animation direction — 26 November 2026

This direction applies to supers. Ordinary attacks, locomotion and the paused
Move Workshop retain their existing presentation and workflow.

Use each fighter's approved **in-game** art as the model and rendering reference.
Preserve head and limb proportions, palette, contour weight, shadow shapes,
costume and weapon ownership. Compare against the neutral sprite at one world
scale, with effects hidden; constant sprite scale alone cannot detect a drawing
that has grown larger.

The user requested wide sweeping crescents, sudden impact and long follow-through,
and authorized timing changes when they improve the result. Animate the entire
body: planted foot or airborne pelvis, hip rotation, rib cage, opposing shoulders,
both arms, neck and gaze. The free arm or shield counterbalances the strike.
Hair, beard, clothing and equipment follow and settle after the torso. The arc
must be readable in the body and weapon even with effects hidden.

Start from a compressed load. Reserve the largest initial reach change for the
last startup to first active transition. Use fast strike changes, deliberate
contact holds and a longer deceleration through the finish. Avoid evenly spaced
poses that make the attack float. Keep continuous anatomy through the smooth
parts; do not stretch the sprite or resize each pose to its bounds.

Inspect anatomy without effects at enlarged size before signing off a sheet.
Trace each shoulder through one elbow and wrist to its hand. Shield/weapon arms
must attach to the correct shoulder and read separately from the torso; overlapping
muscle shapes can suggest an extra limb even when only two hands are drawn.
Check the same pose with its receiver visible so their limbs do not merge into
the attacker. Carry this correction through the adjacent follow-through keys.
For two-handed weapons, trace one continuous shaft through both grips. Reject
split handles and decorative handle ends that read as an extra hand.

Timing is editable, not sacred. First adjust pose exposures within the saved
simulation clocks. If startup, active windows, capture duration, hitstop or
recovery need changing, update their authoritative combat data too and validate
hitboxes, damage/capture events, cancel locks and rollback together. Never create
a visual impact before the actual contact, or let a decorative clip ignore a
legal interruption. Confirmed sequences, misses and blocks need distinct tracks.

Generate new drawings with the image tool, keep the original PNG bytes and record
prompts, references and hashes. Preserve previous production versions. Finish
and review one super before starting the next: 60 FPS hit, mirror, block where
applicable, miss, effects-hidden scale comparison, hand/weapon endpoints, native
event alignment, pause and replay. Publish each completed step to the development
branch; do not publish the Move Workshop.
