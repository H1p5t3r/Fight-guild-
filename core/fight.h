#pragma once

// No engine, allocator, clock, floating point, or platform dependencies.
// World coordinates are hundredths of a pixel; one step is exactly 1/60 second.
namespace fight {
constexpr int VERSION = 17, CHARACTER_COUNT = 6, HISTORY = 64, MOVE_COUNT = 32, FIELD_COUNT = 112;
constexpr int STAGE_COUNT = 3; // Charter Grounds, Tide Docks, Foundry Walk; a connected loop.
constexpr int SWEEP = 22, BACK_THROW = 23, FORWARD_THROW = 24;
constexpr int KNIFE_SPIRAL=25, REKKA_MID=26, REKKA_LOW=27, HOOK_GROUND=28, HOOK_AIR=29,
              STAB_GROUND=30, STAB_AIR=31;
constexpr int MIN_STARTUP = 5;
constexpr int MAX_HURTBOXES = 4;
enum HurtRegion { LegsHurt, TorsoArmsHurt, HeadHurt, ExtensionHurt };
static_assert(ExtensionHurt+1==MAX_HURTBOXES, "Three body regions and one optional extension only");
constexpr int MOMENTUM_MAX = 10000, INPUT_MASK = 4095;
constexpr int MAX_STUN = 240, MAX_HITSTOP = 60, NOTICE_TICKS = 60, COMBO_HOLD = 60;
enum Input { Left=1, Right=2, Down=4, Up=8, P=16, K=32, S=64, Hs=128, D=256,
             Dash=512, Simple=1024, Faultless=2048 };
enum Kind { Normal, Command, Special, Drive, Throw };
// WallDamage is a retired save-compatibility slot. Collision speed determines wall damage.
// Smear slots are reserved for schema compatibility; transition smearing is removed.
enum Field { Button, Category, Direction, Motion, Air, Startup, Active, Recovery,
             Damage, Hitstun, Blockstun, Hitstop, Pushback, Reach, Bottom, Height,
             SpecialCancel, JumpCancel, WhiffCancel, SelfCancel, Advance,
             SimpleDirection, SimpleButton, NormalRoutes, CommandRoutes,
             HitLevel, ChipDamage, GuardBreak, CounterHitstun, CounterHitstop, ReversalEligible, HitboxBack,
             AirPushback, BlockPushback, Launch, AirLaunch, Knockdown, KnockdownFrames, WakeupFrames,
             WallDamage, ThrowRange, Enabled, ArtPose, FollowFrom, FollowFrom2, FollowHit,
             TravelSpeed, InertiaPercent, PullFrames, PullGap, HitAngle,
             NormalCancelStart, NormalCancelEnd, SpecialCancelStart, SpecialCancelEnd,
             JumpCancelStart, JumpCancelEnd, FollowCancelStart, FollowCancelEnd, CancelOn,
             StarterProration, ComboScaling, MinimumDamage, LandingRecovery, AttackLevel,
             CounterTier, CounterVulnerable, CounterFreezeFrames, CounterSlowFrames, ProjectileKind, ProjectileSpawnFrame, ProjectileSpeedX, ProjectileSpeedY, ProjectileGravity, ProjectileLife, ProjectileOffsetX, ProjectileOffsetY, ProjectileWidth, ProjectileHeight, ProjectileHits, ProjectileRehit, ProjectileDurability, ProjectilePersist, ProjectileMelee, SmearMode, SmearPart, SmearStretch, SmearFrame1, SmearFrame2, SmearFrame3, SmearFrame4, HurtMaskWindup, HurtMaskActive, HurtMaskRecovery, Mechanic, TetherSpeed, TetherFrames, BleedInitial, BleedTickDamage, BleedTickFrames, BleedDuration, BleedBlockPercent, BleedCap, VariantStartup, VariantActive, VariantRecovery, VariantDamage, VariantRange, VariantSpeed, VariantLift, VariantHitstun, VariantKnockdown };
enum KnockdownKind { NoKnockdown, SoftKnockdown, HardKnockdown };
enum Reaction { Free, AirReel, Downed, Waking, WallSplat, Reeled };
enum MobilityField { ForwardStyle, WalkSpeed, RunSpeed, RunAcceleration, StepSpeed, StepFrames,
                     BackSpeed, BackFrames, AttackFriction, BackStyle, BackWalkSpeed, BackRunSpeed, JumpSpeed, JumpForwardSpeed, JumpBackSpeed, Gravity, AirJumps, MovePrejumpFrames, AirDashEnabled, AirBackdashEnabled, AirDashStyle, AirBackdashStyle, AirDashSpeed, AirBackdashSpeed, AirDashFrames, AirBackdashFrames, AirDashUses, HoverHeight, HoverRiseSpeed, TeleportDistance, BackTeleportDistance, TeleportStartup, FdEnabled, FdPushPercent, FdDrain, FdAirDrain, FdBlockCost, MoveSmearMode, MoveSmearPart, MoveSmearStretch, MOBILITY_FIELDS };
enum ForwardMovement { ForwardRun, StepDash, HoverDash, Teleport };
struct Mobility { int v[MOBILITY_FIELDS]; };
enum BoxKind { HurtBox, PushBox, HitBox, WallBox, ProjectileBox };
constexpr int HIT_TRAVEL_TICKS = 6; // Existing hit-distance budgets now travel over six action ticks.
struct Box { int left, bottom, right, top; };
constexpr int HURT_PHASES = 3, HURT_FIELDS = 1+MAX_HURTBOXES*4;
// count 0 inherits the current sprite pose. Custom phases have the three body
// regions and optionally one extension; weapons never acquire hurt regions.
struct MoveHurt { int count; Box boxes[MAX_HURTBOXES]; };
constexpr int MAX_HIT_KEYS=32, MAX_HITBOXES=4, HIT_KEY_FIELDS=7+MAX_HITBOXES*4;
constexpr int HIT_TRACK_FIELDS=2+MAX_HIT_KEYS*HIT_KEY_FIELDS;
// A key starts at a 1-based active frame and holds until the next key.
// count -1 uses ordinary strike/hook geometry; 0 is a non-hitting gap.
// Timing/damage -1 inherits the move. Multiple boxes share one hit group.
struct HitKey { int frame, group, count, damage, hitstun, blockstun, hitstop; Box boxes[MAX_HITBOXES]; };
struct MoveHit { int multi, count; HitKey keys[MAX_HIT_KEYS]; };
struct Pose { int phase, index; }; // active, windup, block, signature windup/active; shared with rendering.
enum BlockReaction { NoBlock, StableBlock, PressureBlock, BrokenGuard };
enum Contact { NoContact, NormalHit, Blocked, CounterHit, PunishHit };
// WallRange/Decay/DecayDelay/MidCap/GroundedWallPrime are inert compatibility slots.
enum Rule { ButtonBuffer, MotionWindow, MotionGap, MoveGain, AttackGain,
            BlockAttackGain, DamageGain, GuardGain, SpecialGain, FDDrain,
            FDBlockCost, FDDamageCost, FDPushPercent,
            GravityAfter, GravityStep, GravityCap, WallThreshold, WallRange, WallDecayDelay,
            WallDecay, WallSplatFrames, WallBreakFrames, WallBreakDamage,
            PositiveFrames, PositiveGainPercent, PositiveRegen,
            FDAirDrain, FDLevelCost, CornerPushTransfer, WallMidCap, GroundedWallPrime,
            BlockCarryover, ThrowGraceFrames, AirLandingFrames, RepeatAfter, RepeatGravityStep,
            PrejumpFrames, EmptyLandingFrames, RULE_COUNT };
struct Move { int v[FIELD_COUNT]; };
struct Sample { int frame, direction, pressed, held, consumed; };
struct Fighter {
    int character, simple, x, y, vy, facing, health;
    int move, age, stun, guarding, contact, hit_done, dash, previous, raw;
    unsigned hit_groups;
    int combo, event, last_move;
    int momentum, faultless, movement_remainder;
    int block_reaction, block_age, block_advantage, guard_break;
    int combo_display, combo_time, combo_age;
    int hit_notice, hit_notice_time;
    int reversal_ready, reversal_time, reversal_input_age;
    int reaction, knockdown, down_frames, wakeup_frames, recovery_time, combo_received;
    int wall_time, wall_side, positive_time;
    int knockback_left; // Untravelled hit distance; a wall impact consumes it and horizontal velocity.
    int vx, running, dash_direction, pull_time, pull_owner, pull_gap;
    int carry_vx, carry_time;
    int landing_time, air_action, throw_grace, input_age;
    int combo_proration, combo_scale, repeat_gravity, move_uses[MOVE_COUNT];
    int last_damage, damage_scale, last_base_damage, counter_tier;
    int prejump_time;
    int slow_time, slow_phase, slow_held;
    int dash_kind, dash_age, dash_air, air_dash_used, air_jump_used, teleported;
    int attack_serial, projectile_spawned, contact_count;
    int variant, tether_source, tether_used, bleed_source, bleed_time, bleed_clock, grey_life;
    Sample history[HISTORY];
};
constexpr int MAX_PROJECTILES=16;
struct Projectile { int life, owner, character, move, serial, x, y, vx, vy, facing, hits, cooldown, durability; };
struct State {
    int frame, remaining, hitstop, winner;
    int wall_break_time, wall_break_actor, wall_break_side, stage;
    int wall_health[2]; // Shared by both fighters, independently for the left/right wall.
    int wall_break_x[2], wall_break_y[2]; // Cinematic origins survive neutral reset and rollback.
    int impact_time, impact_duration, impact_actor, impact_tier, impact_x, impact_y;
    Fighter players[2];
    Projectile projectiles[MAX_PROJECTILES];
    int version=VERSION; // Reject snapshots from a different core layout explicitly.
};
struct Rules {
    int buffer=5, motion_window=20, motion_gap=8;
    // Meter is hundredths of one percent. Rates are provisional, editable tuning.
    int move_gain=2, attack_gain=8, block_attack_gain=4, damage_gain=4, guard_gain=3;
    int special_gain=100, fd_drain=25, fd_block_cost=250, fd_damage_cost=0, fd_push_percent=300;
    int gravity_after=5, gravity_step=10, gravity_cap=200;
    int wall_threshold=1000, wall_range=16000, wall_decay_delay=60, wall_decay=20;
    int wall_splat_frames=60, wall_break_frames=150, wall_break_damage=50;
    int positive_frames=360, positive_gain_percent=150, positive_regen=5;
    int fd_air_drain=50, fd_level_cost=50, corner_push_transfer=1, wall_mid_cap=50, grounded_wall_prime=1;
    int block_carryover=1, throw_grace_frames=5, air_landing_frames=3, repeat_after=3, repeat_gravity_step=15;
    int prejump_frames=4, empty_landing_frames=0;
};
// Each engine adapter owns a simulation; multiple matches never share state.
class Simulation {
public:
    State world{};
    Move moves[CHARACTER_COUNT][MOVE_COUNT]{};
    MoveHurt move_hurt[CHARACTER_COUNT][MOVE_COUNT][HURT_PHASES]{};
    MoveHit move_hit[CHARACTER_COUNT][MOVE_COUNT]{};
    Mobility mobility[CHARACTER_COUNT]{};
    Rules rules{};
    void defaults();
    void reset(int character0, int character1, int simple0, int simple1);
    void step(int input0, int input1);
    bool motion_matches(const Fighter& f, int frame, int motion) const;
    unsigned checksum() const;
    int get(int player, int field) const;
    int move_get(int character, int move, int field) const;
    int move_set(int character, int move, int field, int value);
    int hurt_get(int character, int move, int phase, int field) const;
    int hurt_set(int character, int move, int phase, int count, const Box* boxes);
    int hit_get(int character, int move, int field) const;
    int hit_clear(int character, int move, int multi);
    int hit_add(int character, int move, const HitKey& key);
    // Authoring harness setup. Neither helper changes move configuration.
    int preview_place(int player, int x, int y, int momentum);
    int preview_begin(int player, int move);
    int rule_get(int field) const;
    int rule_set(int field, int value);
    int mobility_get(int character, int field) const;
    int mobility_set(int character, int field, int value);
    int can_cancel(int character, int from, int to, int contact) const;
    Pose pose(const Fighter& fighter, int tick_offset=0) const;
    int box_count(int player, int kind) const;
    Box box(int player, int kind, int index=0) const;
    static int pose_box_count(int character, int phase, int pose);
    static Box pose_box(int character, int phase, int pose, int index);
    static unsigned collision_hash();
private:
    Move effective_move(const Fighter& fighter) const;
    void tick_statuses();
    void trigger_tether(Fighter& fighter);
    void clear_owned_status(int owner);
    int requested(Fighter& f, Sample& h) const;
    void begin(Fighter& f, int move);
    bool active(const Fighter& f) const;
    void control(Fighter& f);
    bool overlaps(const Fighter& a, const Fighter& b) const;
    bool blocks(const Fighter& attacker, const Fighter& defender, bool was_stunned, bool was_landing) const;
    bool cancel_window(const Fighter& fighter, int group) const;
    void gain_momentum(Fighter& fighter, int amount);
    void update_faultless(Fighter& fighter);
    Box push_box(const Fighter& fighter) const;
    Box attack_box(const Fighter& fighter, int segment=0, int tick_offset=0) const;
    const HitKey* hit_key(const Fighter& fighter, int tick_offset=0) const;
    int attack_count(const Fighter& fighter, int tick_offset=0) const;
    unsigned hit_bit(const Fighter& fighter, int tick_offset=0) const;
    Box weapon_span(const Fighter& fighter, int tick_offset=0) const;
    Box hurt_box(const Fighter& fighter, int index, int tick_offset=0) const;
    const MoveHurt* hurt_override(const Fighter& fighter, int tick_offset=0) const;
    int hurt_count(const Fighter& fighter, int tick_offset=0) const;
    int hurt_mask(const Fighter& fighter, int tick_offset=0) const;
    void resolve_push(int previous_order, bool preserve_order);
    int clamp_x(const Fighter& fighter, int x) const;
    int gravity_percent(const Fighter& fighter) const;
    bool throw_invulnerable(const Fighter& fighter) const;
    void land(Fighter& fighter);
    void finish_wall_break();
    void move_horizontal(Fighter& fighter, bool was_hitstunned);
    void collide_wall(Fighter& fighter, int velocity, bool in_hitstun);
    void reel_targets(const bool advances[2]);
    bool double_forward(const Fighter& fighter, const Sample& sample, int direction=6) const;
    void start_dash(Fighter& fighter, bool backwards);
    void tick_dash(Fighter& fighter);
    int mobility_or(const Fighter& fighter, int field, int fallback) const;
    void update_projectiles();
    void spawn_projectile(Fighter& fighter);
    void apply_contact(int player, int move, Move effective, int contact, bool prior_combo, int prior_reaction, int facing, bool projectile);
};
// Compatibility instance for the original C ABI and native test runner.
extern Simulation default_simulation;
extern State& world;
extern Move (&moves)[CHARACTER_COUNT][MOVE_COUNT];
extern Rules& rules;
void defaults();
void reset(int character0, int character1, int simple0, int simple1);
void step(int input0, int input1);
bool cancel_allowed(const Move& from, const Move& to, bool same, bool contact);
bool motion_matches(const Fighter& f, int at_frame, int motion);
unsigned checksum();
}

