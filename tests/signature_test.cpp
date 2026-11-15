#include "../core/fight.h"
#include <cstdio>
#include <initializer_list>
using namespace fight;
static int checks=0,failures=0;
#define CHECK(x) do { ++checks; if(!(x)) { std::fprintf(stderr,"Signature FAIL %d: %s\n",__LINE__,#x); ++failures; } } while(0)
static void ticks(Simulation& s,int n,int a=0,int b=0) { for(int i=0;i<n;++i) s.step(a,b); }
static void thaw(Simulation& s) { while(s.world.hitstop) s.step(0,0); }
static void fresh(Simulation& s,int c=5,bool mirror=false) {
    s.defaults();s.reset(c,c==5?4:5,0,0);
    s.world.players[0].x=mirror?80000:20000;s.world.players[1].x=mirror?20000:80000;
    s.world.players[0].facing=mirror?-1:1;s.world.players[1].facing=mirror?1:-1;
}
static void motion(Simulation& s,int button,bool back=false,bool mirror=false) {
    int horizontal=(back!=mirror)?Left:Right;
    s.step(Down,0);s.step(Down|horizontal,0);s.step(horizontal|button,0);
}
static void routes() {
    Simulation s;
    for(bool mirror:{false,true}) {
        int forward=mirror?Left:Right;
        fresh(s,5,mirror);motion(s,K,false,mirror);
        CHECK(s.world.players[0].move==KNIFE_SPIRAL);
        fresh(s,5,mirror);motion(s,S,false,mirror);
        CHECK(s.world.players[0].move==15&&s.get(0,29)==3&&s.get(0,30)==1);
        // On whiff, follow-ups open after the starter's active frames, never on startup.
        s.step(0,0);s.step(forward|S,0);CHECK(s.world.players[0].move==15);
        ticks(s,12);s.step(forward|S,0);CHECK(s.world.players[0].move==REKKA_MID);
        ticks(s,12);s.step(Down|S,0);CHECK(s.world.players[0].move==REKKA_LOW);
        fresh(s,5,mirror);motion(s,S,false,mirror);ticks(s,14);
        s.step(Down|S,0);CHECK(s.world.players[0].move==REKKA_LOW);
        fresh(s,5,mirror);motion(s,S,false,mirror);ticks(s,30,S);
        CHECK(s.world.players[0].last_move==15); // Holding S cannot auto-chain.
        fresh(s,5,mirror);s.step(Down|S,0);CHECK(s.world.players[0].move==6);
        fresh(s,4,mirror);motion(s,S,true,mirror);CHECK(s.world.players[0].move==HOOK_GROUND);
        fresh(s,4,mirror);s.world.players[0].y=22000;s.world.players[0].vy=100;
        motion(s,P,true,mirror);CHECK(s.world.players[0].move==HOOK_AIR);
    }
    fresh(s);s.reset(5,4,1,1);s.step(Simple|Right|K,0);CHECK(s.world.players[0].move==KNIFE_SPIRAL);
    s.reset(4,5,1,0);s.step(Simple|Left|S,0);CHECK(s.world.players[0].move==HOOK_GROUND);
    s.reset(4,5,1,0);s.world.players[0].y=22000;s.step(Simple|Left|P,0);CHECK(s.world.players[0].move==HOOK_AIR);
    CHECK(s.can_cancel(5,15,REKKA_LOW,0)&&s.can_cancel(5,REKKA_MID,REKKA_LOW,0));
    CHECK(!s.can_cancel(5,0,REKKA_MID,1)&&!s.can_cancel(5,0,REKKA_LOW,1));
    CHECK(!s.can_cancel(4,HOOK_GROUND,STAB_GROUND,0)&&s.can_cancel(4,HOOK_GROUND,STAB_GROUND,1));
    for(int c=0;c<6;++c) for(int m=25;m<MOVE_COUNT;++m)
        CHECK(bool(s.moves[c][m].v[Enabled])==(c==5?m<=27:c==4?m>=28:false));
}
static void mobility() {
    Simulation s;
    for(bool mirror:{false,true}) for(int c:{0,4,5}) {
        fresh(s,c,mirror);int forward=mirror?Left:Right,sign=mirror?-1:1;
        s.step(forward|Dash,0);ticks(s,5,forward|Dash);
        auto& f=s.world.players[0];int speed=f.vx,x=f.x;
        CHECK(speed*sign>s.mobility[c].v[WalkSpeed]);
        CHECK(bool(f.running)==(c!=0));
        s.step(P,0);CHECK(f.move==0&&f.x-x==speed&&f.vx*sign>0);
        CHECK(f.running==0&&f.dash==0);
        State snapshot=s.world;ticks(s,20);auto hash=s.checksum();s.world=snapshot;ticks(s,20);CHECK(s.checksum()==hash);
        fresh(s,c,mirror);s.step(forward,0);s.step(0,0);s.step(forward,0);
        CHECK(c==0?s.world.players[0].dash>0:s.world.players[0].running==1);
        if(c!=0) {s.step(0,0);CHECK(s.world.players[0].vx==0&&!s.world.players[0].running);}
        fresh(s,c,mirror);s.step((mirror?Right:Left)|Dash,0);int start=s.world.players[0].x;
        s.step(forward,0);CHECK((s.world.players[0].x-start)*sign<0); // Fixed backward burst.
        fresh(s,c,mirror);s.step(forward|Dash,0);ticks(s,5,forward|Dash);
        int vx=s.world.players[0].vx;s.step(Up|forward,0);
        CHECK(s.world.players[0].prejump_time==4&&s.world.players[0].vx==vx);
        ticks(s,4,forward);CHECK(s.world.players[0].y>0&&s.world.players[0].vx==vx);
    }
    fresh(s);s.step(Dash|Right,0);ticks(s,6,Right);s.moves[5][0].v[InertiaPercent]=50;
    int x=s.world.players[0].x,v=s.world.players[0].vx;s.step(P,0);CHECK(s.world.players[0].x-x==v/2);
    fresh(s);auto& f=s.world.players[0];f.move=KNIFE_SPIRAL;f.age=s.moves[5][KNIFE_SPIRAL].v[Startup]-1;
    x=f.x;s.step(0,0);CHECK(f.x-x==s.moves[5][KNIFE_SPIRAL].v[TravelSpeed]);
    CHECK(s.get(0,29)==4&&s.get(0,30)==0&&s.box_count(0,HurtBox)<=4);
    fresh(s,4);s.world.players[0].x=95000;s.world.players[1].x=98000;
    ticks(s,60,Right|Dash);CHECK(s.box(0,PushBox).right<=s.box(1,PushBox).left);
    CHECK(s.world.players[0].vx==0);
    for(int c:{4,5}) for(bool mirror:{false,true}) {
        fresh(s,c,mirror);int forward=mirror?Left:Right;
        s.step(forward|Dash,0);ticks(s,6,forward|Dash);
        int running_speed=s.world.players[0].vx;
        motion(s,c==4?S:K,c==4,mirror);
        CHECK(s.world.players[0].move==(c==4?HOOK_GROUND:KNIFE_SPIRAL));
        CHECK(s.world.players[0].vx==running_speed-(mirror?-45:45));
        CHECK(s.world.players[0].carry_time==0);
        fresh(s,c,mirror);s.step(forward|Dash,0);ticks(s,6,forward|Dash);ticks(s,8);
        s.step(P,0);CHECK(s.world.players[0].vx==0); // No stored speed after the grace expires.
    }
}
static bool hook(Simulation& s,bool air,bool mirror,bool hittable) {
    fresh(s,4,mirror);auto& a=s.world.players[0];auto& b=s.world.players[1];
    a.x=mirror?65000:35000;b.x=a.x+(mirror?-24000:24000);
    a.y=air?22000:0;a.vy=0;b.y=air||!hittable?0:26000;b.vy=0;
    a.move=air?HOOK_AIR:HOOK_GROUND;a.age=s.moves[4][a.move].v[Startup]-1;
    int initial=b.health;
    for(int i=0;i<8&&b.health==initial;++i) {
        s.step(0,0);
        CHECK(s.box_count(0,HitBox)==8&&s.get(0,48));
        int extent=s.get(0,46)-s.get(0,44);CHECK(extent==(mirror?-8000:8000));
        for(int n=0;n<8;++n) {auto box=s.box(0,HitBox,n);CHECK(box.right-box.left==1000&&box.top-box.bottom==2200);}
    }
    return b.health<initial;
}
static void hooks() {
    Simulation s;
    for(bool mirror:{false,true}) for(bool air:{false,true}) {
        CHECK(hook(s,air,mirror,true));auto& a=s.world.players[0];auto& b=s.world.players[1];
        CHECK(b.reaction==Reeled&&b.pull_owner==0&&b.pull_time==10);
        thaw(s);State snapshot=s.world;
        int before=(b.x-a.x)*a.facing;s.step(P,0);
        CHECK(a.move==(air?STAB_AIR:STAB_GROUND));
        CHECK((b.x-a.x)*a.facing<before);
        ticks(s,24);auto hash=s.checksum();
        CHECK(b.health==948&&a.combo>=2); // Hook 25 + scaled blade 27 remains a true combo.
        s.world=snapshot;s.step(P,0);ticks(s,24);CHECK(s.checksum()==hash);
    }
    CHECK(!hook(s,false,false,false));s.step(P,0);CHECK(s.world.players[0].move==HOOK_GROUND);
    // Blocked contact never grants the hit-only stab route.
    fresh(s,4);auto& a=s.world.players[0];a.move=HOOK_GROUND;a.age=25;a.contact=1;a.event=Blocked;
    s.step(P,0);CHECK(a.move==HOOK_GROUND);
    // If the pulling fighter is interrupted, the victim is released without a stuck state.
    CHECK(hook(s,false,false,true));thaw(s);s.world.players[0].stun=10;s.step(0,0);
    CHECK(s.world.players[1].reaction!=Reeled&&s.world.players[1].pull_owner==-1);
}
static void rekka_hits() {
    for(bool skip:{false,true}) {
        Simulation s;s.defaults();s.reset(5,4,0,0);s.world.players[1].x=48000;
        motion(s,S);int stage=0,highest=0;
        for(int tick=0;tick<80;++tick) {
            int input=0;
            if(s.world.players[0].contact&&!s.world.hitstop&&stage<(skip?1:2)) {
                input=(stage==0&&!skip?Right:Down)|S;++stage;
            }
            s.step(input,0);
            if(s.world.players[0].combo>highest) highest=s.world.players[0].combo;
        }
        CHECK(highest==(skip?2:3));CHECK(s.world.players[1].health==(skip?930:911));
    }
    for(bool crouch:{false,true}) {
        Simulation s;s.defaults();s.reset(5,4,0,0);s.world.players[1].x=48000;
        auto& a=s.world.players[0];a.move=REKKA_LOW;a.age=s.moves[5][REKKA_LOW].v[Startup]-1;
        s.step(0,Right|(crouch?Down:0));CHECK(bool(s.world.players[1].guarding)==crouch);
        CHECK(s.world.players[1].health==(crouch?997:955));
    }
}
int main() { routes();mobility();hooks();rekka_hits();std::printf("Signature moves / movement: %d checks, %d failures\n",checks,failures);return failures?1:0; }
