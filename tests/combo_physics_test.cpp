#include "../core/fight.h"
#include <cstdio>
#include <memory>
using namespace fight;
static int checks=0,failures=0;
#define CHECK(x) do {++checks;if(!(x)){++failures;std::fprintf(stderr,"FAIL combo physics %d: %s\n",__LINE__,#x);}}while(0)
static std::unique_ptr<Simulation> fresh(){
    auto s=std::make_unique<Simulation>();s->defaults();s->reset(0,1,0,0);
    s->mobility[1].v[Gravity]=0;
    auto& m=s->moves[0][0];
    m.v[HitboxBack]=0;m.v[Reach]=50000;m.v[Bottom]=-10000;m.v[Height]=60000;
    m.v[Startup]=5;m.v[Active]=6;m.v[Hitstun]=60;m.v[Hitstop]=3;m.v[Damage]=1;
    m.v[Launch]=0;m.v[AirLaunch]=1000;m.v[GroundBounce]=1000;
    m.v[GroundHitSpeed]=100;m.v[AirHitSpeed]=200;
    m.v[Knockdown]=0;m.v[Advance]=m.v[TravelSpeed]=0;
    s->move_hit[0][0]={};return s;
}
static void hit(Simulation& s,bool new_attack=true,int defend=0){
    auto& a=s.world.players[0];auto& b=s.world.players[1];
    s.world.hitstop=0;a.x=40000;b.x=47000;
    if(new_attack)s.preview_begin(0,0);
    a.age=s.moves[0][0].v[Startup]-1;a.hit_done=a.hit_groups=0;
    int count=a.contact_count;s.step(0,defend);CHECK(a.contact_count==count+1);
}
static void physics(){
    auto s=fresh();auto& b=s->world.players[1];
    hit(*s);CHECK(b.combo_decay==5);CHECK(b.push_percent==100);CHECK(b.vx==100);CHECK(b.knockback_left==0);
    auto saved=s->world;
    for(int i=0;i<3;++i)s->step(0,0);
    CHECK(b.x==saved.players[1].x&&b.vx==100&&b.combo_decay==5);
    s->world.players[0].move=-1;s->step(0,0);CHECK(b.vx==85);
    const int after_one=b.x;
    for(int i=0;i<8;++i)s->step(0,0);
    CHECK(b.x>after_one&&b.vx>0); // No six-frame travel cutoff.
    auto crouch=fresh();hit(*crouch,true,Down);crouch->world.hitstop=0;crouch->world.players[0].move=-1;
    crouch->step(0,0);CHECK(crouch->world.players[1].vx==80);
    s->rules.air_hit_drag=100;b.y=5000;b.vx=400;b.vy=-1000;b.reaction=AirReel;
    hit(*s);CHECK(b.combo_decay==10&&b.push_percent==130&&b.launch_percent==90);
    CHECK(b.vx==340&&b.vy==700); // 200*1.3 + 400*.2; 1000*.9 - 1000*.2.
    CHECK(b.bounce_ground==900);
    s->rules.gravity_after=100;hit(*s);
    CHECK(b.repeat_gravity==15&&s->get(1,35)==115); // Third use; old hit threshold is irrelevant.
    b.combo_decay=50;hit(*s);CHECK(b.push_percent==350&&b.launch_percent==25&&b.bounce_ground==250);
    s->world.hitstop=0;s->world.players[0].move=-1;b.y=1;b.vy=-1;b.vx=0;s->step(0,0);
    CHECK(b.vy==250&&b.y==1&&b.bounce_ground==0);
    // Another authored bounce is possible, but does not reset decay or gravity.
    b.y=5000;b.vy=0;hit(*s);CHECK(b.bounce_ground==250&&b.repeat_gravity==45);
    s->world.hitstop=0;s->world.players[0].move=-1;b.stun=0;b.reaction=Free;b.y=0;b.vy=0;
    s->step(0,0);CHECK(b.combo_decay==0&&b.repeat_gravity==0&&b.move_uses[0]==0);
    CHECK(b.push_percent==100&&b.launch_percent==100);
}
static void identities(){
    auto s=fresh();auto& b=s->world.players[1];auto& a=s->world.players[0];
    hit(*s);hit(*s,false);hit(*s,false);
    CHECK(b.combo_decay==5&&b.move_uses[0]==1&&b.repeat_gravity==0&&b.push_percent==100);
    // Persisting projectile A survives while strike B connects, then A re-hits.
    auto& m=s->moves[0][14];m=s->moves[0][0];m.v[Category]=Special;
    m.v[ProjectileKind]=2;m.v[ProjectilePersist]=1;m.v[ProjectileWidth]=40000;m.v[ProjectileHeight]=50000;
    m.v[ProjectileRehit]=1;
    auto& q=s->world.projectiles[0];
    q={100,0,0,14,42,47000,5000,0,0,1,20,0,1};
    s->world.hitstop=0;a.move=-1;s->step(0,0);CHECK(b.combo_decay==10&&b.move_uses[14]==1);
    q.cooldown=100;hit(*s);CHECK(b.combo_decay==15&&b.move_uses[0]==2);
    s->world.hitstop=0;a.move=-1;q.cooldown=0;s->step(0,0);
    CHECK(b.combo_decay==15&&b.move_uses[14]==1&&b.push_percent==130);
    auto state=s->world;
    for(int i=0;i<30;++i)s->step(0,0);
    const auto hash=s->checksum();s->world=state;
    for(int i=0;i<30;++i)s->step(0,0);
    CHECK(s->checksum()==hash); // Decay identities and pending bounce are rollback state.
    auto starter=fresh();starter->moves[0][0].v[StarterDecay]=20;hit(*starter);
    CHECK(starter->world.players[1].combo_decay==25&&starter->world.players[1].push_percent==220);
    hit(*starter,false);CHECK(starter->world.players[1].combo_decay==25);
    auto block=fresh();hit(*block,true,Right);CHECK(block->world.players[1].combo_decay==0);
}
static void cancels(){
    auto s=fresh();
    CHECK(s->can_cancel(4,0,4,1));CHECK(!s->can_cancel(4,0,1,1));
    CHECK(s->can_cancel(4,1,SLASH_SWEEP,1));CHECK(s->can_cancel(4,1,8,1));
    CHECK(s->can_cancel(4,CLOSE_SLASH,FAR_SLASH,1));CHECK(s->can_cancel(4,CLOSE_SLASH,11,1));
    CHECK(s->can_cancel(4,FAR_SLASH,3,1));CHECK(!s->can_cancel(4,FAR_SLASH,10,1));
    CHECK(!s->can_cancel(4,3,11,1));CHECK(!s->can_cancel(4,10,3,1));
    CHECK(s->can_cancel(4,17,17,1));CHECK(!s->can_cancel(4,17,18,1));
    CHECK(s->can_cancel(4,19,20,1));
    s->moves[4][3].v[CommandRoutes]=8;CHECK(s->can_cancel(4,3,11,1)); // Deliberate exception.
    s->moves[4][3].v[CommandRoutes]=-1;
    s->rules.combo_physics=0;CHECK(s->can_cancel(4,0,1,1)&&s->can_cancel(4,3,11,1));
    s->rules.combo_physics=1;
    CHECK(s->can_cancel(5,1,6,1)&&!s->can_cancel(5,3,11,1));
    CHECK(s->can_cancel(5,6,13,1)); // Fillet's explicit knockdown -> Wound confirm.
    CHECK(s->can_cancel(3,37,37,1)); // Tapper stance exception.
    s->reset(0,1,0,0);s->preview_begin(0,0);auto& a=s->world.players[0];a.contact=1;a.event=NormalHit;
    a.age=5;CHECK(s->get(0,53)&2);a.age=11;CHECK(!(s->get(0,53)&2));
}
static void clocks_and_walls(){
    for(int side=0;side<2;++side){
        auto s=fresh();auto& b=s->world.players[1];
        const auto box=s->box(1,PushBox);const int half=(box.right-box.left)/2;
        const int edge=side?100000-half:half;
        b.x=edge+(side?-300:300);b.vx=side?300:-300;b.y=12000;b.vy=0;
        b.reaction=AirReel;b.stun=0;b.slow_time=4;b.slow_phase=0;
        s->world.players[0].x=50000;
        s->step(0,0);CHECK(b.slow_held&&b.vx==(side?300:-300));
        CHECK(s->world.wall_health[side]==1000);
        s->step(0,0);CHECK(b.x==edge&&b.vx==0&&s->world.wall_health[side]==700);
        // A subsequent hit at an already depleted wall splats on either side.
        b.slow_time=0;b.x=edge+(side?-300:300);b.vx=side?300:-300;
        s->world.wall_health[side]=0;s->step(0,0);
        CHECK(b.reaction==WallSplat&&b.vx==0);
    }
    auto s=fresh();auto& b=s->world.players[1];
    b.y=9000;b.vy=-5000;b.reaction=AirReel;b.stun=20;
    s->moves[0][0].v[AirLaunch]=100;hit(*s);
    CHECK(b.vy<0); // A nearly grounded, fast falling target cannot be reset upward.
}
int main(){physics();identities();cancels();clocks_and_walls();std::printf("Combo physics: %d checks, %d failures\n",checks,failures);return failures?1:0;}