#if defined(__wasm__)
#define FG_EXPORT(name) __attribute__((export_name(#name)))
#else
#define FG_EXPORT(name)
#endif
extern "C" {
FG_EXPORT(fg_version) int fg_version();
FG_EXPORT(fg_defaults) void fg_defaults();
FG_EXPORT(fg_reset) void fg_reset(int character0, int character1, int simple0, int simple1);
FG_EXPORT(fg_step) void fg_step(int input0, int input1);
FG_EXPORT(fg_get) int fg_get(int player, int field);
FG_EXPORT(fg_move_get) int fg_move_get(int character, int move, int field);
FG_EXPORT(fg_move_set) int fg_move_set(int character, int move, int field, int value);
FG_EXPORT(fg_hurt_get) int fg_hurt_get(int character, int move, int phase, int field);
FG_EXPORT(fg_hit_get) int fg_hit_get(int character,int move,int field);
FG_EXPORT(fg_hit_clear) int fg_hit_clear(int character,int move,int multi);
FG_EXPORT(fg_hit_add) int fg_hit_add(int c,int m,int frame,int group,int count,int damage,int hitstun,int blockstun,int hitstop,
    int l0,int b0,int r0,int t0,int l1,int b1,int r1,int t1,int l2,int b2,int r2,int t2,int l3,int b3,int r3,int t3);
FG_EXPORT(fg_preview_place) int fg_preview_place(int player,int x,int y,int momentum);
FG_EXPORT(fg_preview_begin) int fg_preview_begin(int player,int move);
FG_EXPORT(fg_hurt_set) int fg_hurt_set(int character, int move, int phase, int count,
    int l0,int b0,int r0,int t0,int l1,int b1,int r1,int t1,
    int l2,int b2,int r2,int t2,int l3,int b3,int r3,int t3);
FG_EXPORT(fg_pose_box_count) int fg_pose_box_count(int character,int phase,int pose);
FG_EXPORT(fg_pose_box_get) int fg_pose_box_get(int character,int phase,int pose,int index,int edge);
FG_EXPORT(fg_rule_get) int fg_rule_get(int field);
FG_EXPORT(fg_rule_set) int fg_rule_set(int field, int value);
FG_EXPORT(fg_mobility_get) int fg_mobility_get(int character, int field);
FG_EXPORT(fg_mobility_set) int fg_mobility_set(int character, int field, int value);
FG_EXPORT(fg_can_cancel) int fg_can_cancel(int character, int from, int to, int contact);
FG_EXPORT(fg_state_ptr) void* fg_state_ptr();
FG_EXPORT(fg_state_size) int fg_state_size();
FG_EXPORT(fg_checksum) unsigned fg_checksum();
FG_EXPORT(fg_collision_hash) unsigned fg_collision_hash();
FG_EXPORT(fg_box_count) int fg_box_count(int player, int kind);
FG_EXPORT(fg_box_get) int fg_box_get(int player, int kind, int index, int edge);
}
