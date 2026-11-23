export const MECHANIC_SPECS = [
  [
    "mechanic",
    "Drive mechanic",
    0,
    0,
    5,
    "0 off; 1 legacy tether; 2 bleed; 3 attach line on hit; 4 spend line to pull. Reel In ignores guard and creates no damage, hitstop or new stun. Existing hitstun/blockstun pauses during the pull. 5 Break Step: one movement cancel per string, into an enhanced normal."
  ],
  [
    "tetherSpeed",
    "Legacy tether speed",
    1800,
    100,
    4000,
    "Pull velocity for the legacy tether. Reel In uses its travel duration and root gap instead."
  ],
  [
    "tetherFrames",
    "Reel travel duration",
    12,
    1,
    60,
    "Frames of horizontal pull. A free target remains fully actionable; existing hitstun or blockstun pauses until the pull ends. Shared hitstop pauses the pull. Also used by legacy tether."
  ],
  [
    "bleedInitial",
    "Initial grey life",
    20,
    0,
    1000,
    "Grey life added on the applying hit, multiplied by that hit\u2019s combo damage scale."
  ],
  [
    "bleedTickDamage",
    "Bleed tick grey life",
    2,
    0,
    1000,
    "Grey life added each tick interval. It does not remove health."
  ],
  [
    "bleedTickFrames",
    "Bleed tick interval",
    30,
    1,
    600,
    "Action frames between grey-life ticks; pauses during shared hitstop."
  ],
  [
    "bleedDuration",
    "Bleed inactivity timeout",
    420,
    1,
    3600,
    "Frames without an unblocked hit from the owner. Blocks do not refresh. 420 = 7 seconds at 60 Hz, excluding shared hitstop."
  ],
  [
    "bleedBlockPercent",
    "Blocked-hit grey life",
    20,
    0,
    100,
    "Percentage of the blocked move\u2019s unscaled on-hit damage added as grey life, including Faultless Defense."
  ],
  [
    "bleedCap",
    "Grey-life cap",
    300,
    0,
    1000,
    "Maximum stored grey life, also limited to current health minus one. Grey life cannot kill."
  ],
  [
    "variantStartup",
    "Follow-up startup",
    16,
    2,
    120,
    "First active frame of the follow-up. Cash-out grabs: minimum 2 frames; tether pulls: minimum 5."
  ],
  [
    "variantActive",
    "Follow-up active",
    6,
    1,
    120,
    "Active duration. Pull happens once on its first active frame; grab can connect throughout."
  ],
  [
    "variantRecovery",
    "Follow-up recovery",
    26,
    0,
    180,
    "Recovery after the conditional follow-up."
  ],
  [
    "variantDamage",
    "Cash-out base damage",
    60,
    0,
    1000,
    "Base grab damage before scaling; stored grey life is added unscaled on a successful grab."
  ],
  [
    "variantRange",
    "Cash-out grab range",
    3000,
    0,
    20000,
    "Extra ground throw reach beyond both pushbox half-widths. Opponent can jump or use throw immunity."
  ],
  [
    "variantSpeed",
    "Cash-out leap speed",
    600,
    0,
    2000,
    "Forward speed throughout startup and active frames. Existing run inertia is added."
  ],
  [
    "variantLift",
    "Cash-out leap lift",
    650,
    0,
    3000,
    "Initial upward velocity. Uses this character\u2019s gravity; landing does not cut the grab short."
  ],
  [
    "variantHitstun",
    "Cash-out hitstun",
    24,
    0,
    180,
    "Hitstun on a successful cash-out grab."
  ],
  [
    "variantKnockdown",
    "Cash-out knockdown",
    1,
    0,
    2,
    "0 none, 1 soft, 2 hard. Down and wake durations inherit the applying move\u2019s settings."
  ],
  [
    "tetherDuration",
    "Line lifetime",
    180,
    1,
    1200,
    "Unfrozen simulation ticks before an attached line expires. Taking an unblocked hit clears the owner\u2019s line."
  ],
  [
    "tetherRange",
    "Line maximum distance",
    45000,
    1000,
    100000,
    "Maximum horizontal or vertical root distance in pixels. Escaping the tag\u2019s range breaks it; Reel In also checks its own range."
  ],
  [
    "tetherGap",
    "Line stopping gap",
    6000,
    0,
    20000,
    "Minimum horizontal distance between fighter roots at the end of Reel In, clamped to body spacing. The pull never pushes the target farther away."
  ],
  [
    "driveDistance",
    "Drive distance override",
    0,
    0,
    80000,
    "0 derives travel from the longest enabled grounded normal plus its block pushback, minus body spacing. The budget is fixed at activation; no homing. Capped at 40 px per burst frame."
  ],
  [
    "drivePlus",
    "Enhanced normal \u00b7 extra blockstun",
    4,
    0,
    30,
    "Adds these frames of block advantage to the normal canceled out of the burst. It always inherits 100% of dash velocity; its usual attack friction then applies."
  ],
  [
    "driveNeutralFrames",
    "Drive reset \u00b7 neutral frames",
    12,
    1,
    120,
    "Consecutive unfrozen ticks with both fighters free, no attacks, stun, knockdown, dash or live projectile. Small pressure gaps do not refresh it."
  ]
];
