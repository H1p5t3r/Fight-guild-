#pragma once

// No engine, allocator, clock, floating point, or platform dependencies.
// World coordinates are hundredths of a pixel; one step is exactly 1/60 second.
namespace fight {
constexpr int VERSION = 1, HISTORY = 64, MOVE_COUNT = 22, FIELD_COUNT = 27;
enum Input { Left=1, Right=2, Down=4, Up=8, P=16, K=32, S=64, Hs=128, D=256,
             Dash=512, Simple=1024 };
enum Kind { Normal, Command, Special, Drive };
enum Field { Button, Category, Direction, Motion, Air, Startup, Active, Recovery,
             Damage, Hitstun, Blockstun, Hitstop, Pushback, Reach, Bottom, Height,
             SpecialCancel, JumpCancel, WhiffCancel, SelfCancel, Advance,
             SimpleDirection, SimpleButton, NormalRoutes, CommandRoutes,
             HitLevel, Reserved };
struct Move { int v[FIELD_COUNT]; };
struct Sample { int frame, direction, pressed, held, consumed; };
struct Fighter {
    int character, simple, x, y, vy, facing, health;
    int move, age, stun, guarding, contact, hit_done, dash, previous, raw;
    int combo, event, last_move;
    Sample history[HISTORY];
};
struct State { int frame, remaining, hitstop, winner; Fighter players[2]; };
struct Rules { int buffer=5, motion_window=20, motion_gap=8; };
// Each engine adapter owns a simulation; multiple matches never share state.
class Simulation {
public:
    State world{};
    Move moves[2][MOVE_COUNT]{};
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
private:
    int requested(Fighter& f, Sample& h) const;
    void begin(Fighter& f, int move);
    bool active(const Fighter& f) const;
    void control(Fighter& f);
    bool overlaps(const Fighter& a, const Fighter& b) const;
    bool blocks(const Fighter& attacker, const Fighter& defender, bool was_stunned) const;
};
// Compatibility instance for the original C ABI and native test runner.
extern Simulation default_simulation;
extern State& world;
extern Move (&moves)[2][MOVE_COUNT];
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
}
