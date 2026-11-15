#pragma once

// No engine, allocator, clock, floating point, or platform dependencies.
// World coordinates are hundredths of a pixel; one step is exactly 1/60 second.
namespace fight {
constexpr int VERSION = 5, CHARACTER_COUNT = 6, HISTORY = 64, MOVE_COUNT = 22, FIELD_COUNT = 32;
constexpr int MIN_STARTUP = 5;
constexpr int MOMENTUM_MAX = 10000, INPUT_MASK = 4095;
constexpr int MAX_STUN = 240, MAX_HITSTOP = 60, NOTICE_TICKS = 60, COMBO_HOLD = 60;
enum Input { Left=1, Right=2, Down=4, Up=8, P=16, K=32, S=64, Hs=128, D=256,
             Dash=512, Simple=1024, Faultless=2048 };
enum Kind { Normal, Command, Special, Drive };
enum Field { Button, Category, Direction, Motion, Air, Startup, Active, Recovery,
             Damage, Hitstun, Blockstun, Hitstop, Pushback, Reach, Bottom, Height,
             SpecialCancel, JumpCancel, WhiffCancel, SelfCancel, Advance,
             SimpleDirection, SimpleButton, NormalRoutes, CommandRoutes,
             HitLevel, ChipDamage, GuardBreak, CounterHitstun, CounterHitstop, ReversalEligible, HitboxBack };
enum BoxKind { HurtBox, PushBox, HitBox };
struct Box { int left, bottom, right, top; };
struct Pose { int phase, index; }; // active, windup, block; shared with the sprite renderer.
enum BlockReaction { NoBlock, StableBlock, PressureBlock, BrokenGuard };
enum Contact { NoContact, NormalHit, Blocked, CounterHit, PunishHit };
enum Rule { ButtonBuffer, MotionWindow, MotionGap, MoveGain, AttackGain,
            BlockAttackGain, DamageGain, GuardGain, SpecialGain, FDDrain,
            FDBlockCost, FDDamageCost, FDPushPercent, RULE_COUNT };
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
    Sample history[HISTORY];
};
struct State { int frame, remaining, hitstop, winner; Fighter players[2]; };
struct Rules {
    int buffer=5, motion_window=20, motion_gap=8;
    // Meter is hundredths of one percent. Rates are provisional, editable tuning.
    int move_gain=2, attack_gain=8, block_attack_gain=4, damage_gain=4, guard_gain=3;
    int special_gain=100, fd_drain=10, fd_block_cost=100, fd_damage_cost=4, fd_push_percent=300;
};
// Each engine adapter owns a simulation; multiple matches never share state.
class Simulation {
public:
    State world{};
    Move moves[CHARACTER_COUNT][MOVE_COUNT]{};
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
    bool blocks(const Fighter& attacker, const Fighter& defender, bool was_stunned) const;
    void gain_momentum(Fighter& fighter, int amount);
    void update_faultless(Fighter& fighter);
    Box push_box(const Fighter& fighter) const;
    Box attack_box(const Fighter& fighter) const;
    Box hurt_box(const Fighter& fighter, int index, int tick_offset=0) const;
    void resolve_push(int previous_order, bool preserve_order);
    int clamp_x(const Fighter& fighter, int x) const;
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
FG_EXPORT(fg_can_cancel) int fg_can_cancel(int character, int from, int to, int contact);
FG_EXPORT(fg_state_ptr) void* fg_state_ptr();
FG_EXPORT(fg_state_size) int fg_state_size();
FG_EXPORT(fg_checksum) unsigned fg_checksum();
FG_EXPORT(fg_collision_hash) unsigned fg_collision_hash();
FG_EXPORT(fg_box_count) int fg_box_count(int player, int kind);
FG_EXPORT(fg_box_get) int fg_box_get(int player, int kind, int index, int edge);
}
