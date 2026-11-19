#include "legacy_fillet_data.h"
#include "../core/fight.h"
#include <cstdio>
#include <initializer_list>
using namespace fight;
static int checks=0,failures=0;
#define CHECK(x) do { ++checks; if(!(x)) { std::fprintf(stderr,"Tuning FAIL %d: %s\n",__LINE__,#x); ++failures; } } while(0)
static Simulation fresh() {
    Simulation s;legacy_fillet::defaults(s);s.reset(5,4,0,0);
    s.world.players[0].x=45000;s.world.players[1].x=51000;
    return s;
}
static void commit_throw(Simulation& s){while(s.world.pair.kind||s.world.hitstop)s.step(0,0);}
static void ticks(Simulation& s,int count,int a=0,int b=0) { while(count-->0) s.step(a,b); }
static Move& strike(Simulation& s,int slot=0) {
    auto& m=s.moves[5][slot];m.v[Reach]=50000;m.v[HitboxBack]=0;m.v[Bottom]=0;m.v[Height]=50000;
    m.v[Damage]=100;m.v[Hitstop]=0;m.v[Hitstun]=60;m.v[Blockstun]=10;
    m.v[Pushback]=m.v[AirPushback]=m.v[BlockPushback]=m.v[Launch]=m.v[Knockdown]=0;
    m.v[WallDamage]=0;return m;
}
static void prime(Simulation& s,int slot=0) {
    auto& a=s.world.players[0];a.move=slot;a.age=s.moves[5][slot].v[Startup]-1;
    a.contact=a.hit_done=0;
}
static void cancel_windows() {
    auto s=fresh();s.world.players[1].x=90000;
    auto& a=s.world.players[0];a.move=0;a.age=7;a.contact=1;a.event=NormalHit;
    auto& m=s.moves[5][0];m.v[NormalCancelStart]=10;m.v[NormalCancelEnd]=12;
    s.step(K,0);CHECK(a.move==0);ticks(s,2);CHECK(a.move==0);
    s.step(0,0);CHECK(a.move==1&&a.input_age==3); // Buffered until the window opens.
    for(int age:{9,10,12,13}) {
        s=fresh();s.world.players[1].x=90000;auto& f=s.world.players[0];
        f.move=0;f.age=age;f.contact=1;f.event=NormalHit;
        s.moves[5][0].v[NormalCancelStart]=10;s.moves[5][0].v[NormalCancelEnd]=12;
        s.step(K,0);CHECK((f.move==1)==(age==10||age==12));
    }
    s=fresh();a=s.world.players[0]; // Reference remains bound to s's player.
    a.move=15;a.age=15;a.contact=1;a.event=NormalHit;
    s.step(Right|S,0);CHECK(a.move==REKKA_MID);
    s=fresh();a.move=15;a.age=15;a.contact=1;a.event=Blocked;
    s.moves[5][15].v[CancelOn]=1;s.step(Right|S,0);CHECK(a.move==15);
    s=fresh();a.move=15;a.age=15;a.contact=1;a.event=NormalHit;
    // Same-button command remains available even when special cancels are disabled.
    s.moves[5][15].v[FollowCancelEnd]=1;s.moves[5][REKKA_MID].v[Enabled]=0;
    s.moves[5][15].v[SpecialCancel]=0;s.step(Right|S,0);CHECK(a.move==10);
    for(int age:{10,11}) {
        s=fresh();a.move=1;a.age=age;a.contact=1;a.event=NormalHit;
        s.moves[5][1].v[JumpCancelStart]=10;s.moves[5][1].v[JumpCancelEnd]=10;
        s.step(Up,0);CHECK((a.prejump_time>0)==(age==10));
    }
}
static void damage() {
    auto s=fresh();auto& m=strike(s);m.v[StarterProration]=70;m.v[ComboScaling]=10;m.v[MinimumDamage]=10;
    auto& next=strike(s,1);next.v[StarterProration]=100;next.v[ComboScaling]=10;next.v[MinimumDamage]=10;
    prime(s);s.step(0,0);CHECK(s.get(0,55)==100&&s.get(1,3)==900);
    prime(s,1);s.step(0,0);CHECK(s.get(0,55)==63&&s.get(0,56)==63&&s.get(1,3)==837);
    prime(s,1);s.step(0,0);CHECK(s.get(0,55)==56&&s.get(1,3)==781);
    s.world.players[1].combo_scale=0;prime(s,1);s.step(0,0);CHECK(s.get(0,55)==10);
    next.v[Damage]=0;prime(s,1);s.step(0,0);CHECK(s.get(0,55)==0);
    s.world.players[1].stun=0;next.v[Damage]=100;prime(s,1);s.step(0,0);
    CHECK(s.get(0,55)==100&&s.get(0,9)==1&&s.get(1,57)==100);
    s=fresh();strike(s).v[Launch]=1000;
    for(int n=1;n<=7;++n) {
        prime(s);s.step(0,0);
        CHECK(s.get(1,35)==(n<=5?100:n==6?125:150));
    }
    State snapshot=s.world;ticks(s,80);auto expected=s.checksum();s.world=snapshot;ticks(s,80);
    CHECK(s.checksum()==expected);
}
static void defense() {
    for(int input:{0,int(Down),int(Left)}) {
        auto s=fresh();strike(s);auto& b=s.world.players[1];b.guarding=1;b.stun=3;
        prime(s);s.step(0,input);CHECK(b.guarding&&b.health==1000);
    }
    for(int input:{0,int(Down)}) {
        auto s=fresh();strike(s).v[HitLevel]=1;auto& b=s.world.players[1];b.guarding=1;b.stun=3;
        prime(s);s.step(0,input);CHECK((b.health==1000)==(input==Down));
    }
    auto s=fresh();strike(s);auto& b=s.world.players[1];b.guarding=1;b.stun=3;b.guard_break=1;
    prime(s);s.step(0,0);CHECK(!b.guarding&&b.health==900);
    s=fresh();strike(s);b.guarding=1;b.stun=1;s.step(0,0);
    prime(s);s.step(0,0);CHECK(!b.guarding); // A one-frame gap ends carryover.
    for(bool guarded:{false,true}) {
        s=fresh();b.stun=1;b.guarding=guarded;s.step(0,0);CHECK(b.throw_grace==5);
        for(int i=0;i<5;++i) {
            prime(s,FORWARD_THROW);s.step(0,0);CHECK(b.health==1000);
        }
        prime(s,FORWARD_THROW);s.step(0,0);commit_throw(s);CHECK(b.health==920);
    }
    s=fresh();b.reaction=Waking;b.recovery_time=1;s.step(0,0);CHECK(b.throw_grace==5);
    s=fresh();b.stun=3;b.guarding=b.guard_break=1;b.throw_grace=5;
    prime(s,FORWARD_THROW);s.step(0,0);commit_throw(s);CHECK(b.health==920); // Guard break bypasses all throw grace.
    s=fresh();strike(s);b.guarding=1;b.stun=3;s.rules.block_carryover=0;
    prime(s);s.step(0,0);CHECK(b.health==900);
}
static void landing_fd_walls() {
    auto s=fresh();s.reset(4,5,0,0);auto& a=s.world.players[0];
    a.y=1;a.vy=-500;a.move=HOOK_AIR;a.age=25;a.air_action=1;
    s.step(0,0);CHECK(a.landing_time==12&&a.move==-1);
    ticks(s,11);s.step(P,0);CHECK(a.landing_time==0&&a.move==-1);
    s.step(0,0);CHECK(a.move==0&&a.input_age==1);
    s=fresh();a.y=1;a.vy=-500;a.air_action=1;s.step(0,0);CHECK(a.landing_time==3);
    s=fresh();a.y=1;a.vy=-500;s.step(0,0);CHECK(a.landing_time==0);
    s=fresh();a.y=1;a.vy=-500;a.air_action=1;s.step(0,0);
    auto snapshot=s.world;ticks(s,4);auto hash=s.checksum();s.world=snapshot;ticks(s,4);CHECK(hash==s.checksum());
    s=fresh();a.momentum=10000;s.step(Left|Faultless,0);CHECK(a.momentum==9975);
    s=fresh();a.momentum=10000;a.y=10000;s.step(Left|Faultless,0);CHECK(a.momentum==9950);
    s=fresh();strike(s).v[AttackLevel]=2;s.world.players[1].momentum=10000;
    prime(s);s.step(0,Right|Faultless);CHECK(s.world.players[1].momentum==9625);
    s=fresh();auto& m=strike(s);m.v[BlockPushback]=1000;
    a.x=85000;s.world.players[1].x=100000;s.step(0,0);
    int before=a.x;prime(s);s.step(0,Right);CHECK(a.x==before-1000);
    s=fresh();strike(s).v[WallDamage]=5000;
    // Legacy attack-wall-damage and midscreen-cap fields no longer affect walls.
    for(int i=0;i<4;++i) {prime(s);s.step(0,0);}
    CHECK(s.world.wall_health[0]==1000&&s.world.wall_health[1]==1000);
    a.x=85000;s.world.players[1].x=100000;s.step(0,0);
    prime(s);s.step(0,0);CHECK(s.world.players[1].reaction==Free&&s.world.wall_health[1]==1000);
}
static void jumps() {
    auto s=fresh();s.world.players[1].x=90000;auto& a=s.world.players[0];
    a.vx=900;
    for(int remaining=4;remaining>=1;--remaining) {
        s.step(remaining==4?Up|Right:remaining==1?P:0,0);
        CHECK(a.y==0&&a.prejump_time==remaining&&a.move==-1);
        CHECK(a.vx==900&&s.get(0,21)==1);
        CHECK(s.get(0,29)==0&&s.get(0,30)==11); // Crouched body-only startup pose.
    }
    s.step(0,0);CHECK(a.y>0&&a.prejump_time==0&&a.move==17&&a.input_age==1);
    s=fresh();s.step(Up,0);s.world.hitstop=2;
    auto snapshot=s.world;ticks(s,9);auto hash=s.checksum();s.world=snapshot;
    ticks(s,2);CHECK(a.prejump_time==4&&a.y==0);
    ticks(s,7);CHECK(s.checksum()==hash);
    s=fresh();prime(s,FORWARD_THROW);s.step(0,Up);
    auto& b=s.world.players[1];CHECK(b.health==1000&&b.prejump_time==4);
    strike(s);b.momentum=10000;prime(s);s.step(0,Right|Faultless);
    CHECK(b.health==900&&!b.guarding&&!b.faultless&&b.prejump_time==0); // No guarding during startup.
    s=fresh();a.momentum=10000;s.step(Up,0);ticks(s,3);
    s.step(Left|Faultless,0);CHECK(a.y>0&&a.faultless&&a.momentum==9950);
    s=fresh();s.rules.prejump_frames=0;s.step(Up,0);CHECK(a.y>0&&!a.prejump_time);
    s=fresh();s.rules.empty_landing_frames=2;a.y=1;a.vy=-500;
    s.step(0,0);CHECK(a.landing_time==2);
    s.step(P,0);CHECK(a.move==-1&&a.landing_time==1);
    s.step(0,0);CHECK(a.move==-1&&a.landing_time==0);
    s.step(0,0);CHECK(a.move==0&&a.input_age==2);
    CHECK(!s.rule_set(PrejumpFrames,31)&&!s.rule_set(EmptyLandingFrames,121));
}
static void counters() {
    auto s=fresh();strike(s);auto& b=s.world.players[1];
    b.move=0;b.age=s.moves[4][0].v[Startup]+s.moves[4][0].v[Active];
    s.moves[4][0].v[CounterVulnerable]=7;
    prime(s);s.step(0,0);CHECK(s.get(0,10)==CounterHit);
    s=fresh();strike(s);b.move=0;b.age=1;s.moves[4][0].v[CounterVulnerable]=0;
    prime(s);s.step(0,0);CHECK(s.get(0,10)==NormalHit);
    CHECK(s.moves[5][3].v[CounterFreezeFrames]==31&&s.moves[5][3].v[CounterSlowFrames]==35);
    CHECK(s.moves[5][15].v[CounterTier]==0&&s.moves[5][15].v[CounterHitstun]==0);
    for(int c=0;c<CHARACTER_COUNT;++c) for(const auto& m:s.moves[c]) CHECK(m.v[Startup]>=startup_minimum(m));
}
int main() {
    cancel_windows();damage();defense();landing_fd_walls();jumps();counters();
    std::printf("%d tuning checks, %d failures\n",checks,failures);return failures?1:0;
}
