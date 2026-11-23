#include <memory>
#include "legacy_fillet_data.h"
#include "../core/fight.h"
#include <initializer_list>
#include <cstdio>
using namespace fight;
static int checks=0,failures=0;
#define CHECK(x) do { ++checks; if(!(x)) { std::fprintf(stderr,"FAIL recovery line %d: %s\n",__LINE__,#x); ++failures; } } while(0)
static void initialize(Simulation& s) { legacy_fillet::defaults(s); s.reset(5,4,0,0);
    s.world.players[0].x=45000; s.world.players[1].x=51000;
}
static void ticks(Simulation& s,int n,int a=0,int b=0) { for(int i=0;i<n;++i) s.step(a,b); }
static void thaw(Simulation& s) { while(s.world.hitstop&&!s.world.wall_break_time) s.step(0,0); }
static void commit_throw(Simulation& s){while(s.world.pair.kind||s.world.hitstop)s.step(0,0);}
static void prime(Simulation& s,int player=0,int slot=0) {
    auto& f=s.world.players[player]; f.move=slot; f.age=s.moves[f.character][slot].v[Startup]-1;
    f.hit_done=0;
}
static Move& wide(Simulation& s,int slot=0) {
    auto& m=s.moves[5][slot]; m.v[Reach]=50000; m.v[HitboxBack]=0;
    m.v[Bottom]=0; m.v[Height]=50000; return m;
}
static void test_universals() {
    for(int c=0;c<CHARACTER_COUNT;++c) {
        auto s_storage=std::make_unique<Simulation>();auto& s=*s_storage;initialize(s); s.reset(c,(c+1)%6,0,0);
        CHECK(s.moves[c][SLASH_SWEEP].v[Knockdown]==HardKnockdown);
        CHECK(s.moves[c][SLASH_SWEEP].v[HitLevel]==1);
        for(int slot=BACK_THROW;slot<=FORWARD_THROW;++slot) {
            CHECK(s.moves[c][slot].v[Startup]==2);
            CHECK(s.moves[c][slot].v[Knockdown]==HardKnockdown);
            CHECK(!s.can_cancel(c,0,slot,1));
        }
        for(int raw:{Down|D,Down|Left|D,Down|Right|D}) {
            s.reset(c,(c+1)%6,0,0);s.step(raw,0);CHECK(s.world.players[0].move==(c==1?13:SWEEP)); // Hammer has only Break Step on D.
        }
    }
    for(int guard:{int(Right),Right|Down}) {
        auto s_storage=std::make_unique<Simulation>();auto& s=*s_storage;initialize(s);wide(s,SWEEP);prime(s,0,SWEEP);s.step(0,guard);
        CHECK((s.world.players[1].health<1000)==(guard==Right));
        CHECK((s.world.players[1].knockdown==HardKnockdown)==(guard==Right));
        CHECK(s.world.wall_health[0]==1000&&s.world.wall_health[1]==1000);
    }
    for(int direction:{Left,Right}) {
        auto s_storage=std::make_unique<Simulation>();auto& s=*s_storage;initialize(s);int slot=direction==Left?BACK_THROW:FORWARD_THROW;
        ticks(s,1,direction|P|K);CHECK(s.world.players[0].move==slot);
        CHECK(s.world.players[1].health==1000);
        s.step(direction|P|K,0);
        CHECK(s.world.pair.kind==LegacyCapture&&s.world.players[1].health==1000);commit_throw(s);
        CHECK(s.world.players[1].health==920&&s.world.players[1].knockdown==HardKnockdown);
        CHECK((s.world.players[0].x>s.world.players[1].x)==(direction==Left));
        CHECK(s.world.players[0].faultless==0&&s.world.players[0].hit_done==1);
    }
    auto left_storage=std::make_unique<Simulation>();auto& left=*left_storage;initialize(left);ticks(left,5,0,Left|P|K);commit_throw(left);
    CHECK(left.world.players[1].last_move==FORWARD_THROW&&left.world.players[0].health==920);
    auto backward_storage=std::make_unique<Simulation>();auto& backward=*backward_storage;initialize(backward);ticks(backward,5,0,Right|P|K);commit_throw(backward);
    CHECK(backward.world.players[1].last_move==BACK_THROW&&backward.world.players[1].x<backward.world.players[0].x);
    auto fd_storage=std::make_unique<Simulation>();auto& fd=*fd_storage;initialize(fd);fd.world.players[0].momentum=1000;fd.step(Left|Faultless|P|K,0);
    CHECK(fd.world.players[0].faultless&&fd.world.players[0].move==-1);
    auto whiff_storage=std::make_unique<Simulation>();auto& whiff=*whiff_storage;initialize(whiff);whiff.world.players[1].x=65000;ticks(whiff,50,Right|P|K);
    CHECK(whiff.world.players[1].health==1000&&whiff.world.players[0].move==-1);
    for(int mode=0;mode<6;++mode) {
        auto s_storage=std::make_unique<Simulation>();auto& s=*s_storage;initialize(s);auto& d=s.world.players[1];
        d.stun=20;d.guarding=mode<2;d.guard_break=mode==1;
        if(mode==3) { d.y=5000;d.vy=500; }
        if(mode==4||mode==5) { d.reaction=mode==4?Downed:Waking;d.recovery_time=30; }
        prime(s,0,FORWARD_THROW);s.step(0,0);commit_throw(s);
        CHECK((d.health==920)==(mode==1)); // Only guard break removes stun's throw protection.
    }
    auto clash_storage=std::make_unique<Simulation>();auto& clash=*clash_storage;initialize(clash);ticks(clash,5,Right|P|K,Left|P|K);
    CHECK(clash.world.players[0].health==1000&&clash.world.players[1].health==1000);
    CHECK(clash.world.players[0].pair_recovery==12&&clash.world.players[1].pair_recovery==12);
    auto strike_storage=std::make_unique<Simulation>();auto& strike=*strike_storage;initialize(strike);prime(strike,0,FORWARD_THROW);prime(strike,1,0);strike.step(0,0);
    CHECK(strike.world.players[0].health<1000&&strike.world.players[1].health==1000);
}
static void test_recovery() {
    auto s_storage=std::make_unique<Simulation>();auto& s=*s_storage;initialize(s);auto& m=wide(s);m.v[Launch]=1200;m.v[Knockdown]=SoftKnockdown;
    m.v[KnockdownFrames]=6;m.v[WakeupFrames]=8;prime(s);s.step(0,0);
    CHECK(s.world.players[1].reaction==AirReel&&s.world.players[1].vy==1200);
    int y=s.world.players[1].y;ticks(s,3);CHECK(s.world.players[1].y==y);
    thaw(s);
    int guard=0;
    while(s.world.players[1].reaction==AirReel&&guard++<180) s.step(0,0);
    CHECK(guard<180&&s.world.players[1].reaction==Downed&&s.world.players[1].y==0);
    int landing_x=s.world.players[1].x;
    int health=s.world.players[1].health;
    prime(s);s.step(0,Left|Up|Dash);
    CHECK(s.world.players[1].health==health); // No OTG hit during automatic tech.
    ticks(s,5,0,Left|Up|Dash);
    CHECK(s.world.players[1].reaction==Waking&&s.world.players[1].recovery_time==8);
    ticks(s,8,0,Left|Up|Dash);
    CHECK(s.world.players[1].reaction==Free&&s.world.players[1].x==landing_x);
    CHECK(s.world.players[1].combo_received==0&&s.get(1,35)==100);
    auto hard_storage=std::make_unique<Simulation>();auto& hard=*hard_storage;initialize(hard);prime(hard,0,FORWARD_THROW);hard.step(0,0);commit_throw(hard);thaw(hard);
    for(int i=0;i<120&&hard.world.players[1].reaction==AirReel;++i) hard.step(0,0);
    CHECK(hard.world.players[1].reaction==Downed&&hard.world.players[1].recovery_time==36);
    ticks(hard,35,0,Up|Dash);CHECK(hard.world.players[1].reaction==Downed);
    hard.step(0,0);CHECK(hard.world.players[1].reaction==Waking);
    auto reversal_storage=std::make_unique<Simulation>();auto& reversal=*reversal_storage;initialize(reversal);auto& d=reversal.world.players[1];
    reversal.moves[4][16].v[Enabled]=1;d.simple=1;d.reaction=Waking;d.recovery_time=2;d.knockdown=SoftKnockdown;
    ticks(reversal,3,0,Simple|Up|Hs);
    CHECK(d.move==16&&d.reversal_time==NOTICE_TICKS&&d.y==0);
    for(int slot:{0,FORWARD_THROW}) {
        auto last_storage=std::make_unique<Simulation>();auto& last=*last_storage;initialize(last);wide(last);auto& recovering=last.world.players[1];
        recovering.reaction=Waking;recovering.recovery_time=1;
        prime(last,0,slot);last.step(0,0);
        CHECK(recovering.health==1000&&recovering.reaction==Free);
    }
    for(int type=0;type<3;++type) {
        auto k_storage=std::make_unique<Simulation>();auto& k=*k_storage;initialize(k);auto& move=wide(k);move.v[Pushback]=1000;move.v[AirPushback]=5000;move.v[BlockPushback]=7000;
        move.v[Launch]=1000;move.v[AirLaunch]=-200;
        auto& target=k.world.players[1];int old=target.x;
        if(type==1) {target.y=5000;target.vy=0;}
        if(type==2) {target.stun=1;target.guarding=1;}
        prime(k);k.step(0,type==2?Right:0);
        CHECK(target.x-old==(type==2?7000:0));
        CHECK(target.vx==(type==0?167:type==1?834:0));
        CHECK(target.vy==(type==0?1000:type==1?-200:0));
        CHECK((target.reaction==AirReel)==(type<2));
    }
}
static void test_gravity() {
    auto s_storage=std::make_unique<Simulation>();auto& s=*s_storage;initialize(s);auto& d=s.world.players[1];auto& a=s.world.players[0];
    d.y=12000;d.reaction=AirReel;d.combo_received=5;d.stun=20;a.combo=5;
    s.step(0,0);CHECK(d.vy==-85&&s.get(1,35)==100);
    wide(s).v[AirLaunch]=1000;prime(s);s.step(0,0);
    CHECK(a.combo==6&&d.combo_received==6&&s.get(1,35)==110);
    int vy=d.vy;thaw(s);CHECK(d.vy==vy);s.step(0,0);CHECK(d.vy==vy-93);
    d.combo_received=1000;CHECK(s.get(1,35)==200);
    CHECK(s.rule_set(GravityAfter,8)&&s.rule_set(GravityStep,20)&&s.rule_set(GravityCap,150));
    d.combo_received=8;CHECK(s.get(1,35)==100);
    d.combo_received=9;CHECK(s.get(1,35)==120);
    d.combo_received=11;CHECK(s.get(1,35)==150);
    d.reaction=Free;d.stun=0;d.vy=0;s.step(0,0);CHECK(d.vy==-85&&d.combo_received==0);
    CHECK(!s.rule_set(GravityCap,99)&&!s.rule_set(GravityStep,-1));
}
static Simulation splat(int actor=0) {
    auto s_storage=std::make_unique<Simulation>();auto& s=*s_storage;initialize(s);s.rules.wall_threshold=100;s.reset(5,4,0,0);
    auto& m=s.moves[s.world.players[actor].character][0];
    m.v[Reach]=50000;m.v[Bottom]=0;m.v[Height]=50000;m.v[Damage]=20;
    m.v[Launch]=0;m.v[Pushback]=m.v[AirPushback]=1200;m.v[Hitstun]=60;
    m.v[StarterProration]=100;m.v[ComboScaling]=0;
    s.world.players[actor].x=actor==0?90000:10000;
    s.world.players[1-actor].x=actor==0?100000:0;
    s.step(0,0);
    // First collision depletes the wall; the next collision splats.
    for(int hit=0;hit<2;++hit) {prime(s,actor);s.step(0,0);thaw(s);s.step(0,0);}
    return s;
}
static void test_walls() {
    for(int actor=0;actor<2;++actor) {
        auto s=splat(actor);auto& d=s.world.players[1-actor];
        CHECK(d.reaction==WallSplat&&d.wall_time==60&&s.world.wall_health[actor==0?1:0]==0);
        int y=d.y;thaw(s);s.step(0,0);CHECK(d.y==y&&d.wall_time==59);
        prime(s,actor);s.step(0,0);
        CHECK(s.world.wall_break_time==s.rules.wall_break_frames&&s.world.wall_break_actor==actor);
        CHECK(d.health==890&&s.world.players[actor].combo==3);
        int timer=s.world.remaining;unsigned expected=0;
        State snapshot=s.world;
        ticks(s,s.rules.wall_break_frames,Left|P,Right|K);expected=s.checksum();
        CHECK(s.world.wall_break_time==0&&s.world.stage==(actor==0?1:2)&&s.world.remaining==timer);
        CHECK(s.world.players[actor].positive_time==360&&d.health==890);
        CHECK(d.reaction==Free&&d.y==0&&d.stun==0&&s.world.wall_health[actor==0?1:0]==100&&d.combo_received==0);
        CHECK(s.world.players[0].x<s.world.players[1].x);
        s.world=snapshot;ticks(s,s.rules.wall_break_frames,Left|P,Right|K);CHECK(s.checksum()==expected);
        s.step(Left|P,Right|K);CHECK(s.world.players[0].move==-1&&s.world.players[1].move==-1);
        int meter=s.world.players[actor].momentum;
        s.step(0,0);CHECK(s.world.players[actor].momentum==meter+5);
    }
    auto timeout=splat();thaw(timeout);ticks(timeout,60);
    CHECK(timeout.world.players[1].reaction==AirReel&&timeout.world.wall_health[1]==0);
    for(int i=0;i<100&&timeout.world.players[1].reaction!=Free;++i) timeout.step(0,0);
    CHECK(timeout.world.players[1].reaction==Free&&timeout.world.stage==0);
    auto last=splat();thaw(last);ticks(last,59);prime(last);last.step(0,0);
    CHECK(last.world.wall_break_time==last.rules.wall_break_frames); // The final splat tick remains a follow-up opportunity.
    auto block_storage=std::make_unique<Simulation>();auto& block=*block_storage;initialize(block);wide(block).v[WallDamage]=5000;prime(block);block.step(0,Right);
    CHECK(block.world.wall_health[0]==1000&&block.world.wall_health[1]==1000&&block.world.wall_break_time==0);
    auto bonus_storage=std::make_unique<Simulation>();auto& bonus=*bonus_storage;initialize(bonus);wide(bonus).v[Damage]=20;bonus.world.players[0].positive_time=1;
    prime(bonus);bonus.step(0,0);
    CHECK(bonus.world.players[0].momentum==245&&bonus.world.players[0].positive_time==0);
    auto fd_storage=std::make_unique<Simulation>();auto& fd=*fd_storage;initialize(fd);fd.world.players[0].positive_time=1;fd.world.players[0].momentum=1000;
    fd.step(Left|Faultless,0);
    CHECK(fd.world.players[0].momentum==1000-fd.rules.fd_drain&&fd.world.players[0].positive_time==0);
    auto mid_storage=std::make_unique<Simulation>();auto& mid=*mid_storage;initialize(mid);wide(mid).v[WallDamage]=400;prime(mid);mid.step(0,0);
    CHECK(mid.world.wall_health[0]==1000&&mid.world.wall_health[1]==1000&&mid.world.players[1].reaction==Free);
    thaw(mid);ticks(mid,mid.rules.wall_decay_delay+1);
    CHECK(mid.world.wall_health[0]==1000&&mid.world.wall_health[1]==1000);
    auto ko=splat();thaw(ko);ko.world.players[1].health=30;prime(ko);ko.step(0,0);
    CHECK(ko.world.winner==-1&&ko.world.players[1].health==0);
    ticks(ko,ko.rules.wall_break_frames);CHECK(ko.world.winner==0&&ko.world.wall_break_time==0);
    auto replay=splat();thaw(replay);State state=replay.world;prime(replay);replay.step(0,0);
    ticks(replay,100);unsigned hash=replay.checksum();
    replay.world=state;prime(replay);replay.step(0,0);ticks(replay,100);CHECK(replay.checksum()==hash);
}
static void test_stage_routes() {
    for(int stage=0;stage<STAGE_COUNT;++stage) for(int actor=0;actor<2;++actor)
    for(int duration:{30,90,150,151,300}) {
        auto s=splat(actor); s.world.stage=stage; s.rules.wall_break_frames=duration;
        thaw(s); prime(s,actor); s.step(0,0);
        int side=actor==0?1:-1, target=(stage+(side>0?1:2))%STAGE_COUNT;
        CHECK(s.world.wall_break_side==side);
        State origin=s.world;
        CHECK(origin.wall_break_x[0]==origin.players[0].x&&origin.wall_break_x[1]==origin.players[1].x);
        int cut=duration-duration/3;
        ticks(s,cut-1,Left|P,Right|K);
        CHECK(s.world.stage==stage&&s.world.remaining==origin.remaining);
        s.step(Left|P,Right|K);
        CHECK(s.world.stage==target&&s.world.wall_break_time==duration/3);
        CHECK(s.world.players[actor].x==(side>0?42000:58000));
        CHECK(s.world.wall_break_x[0]==origin.wall_break_x[0]&&s.world.wall_break_y[1]==origin.wall_break_y[1]);
        State landing=s.world; ticks(s,duration/3,Left|P,Right|K);
        CHECK(s.world.stage==target&&s.world.wall_break_time==0&&s.world.remaining==origin.remaining);
        unsigned hash=s.checksum(); s.world=landing; ticks(s,duration/3,Left|P,Right|K); CHECK(s.checksum()==hash);
        s.world=origin; ticks(s,duration,Left|P,Right|K); CHECK(s.checksum()==hash);
    }
}
static void test_recovery_poses() {
    for(int c=0;c<CHARACTER_COUNT;++c) for(int kd:{SoftKnockdown,HardKnockdown}) for(int wake:{0,1,8,21}) {
        auto s_storage=std::make_unique<Simulation>();auto& s=*s_storage;initialize(s);s.reset(c,(c+1)%6,0,0);
        auto& f=s.world.players[0];f.reaction=Downed;f.knockdown=kd;
        f.recovery_time=3;f.wakeup_frames=wake;
        const int phase=kd==HardKnockdown?9:10;
        CHECK(s.get(0,29)==phase&&s.get(0,30)==0);
        s.world.hitstop=4;ticks(s,4);
        CHECK(f.recovery_time==3&&s.get(0,29)==phase&&s.get(0,30)==0);
        ticks(s,3);
        CHECK(f.reaction==(wake?Waking:Free));
        State before=s.world;
        for(int t=0;t<wake;++t) {
            CHECK(s.get(0,29)==phase);
            CHECK(s.get(0,30)==(wake==1?5:1+t*4/(wake-1)));
            CHECK(Simulation::pose_box_count(c,phase,s.get(0,30))==3);
            s.step(0,0);
        }
        CHECK(f.reaction==Free&&f.recovery_time==0);
        unsigned hash=s.checksum();s.world=before;ticks(s,wake);CHECK(s.checksum()==hash);
    }
}
int main() {
    test_universals();test_recovery();test_recovery_poses();test_gravity();test_walls();test_stage_routes();
    std::printf("Recovery / throws / combo gravity / walls: %d checks, %d failures\n",checks,failures);
    return failures?1:0;
}
