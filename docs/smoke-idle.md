# Smoke — approved A standing / H crouching idles

Smoke uses **A / Open Current** while standing and **H / Uncoiled Vapor** while
crouching. Both retain the approved olive hood, dark hair, ivory tails and
alchemist equipment. Forefeet remain at ground level; the weightless appearance
does not make her airborne or change her movement, throws, blocking or pushbox.

Each body clip has four generated keys, held for 20 action frames each. Eight
separate gray/olive vapor keys crossfade behind her over the same 80-frame loop.
The vapor uses her saved `idleTime`, so hitstop freezes it and scrubbing or
rollback restores it. It stays with her foreground group, hides during attack,
hit/block, travel and movement poses, and never receives collision boxes.

The two body clips append pose phases 11 and 12. Their anatomical hurtboxes
use legs, torso/arms, head and one extended-arm region: four boxes maximum.
Hair, hood, coat tails, vials and smoke are excluded. Each source clip has a fixed
standing-equivalent scale, so H remains a low crouch instead of being enlarged.
Attack art, attack tuning, user drafts and push dimensions are preserved.

In the browser editor choose **Smoke → Movement & defense → Preview action →
Idle stance / Crouching idle**. Play or scrub the same preview used for attacks.
In Godot, **Development → Sprite & collision review → Ready / Crouch** supports
looping, frame selection, mirroring and the matching body boxes.

Approved comparison sheets live in `art/characters/smoke-idle-v1/`. Production
PNGs and exact prompts are in `godot/assets/fighters/smoke-idle-v1/`. Original
image-generated pixels are unchanged; registration and collision are metadata.
Run `python scripts/register-smoke-idle-art.py` then
`python scripts/generate-combat-data.py` to reproduce the registration. The
first vapor generation was rejected for diffuse haze at cell edges; its clean
replacement was produced with the image generator, not pixel manipulation.
