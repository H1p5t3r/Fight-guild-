#pragma once

// No engine, allocator, clock, floating point, or platform dependencies.
// World coordinates are hundredths of a pixel; one step is exactly 1/60 second.
namespace fight {
constexpr int VERSION = 10, CHARACTER_COUNT = 6, HISTORY = 64, MOVE_COUNT = 32, FIELD_COUNT = 69;
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
             CounterTier, CounterVulnerable, CounterFreezeFrames, CounterSlowFrames };
enum KnockdownKind { NoKnockdown, SoftKnockdown, HardKnockdown };
enum Reaction { Free, AirReel, Downed, Waking, WallSplat, Reeled };
enum MobilityField { ForwardStyle, WalkSpeed, RunSpeed, RunAcceleration, StepSpeed, StepFrames,
                     BackSpeed, BackFrames, AttackFriction, MOBILITY_FIELDS };
enum ForwardMovement { ForwardRun, StepDash };
struct Mobility { int v[MOBILITY_FIELDS]; };
enum BoxKind { HurtBox, PushBox, HitBox };
struct Box { int left, bottom, right, top; };
struct Pose { int phase, index; }; // active, windup, block, signature windup/active; shared with rendering.
enum BlockReaction { NoBlock, StableBlock, PressureBlock, BrokenGuard };
enum Contact { NoContact, NormalHit, Blocked, CounterHit, PunishHit };
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
    int combo, event, last_move;
    int momentum, faultless, movement_remainder;
    int block_reaction, block_age, block_advantage, guard_break;
    int combo_display, combo_time, combo_age;
    int hit_notice, hit_notice_time;
    int reversal_ready, reversal_time, reversal_input_age;
    int reaction, knockdown, down_frames, wakeup_frames, recovery_time, combo_received;
    int wall_damage, wall_delay, wall_time, wall_side, positive_time;
    int vx, running, dash_direction, pull_time, pull_owner, pull_gap;
    int carry_vx, carry_time;
    int landing_time, air_action, throw_grace, input_age;
    int combo_proration, combo_scale, repeat_gravity, move_uses[MOVE_COUNT];
    int last_damage, damage_scale, last_base_damage, counter_tier;
    int prejump_time;
    int slow_time, slow_phase, slow_held;
    Sample history[HISTORY];
};
struct State {
    int frame, remaining, hitstop, winner;
    int wall_break_time, wall_break_actor, wall_break_side, stage;
    int impact_time, impact_duration, impact_actor, impact_tier, impact_x, impact_y;
    Fighter players[2];
};
struct Rules {
    int buffer=5, motion_window=20, motion_gap=8;
    // Meter is hundredths of one percent. Rates are provisional, editable tuning.
    int move_gain=2, attack_gain=8, block_attack_gain=4, damage_gain=4, guard_gain=3;
    int special_gain=100, fd_drain=25, fd_block_cost=250, fd_damage_cost=0, fd_push_percent=300;
    int gravity_after=5, gravity_step=10, gravity_cap=200;
    int wall_threshold=1000, wall_range=16000, wall_decay_delay=60, wall_decay=20;
    int wall_splat_frames=60, wall_break_frames=90, wall_break_damage=50;
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
    Box weapon_span(const Fighter& fighter, int tick_offset=0) const;
    Box hurt_box(const Fighter& fighter, int index, int tick_offset=0) const;
    void resolve_push(int previous_order, bool preserve_order);
    int clamp_x(const Fighter& fighter, int x) const;
    int gravity_percent(const Fighter& fighter) const;
    bool throw_invulnerable(const Fighter& fighter) const;
    void land(Fighter& fighter);
    void finish_wall_break();
    void move_horizontal(Fighter& fighter);
    void reel_targets(const bool advances[2]);
    bool double_forward(const Fighter& fighter, const Sample& sample) const;
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
