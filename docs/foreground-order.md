# Foreground character order

The fighter whose attack most recently connected draws in front of the other fighter. A hit, block (including Faultless Defense or a guard point), armored contact, throw/capture or projectile hit updates the order. Whiffs, projectile clashes and damage ticks from an existing status do not.

The order persists through hitstop, recovery, knockdowns, side switches and wall transitions until another attack connects. It resets at the start of a round. Before the first contact, the existing player-two foreground order is used. Contacts on the same simulation frame use the engine's deterministic resolution order.

The foreground owner is part of the rollback snapshot. Godot and the browser editor read that state directly; scrubbing or restoring a previous frame restores the order too. Detached weapons follow their owner, while the native HUD and collision overlay remain above both fighters.

Schema/core version 21 adds this presentation state without changing any move fields. Version-20 JSON imports preserve all edits and art briefs, including deliberately slower standard throws. Both online peers must use the updated build.
