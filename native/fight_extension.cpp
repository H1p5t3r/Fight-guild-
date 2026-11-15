#include "fight.h"
#include <cstring>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>

using namespace godot;

class FightCore : public RefCounted {
    GDCLASS(FightCore, RefCounted)
    fight::Simulation simulation;
protected:
    static void _bind_methods() {
        ClassDB::bind_method(D_METHOD("reset", "character0", "character1", "simple0", "simple1"), &FightCore::reset);
        ClassDB::bind_method(D_METHOD("step", "input0", "input1"), &FightCore::step);
        ClassDB::bind_method(D_METHOD("read_value", "player", "field"), &FightCore::read_value);
        ClassDB::bind_method(D_METHOD("checksum"), &FightCore::checksum);
        ClassDB::bind_method(D_METHOD("snapshot"), &FightCore::snapshot);
        ClassDB::bind_method(D_METHOD("restore", "bytes"), &FightCore::restore);
        ClassDB::bind_method(D_METHOD("configuration"), &FightCore::configuration);
        ClassDB::bind_method(D_METHOD("configure", "values"), &FightCore::configure);
        ClassDB::bind_method(D_METHOD("restore_defaults"), &FightCore::restore_defaults);
        ClassDB::bind_method(D_METHOD("can_cancel", "character", "from", "to", "contact"), &FightCore::can_cancel);
        ClassDB::bind_method(D_METHOD("set_training_momentum", "player", "value"), &FightCore::set_training_momentum);
        ClassDB::bind_method(D_METHOD("boxes", "player", "kind"), &FightCore::boxes);
        ClassDB::bind_method(D_METHOD("pose_boxes", "character", "phase", "pose"), &FightCore::pose_boxes);
        ClassDB::bind_method(D_METHOD("collision_hash"), &FightCore::collision_hash);
    }
public:
    FightCore() { simulation.defaults(); simulation.reset(0,1,0,0); }
    void reset(int a,int b,bool simple_a,bool simple_b) { simulation.reset(a,b,simple_a,simple_b); }
    void step(int a,int b) { simulation.step(a,b); }
    int read_value(int p,int f) const { return simulation.get(p,f); }
    int64_t checksum() const { return simulation.checksum(); }
    int64_t collision_hash() const { return fight::Simulation::collision_hash(); }
    PackedInt32Array boxes(int player,int kind) const {
        PackedInt32Array result;
        for(int i=0;i<simulation.box_count(player,kind);++i) {
            auto b=simulation.box(player,kind,i);
            result.push_back(b.left); result.push_back(b.bottom);
            result.push_back(b.right); result.push_back(b.top);
        }
        return result;
    }
    PackedInt32Array pose_boxes(int character,int phase,int pose) const {
        PackedInt32Array result;
        for(int i=0;i<fight::Simulation::pose_box_count(character,phase,pose);++i) {
            auto b=fight::Simulation::pose_box(character,phase,pose,i);
            result.push_back(b.left); result.push_back(b.bottom);
            result.push_back(b.right); result.push_back(b.top);
        }
        return result;
    }
    bool can_cancel(int c,int from,int to,bool contact) const { return simulation.can_cancel(c,from,to,contact)!=0; }
    void restore_defaults() { simulation.defaults(); }
    bool set_training_momentum(int player,int value) {
        if(player<0||player>1||value<0||value>fight::MOMENTUM_MAX) return false;
        simulation.world.players[player].momentum=value;
        return true;
    }
    PackedByteArray snapshot() const {
        PackedByteArray bytes;
        bytes.resize(sizeof(fight::State));
        std::memcpy(bytes.ptrw(), &simulation.world, sizeof(fight::State));
        return bytes;
    }
    bool restore(const PackedByteArray& bytes) {
        if(bytes.size()!=sizeof(fight::State)) return false;
        fight::State candidate{};
        std::memcpy(&candidate,bytes.ptr(),sizeof(candidate));
        if(candidate.frame<0||candidate.winner< -1||candidate.winner>2||candidate.hitstop<0||candidate.hitstop>fight::MAX_HITSTOP) return false;
        for(const auto& f:candidate.players) {
            if(f.character<0||f.character>=fight::CHARACTER_COUNT||f.move< -1||f.move>=fight::MOVE_COUNT
                ||f.simple<0||f.simple>1||(f.facing!=1&&f.facing!= -1)
                ||f.age<0||f.age>420||f.stun<0||f.stun>fight::MAX_STUN
                ||f.momentum<0||f.momentum>fight::MOMENTUM_MAX||f.faultless<0||f.faultless>1
                ||f.movement_remainder<0||f.movement_remainder>=100
                ||f.block_reaction<0||f.block_reaction>fight::BrokenGuard
                ||f.block_age<0||f.block_age>180||f.block_advantage< -300||f.block_advantage>180
                ||f.guard_break<0||f.guard_break>1
                ||f.combo<0||f.combo_display<0||f.combo_time<0||f.combo_time>fight::COMBO_HOLD
                ||f.combo_age<0||f.combo_age>1000||f.hit_notice<0||f.hit_notice>fight::PunishHit
                ||f.hit_notice_time<0||f.hit_notice_time>fight::NOTICE_TICKS
                ||f.reversal_ready<0||f.reversal_ready>1||f.reversal_time<0||f.reversal_time>fight::NOTICE_TICKS
                ||f.reversal_input_age<0||f.reversal_input_age>=12) return false;
        }
        simulation.world=candidate;
        return true;
    }
    PackedInt32Array configuration() const {
        PackedInt32Array data;
        for(int c=0;c<fight::CHARACTER_COUNT;++c) for(int m=0;m<fight::MOVE_COUNT;++m)
            for(int f=0;f<fight::FIELD_COUNT;++f) data.push_back(simulation.move_get(c,m,f));
        for(int f=0;f<fight::RULE_COUNT;++f) data.push_back(simulation.rule_get(f));
        return data;
    }
    bool configure(const PackedInt32Array& data) {
        if(data.size()!=fight::CHARACTER_COUNT*fight::MOVE_COUNT*fight::FIELD_COUNT+fight::RULE_COUNT) return false;
        auto candidate=simulation;
        int at=0;
        for(int c=0;c<fight::CHARACTER_COUNT;++c) for(int m=0;m<fight::MOVE_COUNT;++m)
            for(int f=0;f<fight::FIELD_COUNT;++f) if(!candidate.move_set(c,m,f,data[at++])) return false;
        for(int f=0;f<fight::RULE_COUNT;++f) if(!candidate.rule_set(f,data[at++])) return false;
        simulation=candidate;
        return true;
    }
};

void initialize_fight(ModuleInitializationLevel level) {
    if(level==MODULE_INITIALIZATION_LEVEL_SCENE) GDREGISTER_CLASS(FightCore);
}
void uninitialize_fight(ModuleInitializationLevel) {}
extern "C" GDExtensionBool GDE_EXPORT fight_library_init(GDExtensionInterfaceGetProcAddress get_proc,
        GDExtensionClassLibraryPtr library, GDExtensionInitialization* initialization) {
    GDExtensionBinding::InitObject init(get_proc,library,initialization);
    init.register_initializer(initialize_fight);
    init.register_terminator(uninitialize_fight);
    init.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
    return init.init();
}
