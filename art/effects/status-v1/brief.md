# Bleed and tether — persistent state effects

Use the existing Ink Snap rendering language: cel-shaded graphic shapes, dark
local edges, ivory highlights and generous transparent gaps. These are status
indicators, so their scale stays below a contact burst and they never create a
false hit flash, shake or sound.

- Bleed: three crimson/wine notches over the torso, a restrained pulse at the
  native bleed tick, and three staggered falling droplets. A droplet emblem and
  `BLEED` tag under the affected fighter's health show the stored grey-life value.
- Tether: a navy-edged teal/ivory braided cord joins the owner and marked fighter.
  An ivory hook inside a broken rope loop marks the target above the body art.
  The attached cord has a slight sag. During the actual pull it tightens, its
  width increases, and chevrons travel back toward the owner. The HUD changes
  from `TETHERED` to `REELING` only while the native pull is active.
- Different silhouettes and explicit tags carry meaning in addition to color.
  Marks remain readable without covering faces or replacing the fighter palette.

The original generated PNG is copied byte-for-byte. `source.json` preserves its
prompt, references, origin and SHA-256. Atlas regions are metadata crops only.
The rope follows a cosmetic curve assembled from the authored cord; it has no
independent physics. No character sprites or attack effects are repainted.

Every animation derives from saved native status fields. There are no timers,
random particles or retained emitter objects. Pauses and hitstop hold the art;
rollback restores it immediately. Expiry, cash-out, source interruption, range
breaks and round reset remove it when the corresponding state clears. Reduced
motion keeps static marks/drops and directional pull chevrons, without pulses
or traveling particles. Wall travel suppresses in-arena status drawing.
