#include "legacy_fillet_data.h"
#include "../core/fight.h"
#include <cstdio>
#include <initializer_list>
using namespace fight;
static int checks=0,failures=0;
#define CHECK(x) do { ++checks; if(!(x)) {std::fprintf(stderr,"Wall FAIL %d: %s\n",__LINE__,#x);++failures;} } while(0)
static Simulation fresh() {Simulation s;legacy_fillet::defaults(s);s.reset(5,4,0,0);return s;}
static void tick(Simulation& s,int n=1) {while(n-->0)s.step(0,0);}
static int edge(Simulation& s,int p,int side) {
    auto b=s.box(p,PushBox);int half=(b.right-b.left)/2;
    return side==0?half:100000-half;
}
static void incoming(Simulation& s,int p,int side,int velocity,int health,int height=0) {
    auto& f=s.world.players[p];f.x=edge(s,p,side)+(side==0?velocity:-velocity);
    f.vx=(side==0?-velocity:velocity);f.y=height;f.vy=0;f.stun=40;
    f.knockback_left=0;f.reaction=height?AirReel:Free;f.guarding=0;
    s.world.wall_health[side]=health;
    s.world.players[1-p].x=50000;
}
static void impacts() {
    for(int p:{0,1})for(int side:{0,1})for(int height:{0,12000,80000}) {
        auto s=fresh();incoming(s,p,side,375,1000,height);tick(s);
        auto& f=s.world.players[p];
        CHECK(s.world.wall_health[side]==625&&s.world.wall_health[1-side]==1000);
        CHECK(f.x==edge(s,p,side)&&f.vx==0&&f.reaction!=WallSplat);
        tick(s,5);CHECK(s.world.wall_health[side]==625); // Resting contact cannot drain again.
        incoming(s,p,side,900,625,height);tick(s);
        CHECK(s.world.wall_health[side]==0&&f.reaction!=WallSplat&&f.vx==0);
        tick(s,5);CHECK(f.reaction!=WallSplat); // Zero health alone is not a splat.
        incoming(s,p,side,1,0,height);tick(s);
        CHECK(f.reaction==WallSplat&&f.wall_time==s.rules.wall_splat_frames&&f.vx==0);
        CHECK(f.wall_side==(side==0?-1:1)&&f.y>=height);
        tick(s,s.rules.wall_splat_frames);CHECK(s.world.wall_health[side]==0);
    }
    auto s=fresh();incoming(s,1,1,4000,1000);s.world.players[1].x=edge(s,1,1)-1;
    tick(s);CHECK(s.world.wall_health[1]==0); // Full arriving speed, not remaining gap or overshoot.
    s=fresh();incoming(s,0,0,300,1000);s.world.players[0].stun=1;tick(s);
    CHECK(s.world.wall_health[0]==700); // Last hitstun tick still qualifies.
    s=fresh();incoming(s,0,0,300,1000);s.world.players[0].knockback_left=900;tick(s);
    CHECK(s.world.players[0].knockback_left==0&&s.world.players[0].vx==0);
    s=fresh();incoming(s,0,0,300,1000);s.world.players[0].x=edge(s,0,0);tick(s);
    CHECK(s.world.wall_health[0]==700); // New outward velocity at contact is a fresh impact.
}
static void non_impacts() {
    for(int side:{0,1})for(int mode=0;mode<7;++mode) {
        auto s=fresh();incoming(s,0,side,600,1000,mode==6?80000:0);
        auto& f=s.world.players[0];
        if(mode==0) f.vx=0;
        if(mode==1) f.vx=-f.vx; // Travelling away.
        if(mode==2) f.guarding=1;
        if(mode==3) f.guarding=f.guard_break=1; // Guard break remains blockstun.
        if(mode==4) {f.stun=0;f.running=1;}
        if(mode==5) {f.reaction=Downed;f.recovery_time=10;}
        if(mode==6) f.stun=0; // Air reel after actual hitstun ends.
        tick(s);CHECK(s.world.wall_health[0]==1000&&s.world.wall_health[1]==1000);
    }
    auto s=fresh();s.world.wall_health[0]=0;s.world.wall_health[1]=300;tick(s,500);
    CHECK(s.world.wall_health[0]==0&&s.world.wall_health[1]==300); // No automatic healing.
    s.reset(4,5,0,0);CHECK(s.world.wall_health[0]==1000&&s.world.wall_health[1]==1000);
}
static void travel_and_clocks() {
    auto s=fresh();auto& a=s.world.players[0];auto& b=s.world.players[1];
    a.x=45000;b.x=51000;auto& m=s.moves[5][0];m.v[Hitstop]=3;m.v[Pushback]=1201;
    m.v[Reach]=50000;m.v[Bottom]=0;m.v[Height]=50000;m.v[Hitstun]=30;
    a.move=0;a.age=m.v[Startup]-1;s.step(0,0);
    CHECK(b.x==51000&&b.vx==201&&b.knockback_left==1201);
    tick(s,3);CHECK(b.x==51000&&b.vx==201); // Hitstop freezes movement.
    tick(s,6);CHECK(b.x==52201&&b.vx==0&&b.knockback_left==0);
    s=fresh();incoming(s,1,1,600,1000);b.slow_time=4;b.slow_phase=0;
    auto state=s.world;tick(s);CHECK(s.world.wall_health[1]==1000&&b.vx==600);
    tick(s);CHECK(s.world.wall_health[1]==400&&b.vx==0);
    auto expected=s.checksum();s.world=state;tick(s,2);CHECK(s.checksum()==expected);
    s=fresh();incoming(s,0,0,250,1000);s.world.hitstop=5;tick(s,5);
    CHECK(s.world.wall_health[0]==1000);tick(s);CHECK(s.world.wall_health[0]==750);
    s=fresh();incoming(s,0,0,450,1000);tick(s);
    incoming(s,1,0,250,s.world.wall_health[0]);tick(s);
    CHECK(s.world.wall_health[0]==300&&s.world.wall_health[1]==1000); // Shared wall, independent sides.
}
static void wallboxes() {
    auto s=fresh();CHECK(s.box_count(-1,WallBox)==2&&s.box_count(0,WallBox)==0);
    auto left=s.box(-1,WallBox,0),right=s.box(-1,WallBox,1);
    CHECK(left.right==0&&right.left==100000&&left.bottom<0&&left.top>200000);
    CHECK(left.left< -100000&&right.right>200000&&right.bottom==left.bottom&&right.top==left.top);
}
int main(){impacts();non_impacts();travel_and_clocks();wallboxes();
    std::printf("Collision-driven wall health / velocity / clocks: %d checks, %d failures\n",checks,failures);return failures?1:0;}
