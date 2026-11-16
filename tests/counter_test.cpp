#include "../core/fight.h"
#include <cstdio>
using namespace fight;
static int checks=0,failures=0;
#define CHECK(x) do { ++checks; if(!(x)) { std::fprintf(stderr,"Counter FAIL %d: %s\n",__LINE__,#x); ++failures; } } while(0)
static Simulation setup() {
    Simulation s;s.defaults();s.reset(5,4,0,0);
    s.world.players[0].x=45000;s.world.players[1].x=51000;
    auto& m=s.moves[5][0];
    m.v[Reach]=50000;m.v[HitboxBack]=0;m.v[Bottom]=0;m.v[Height]=50000;
    m.v[Damage]=100;m.v[Hitstun]=100;m.v[Hitstop]=5;m.v[CounterHitstun]=0;
    m.v[Pushback]=m.v[AirPushback]=m.v[BlockPushback]=m.v[Launch]=m.v[WallDamage]=0;
    m.v[CounterTier]=3;m.v[CounterFreezeFrames]=31;m.v[CounterSlowFrames]=35;
    s.world.players[0].move=0;s.world.players[0].age=m.v[Startup]-1;
    s.world.players[1].move=0;s.world.players[1].age=0;
    return s;
}
static void ticks(Simulation& s,int n) { while(n-->0) s.step(0,0); }
int main() {
    auto s=setup();s.step(0,0);
    CHECK(s.get(0,10)==CounterHit&&s.world.hitstop==31&&s.get(1,63)==35);
    CHECK(s.world.impact_time==84&&s.world.impact_actor==0&&s.world.impact_tier==3);
    int stun=s.world.players[1].stun,age=s.world.players[0].age;
    ticks(s,31);
    CHECK(s.world.players[1].stun==stun&&s.world.players[0].age==age&&s.get(1,63)==35);
    CHECK(s.world.impact_time==53);
    int held=0;
    for(int i=0;i<35;++i) {
        int before=s.world.players[1].stun;s.step(0,0);
        held+=s.get(1,64);
        CHECK(s.world.players[1].stun==before-(i%2));
    }
    CHECK(held==18&&s.get(1,63)==0&&s.world.players[1].stun==stun-17);
    CHECK(s.world.players[0].move==-1); // Attacker recovered at normal speed.
    s.step(0,0);CHECK(s.world.players[1].stun==stun-18&&!s.get(1,64));
    s=setup();s.step(0,0);ticks(s,32);
    auto snapshot=s.world;ticks(s,130);auto hash=s.checksum();s.world=snapshot;ticks(s,130);
    CHECK(s.checksum()==hash); // Includes an odd slowdown phase, hitstop and impact clocks.
    s=setup();s.step(0,0);ticks(s,33);
    auto& a=s.world.players[0];auto& b=s.world.players[1];
    a.move=0;a.age=s.moves[5][0].v[Startup]-1;a.hit_done=a.contact=0;
    s.step(0,0);CHECK(a.event==NormalHit&&b.slow_time==32); // Follow-up keeps the remaining slowdown.
    ticks(s,5);CHECK(b.slow_time==32); // Shared impact freeze pauses the per-fighter clock.
    for(int result=0;result<3;++result) {
        s=setup();b.move=-1;
        if(result==1) {b.move=0;b.age=s.moves[4][0].v[Startup]+s.moves[4][0].v[Active];}
        s.step(0,result==2?Right:0);
        CHECK(a.event==(result==0?NormalHit:result==1?PunishHit:Blocked));
        CHECK(!b.slow_time&&!s.world.impact_time&&s.world.hitstop==5);
    }
    s=setup();s.moves[5][0].v[CounterFreezeFrames]=-1;s.moves[5][0].v[CounterSlowFrames]=0;
    s.moves[5][0].v[CounterHitstop]=7;s.step(0,0);CHECK(s.world.hitstop==12&&!b.slow_time);
    s=setup();s.moves[5][0].v[CounterFreezeFrames]=0;s.moves[5][0].v[CounterSlowFrames]=3;
    s.step(0,0);CHECK(!s.world.hitstop);ticks(s,3);CHECK(b.stun==99&&b.slow_time==0);
    s=setup();s.step(0,0);ticks(s,31);b.y=10000;b.vy=1000;b.reaction=AirReel;
    s.step(0,0);CHECK(b.y==10000&&b.vy==1000);
    s.step(0,0);CHECK(b.y==11000&&b.vy==915);
    s=setup();b.move=0;b.age=s.moves[4][0].v[Startup]-1;
    s.moves[4][0]=s.moves[5][0];s.step(0,0);
    CHECK(a.event==CounterHit&&b.event==CounterHit&&a.slow_time==35&&b.slow_time==35);
    CHECK(s.world.impact_actor==0); // Stable tie for simultaneous cinematic counters.
    ticks(s,31);int as=a.stun,bs=b.stun;ticks(s,35);CHECK(a.stun==as-17&&b.stun==bs-17);
    CHECK(!s.move_set(5,0,CounterFreezeFrames,61)&&!s.move_set(5,0,CounterSlowFrames,121));
    s.reset(5,4,0,0);CHECK(!s.world.impact_time&&!s.get(0,63)&&!s.get(1,63));
    std::printf("Counter slowdown: %d checks, %d failures\n",checks,failures);
    return failures?1:0;
}
