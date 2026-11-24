#include "../core/fight.h"
#include <cstdio>
#include <cstdlib>
#include <initializer_list>
using namespace fight;
static Simulation sim;
static int checks=0;
static void check(bool value,const char* why) { ++checks;if(!value){std::fprintf(stderr,"Grab timing: %s at F%d C%d (health %d/%d)\n",why,sim.world.frame,sim.world.pair.clock,sim.world.players[0].health,sim.world.players[1].health);std::exit(1);} }
static void setup(int attacker,int victim,int owner,int facing,int slot) {
    sim.defaults();sim.reset(owner?victim:attacker,owner?attacker:victim,0,0);
    sim.preview_place(owner,50000-facing*3000,0,0);sim.preview_place(1-owner,50000+facing*3000,0,0);
    if(attacker==5&&slot>=45)check(sim.preview_status(1-owner,1,59),"cashout setup");
    check(sim.preview_begin(owner,slot),"enabled grab starts");
    for(int tick=0;tick<sim.moves[attacker][slot].v[Startup];++tick)sim.step(0,0);
    check(sim.world.pair.kind||sim.world.players[owner].grab_time,"startup reaches capture");
    check(sim.world.players[1-owner].health==1000,"startup/capture does not pay damage early");
    while(sim.world.hitstop) {
        const int clock=sim.world.pair.clock,time=sim.world.players[owner].grab_time;
        sim.step(0,0);
        check(sim.world.pair.clock==clock&&sim.world.players[owner].grab_time==time,"shared freeze advances neither capture clock");
    }
}
static void release(int owner,int duration,int damage) {
    const State saved=sim.world;
    for(int tick=1;tick<=duration;++tick) {
        sim.step(0,0);
        check(sim.world.players[1-owner].health==(tick==duration?1000-damage:1000),"damage occurs once on final capture tick");
        if(tick<duration)check(sim.world.players[1-owner].reaction==Captured,"receiver released early");
    }
    check(!sim.world.pair.kind&&!sim.world.players[owner].grab_time,"capture ends on authored duration");
    const unsigned hash=sim.checksum();sim.world=saved;
    for(int tick=0;tick<duration;++tick)sim.step(0,0);
    check(sim.checksum()==hash,"longer capture replays identically");
}
int main() {
    for(int attacker=0;attacker<CHARACTER_COUNT;++attacker)for(int victim=0;victim<CHARACTER_COUNT;++victim)
    for(int owner:{0,1})for(int facing:{-1,1})for(int slot:{BACK_THROW,FORWARD_THROW}) {
        setup(attacker,victim,owner,facing,slot);
        check(sim.moves[attacker][slot].v[Startup]==2,"normal throw retains two-frame startup");
        release(owner,40,sim.moves[attacker][slot].v[Damage]);
    }
    for(int owner:{0,1})for(int facing:{-1,1}) {
        for(int slot:{VAULT_CASHOUT,SKIM_CASHOUT}) {
            setup(5,4,owner,facing,slot);release(owner,52,114);
        }
        for(int slot:{13,40}) {
            setup(3,4,owner,facing,slot);release(owner,slot==13?40:52,sim.moves[3][slot].v[Damage]);
            check(sim.world.players[owner].stance==1,"Tapper still returns to stance");
        }
    }
    for(int attacker=0;attacker<CHARACTER_COUNT;++attacker)for(int owner:{0,1})for(int tech:{1,6,7}) {
        setup(attacker,4,owner,1,FORWARD_THROW);
        for(int tick=1;tick<tech;++tick)sim.step(0,0);
        sim.step(owner?(P|K):0,owner?0:(P|K));
        const bool captured=sim.world.pair.kind||sim.world.players[owner].grab_time;
        check(captured==(tech>6),"longer hold does not extend six-tick tech window");
        check(sim.world.players[1-owner].health==1000,"tech window has no early damage");
    }
    // A saved move with zero GrabFrames retains its old six-tick gate.
    sim.defaults();sim.moves[4][FORWARD_THROW].v[GrabFrames]=0;sim.reset(4,5,0,0);
    sim.preview_place(0,47000,0,0);sim.preview_place(1,53000,0,0);sim.preview_begin(0,FORWARD_THROW);
    sim.step(0,0);sim.step(0,0);
    check(sim.world.pair.ticks==6,"older move files retain explicit zero-duration behavior");
    std::printf("Grab timing: %d checks passed; 40/52-tick holds, six-tick tech, one damage event and replay\n",checks);
}
