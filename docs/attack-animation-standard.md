# Attack animation standard — approved Fillet timing process

Supers additionally follow the [26 November super direction](super-animation-standard.md):
full-body crescent motion, sudden impact, long follow-through and permission to
adjust timing when needed. That exception applies only to supers.

The user approved Fillet's held-pose sweep on 2026-11-19 and requested this
process across the rest of her kit and future attacks. This supersedes automatic
"new drawing every two frames" as the default. A drawing is a choice, not a timer.

1. Read the current move data first: first active frame, active windows, recovery,
   hitstop, hitbox changes, root travel, airborne/grounded transitions, branches
   and capture/release events. Preserve all gameplay values.
2. Write an exposure plan before making art. Hold a compact loaded pose through
   the last startup frame. The **largest attacking-limb/weapon movement must be
   the last-startup → first-active transition**. Do not spend that extension on
   a nearly completed strike during startup. A moving approach still follows its
   existing gameplay root; presentation must not change travel or contact time.
3. Show readable contact, then a smaller follow-through, withdrawal and settled
   recovery. Use deliberate holds. Keep extra active drawings only where they
   explain an actual path or hitbox change. Recovery may settle visually before
   it becomes actionable; its remaining lock still comes from the move data.
4. Reuse consistent approved drawings where possible. Use one source sheet and
   one fixed body scale per action; anchor support feet or the airborne pelvis.
   Never alternate incompatible drawings merely to increase frame count. Verify
   head size, limb lengths, palette, knife ownership and silhouette continuity.
5. Generate missing art with the image generator and preserve source PNG bytes,
   prompts, references and checksums. Follow approved choreography. If a new
   direction needs a choice, use windup/contact/follow-through options with
   direction arrows before production. Fillet's remaining kit is explicitly
   authorized to use the supplied implementation-pack choreography directly.
6. Keep effects separate where possible. Weapon arcs may extend the visible cut
   to its authored hitbox (explicitly authorized for Fillet); they add no hurtbox
   or damage area. No automatic limb stretching, crossfade or blended poses.
7. Use saved simulation clocks for pose selection: action age for attacks,
   shared capture clock for paired moves, and actual hitstop/counter slowdown.
   Paired latch and release accents follow their own real event times; never
   invent an impact on a missed capture. Landing, interruption, legal cancels
   and rollback take precedence over a decorative clip.
8. Review **at 1× / 60 Hz first**, then slow down for alignment checks. Show whiff
   and real contact separately. Validate both facings, feet/pelvis registration,
   strike reach, first-active timing, recovery end, edited timings and replay.
   Use MP4 or the browser player for exact game-speed presentation; slow GIFs
   are inspection aids. A pretty still or a smooth slow loop is insufficient.

For inherited rasters, record the selected loaded/contact/finish/retract source
keys explicitly. Measure the attacking tip/limb in adjacent keys when reviewing
the active snap; a large overall root displacement must not mask a weak strike.
Two-frame throws combine preparation into frame 1 and latch on frame 2. Rekka
branches preserve their common entry until the authored divergence frame.

Reference implementation: [Fillet 2S timing](../art/characters/fillet-v1/production/sweep-timing/README.md).
Current whole-kit plan: [Fillet kit timing](../art/characters/fillet-v1/production/kit-timing/README.md).

Shark's full-kit application is documented in [Shark v2](../art/characters/shark-kit-v2/README.md). A normal-throw capture must have separate whiff and connected recovery tracks: latch/load follows the capture clock, and the release pose only begins after capture succeeds. Include separate weapon endpoints and effect extents when framing an animation review so long attacks stay visible. Validate atlas alpha in the runtime as well as in the image preview; image-tool previews can conceal translucent background haze.

The [20 November guide audit](attack-animation-audit-2026-11-20.md) adds a repeatable
review check: include hit, block and whiff recordings, a silhouette/effects toggle,
and the previous actual recording. For casts, separate the caster's visual
follow-through from the projectile's saved lifetime. A body may settle during
its existing action lock, but art must never shorten that lock. Check the source
against the moving hand as well as the feet; a recovery jump should not be larger
than the first-active strike. Record unresolved readability issues explicitly.

The [Fillet guide audit](fillet-animation-audit-2026-11-20.md) adds two source
registration checks: inspect transparent atlas gutters at runtime (generated
figures need not occupy equal-width cells), and compare anatomical anchors
across source columns before assigning pivots. A narrow swept strike must lose
its low trail when its later active geometry becomes high-only. Validate the
actual pixels with effects hidden; a detached effect cannot substitute for
missing arm/weapon reach.
