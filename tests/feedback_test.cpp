#include "legacy_fillet_data.h"
#include "../core/fight.h"
#include <cstdio>
#include <cstring>
#include <initializer_list>
using namespace fight;
static Simulation s;
static int failures=0,checks=0;
#define CHECK(x) do{++checks;if(!(x)){++failures;std::fprintf(stderr,"Feedback %d: %s\n",__LINE__,#x);}}while(0)
static int count(int kind){int n=0;for(int i=0;i<s.cue_count;++i)n+=s.cues[i].v[1]==kind;return n;}
static void setup(int facing=1){
    legacy_fillet::defaults(s);s.reset(5,4,0,0);
    auto& a=s.world.players[0];auto& b=s.world.players[1];
    a.x=50000-facing*5000;b.x=50000+facing*5000;a.facing=facing;b.facing=-facing;
    auto& m=s.moves[5][0];m.v[Reach]=30000;m.v[Bottom]=0;m.v[Height]=30000;
    m.v[Pushback]=m.v[AirPushback]=m.v[BlockPushback]=0;m.v[CounterTier]=3;
    m.v[CounterFreezeFrames]=21;m.v[CounterSlowFrames]=0;m.v[Hitstop]=8;
    a.move=0;a.age=m.v[Startup]-1;
}
static void contacts(){
    for(int facing:{-1,1})for(int kind:{HitCue,BlockCue,CounterCue,PunishCue,GuardBreakCue,FaultlessCue,ArmorCue}){
        setup(facing);auto& b=s.world.players[1];int input=0;
        if(kind==BlockCue||kind==GuardBreakCue||kind==FaultlessCue)input=facing>0?Right:Left;
        if(kind==GuardBreakCue)s.moves[5][0].v[GuardBreak]=1;
        if(kind==FaultlessCue){b.momentum=10000;input|=Faultless;}
        if(kind==CounterCue||kind==PunishCue||kind==ArmorCue){b.move=3;b.age=kind==PunishCue?s.moves[4][3].v[Startup]+s.moves[4][3].v[Active]:0;}
        if(kind==ArmorCue){s.moves[4][3].v[ArmorFrames]=20;b.armor_left=1;}
        s.step(0,input);CHECK(count(kind)==1);CHECK(count(SwingCue)==1);
        for(int i=0;i<s.cue_count;++i)if(s.cues[i].v[1]==kind){
            CHECK(s.cues[i].v[0]==0&&s.cues[i].v[2]==0&&s.cues[i].v[3]==5&&s.cues[i].v[4]==0);
            CHECK(s.cues[i].v[8]==facing&&s.cues[i].v[6]>b.x-12000&&s.cues[i].v[6]<b.x+12000);
            CHECK(s.cues[i].v[7]>=8000); // Tall mid strikes must not pick the legs merely because they are first.
        }
        for(int n=0;n<8;++n){s.step(0,input);CHECK(s.cue_count==0);}
    }
    setup();s.world.players[1].x=99000;s.step(0,0);CHECK(count(SwingCue)==1&&count(HitCue)==0);
    s.reset(5,4,0,0);CHECK(s.cue_count==0);
}
static void strike_height(){
    for(int facing:{-1,1})for(int bottom:{0,12000}){
        setup(facing);auto& m=s.moves[5][0];m.v[Bottom]=bottom;m.v[Height]=2700;
        s.step(0,0);CHECK(count(HitCue)==1);
        for(int i=0;i<s.cue_count;++i)if(s.cues[i].v[1]==HitCue)
            CHECK(s.cues[i].v[7]>=bottom&&s.cues[i].v[7]<=bottom+2700);
    }
}
static void multi_and_replay(){
    setup();auto& m=s.moves[5][0];m.v[Active]=5;m.v[Hitstop]=0;m.v[Hitstun]=80;
    s.move_hit[5][0]={};s.move_hit[5][0].multi=1;s.move_hit[5][0].count=2;
    s.move_hit[5][0].keys[0]={1,1,-1,-1,-1,-1,-1,{}};
    s.move_hit[5][0].keys[1]={4,2,-1,-1,-1,-1,-1,{}};
    int hits=0;
    for(int n=0;n<6;++n){
        const State before=s.world;s.step(0,0);const auto hash=s.checksum();
        Cue expected[MAX_CUES];std::memcpy(expected,s.cues,sizeof expected);int size=s.cue_count;hits+=count(HitCue);
        s.world=before;s.step(0,0);
        CHECK(s.checksum()==hash&&s.cue_count==size&&std::memcmp(s.cues,expected,size*sizeof(Cue))==0);
    }
    CHECK(hits==2);
    setup();s.step(0,0);CHECK(count(HitCue)==1);
    auto hash=s.checksum();s.cue_count=0;CHECK(s.checksum()==hash); // Cues are not gameplay state.
}
static void projectiles(){
    setup();s.world.players[0].move=-1;
    auto& m=s.moves[5][14];m.v[ProjectileKind]=1;m.v[ProjectilePersist]=1;
    m.v[ProjectileWidth]=12000;m.v[ProjectileHeight]=12000;m.v[ProjectileLife]=100;m.v[Hitstop]=0;
    s.world.projectiles[0]={100,0,5,14,77,45000,8000,12000,0,1,1,0,1};
    s.step(0,0);CHECK(count(HitCue)==1);
    for(int i=0;i<s.cue_count;++i)if(s.cues[i].v[1]==HitCue)CHECK(s.cues[i].v[4]==14&&s.cues[i].v[5]==77&&s.cues[i].v[10]==1);
    setup();s.world.players[0].move=-1;s.world.players[1].x=90000;
    for(int c:{4,5}){s.moves[c][14].v[ProjectileKind]=1;s.moves[c][14].v[ProjectileWidth]=10000;s.moves[c][14].v[ProjectileHeight]=10000;}
    s.world.projectiles[0]={100,0,5,14,2,50000,20000,0,0,1,1,0,1};
    s.world.projectiles[1]={100,1,4,14,2,50000,20000,0,0,-1,1,0,1};
    s.step(0,0);CHECK(count(ClashCue)==1&&count(HitCue)==0);
}
static void utilities_and_throws(){
    for(int c:{1,4}){
        s.defaults();s.reset(c,5,0,0);CHECK(s.preview_begin(0,c==4?22:13));
        for(int n=0;n<60;++n){s.step(0,0);CHECK(count(HitCue)+count(BlockCue)+count(CounterCue)==0);}
    }
    s.defaults();s.reset(5,4,0,0);s.world.players[0].x=47000;s.world.players[1].x=53000;
    CHECK(s.preview_begin(0,FORWARD_THROW));int hits=0;
    for(int n=0;n<100;++n){int hp=s.world.players[1].health;s.step(0,0);hits+=count(HitCue);if(count(HitCue))CHECK(s.world.players[1].health<hp);}
    CHECK(hits==1); // Capture and held animation do not emit early impacts.
    s.defaults();s.reset(5,4,0,0);s.world.players[1].reaction=Downed;s.world.players[1].recovery_time=90;
    s.world.players[0].x=47000;s.world.players[1].x=53000;CHECK(s.preview_begin(0,13));
    for(int n=0;n<100;++n){s.step(0,0);CHECK(count(HitCue)==0);} // Wound/bleed is not a strike.
}
static void walls_and_landing(){
    setup();s.world.players[0].move=-1;auto& b=s.world.players[1];
    auto box=s.box(1,PushBox);b.x=100000-(box.right-box.left)/2-300;
    b.vx=1000;b.stun=40;b.reaction=AirReel;b.y=12000;
    s.step(0,0);CHECK(count(WallCue)==1);
    for(int n=0;n<4;++n){s.step(0,0);CHECK(count(WallCue)==0);}
    setup();s.world.players[1].reaction=WallSplat;s.world.players[1].wall_time=50;
    s.step(0,0);CHECK(count(WallBreakCue)==1&&count(HitCue)==1);
    setup();s.world.players[0].move=-1;s.world.players[1].y=50;s.world.players[1].vy=-300;
    s.step(0,0);CHECK(count(LandCue)==1);s.step(0,0);CHECK(count(LandCue)==0);
}
int main(){contacts();strike_height();multi_and_replay();projectiles();utilities_and_throws();walls_and_landing();
    std::printf("Feedback: %d checks, %d failures\n",checks,failures);return failures?1:0;}
