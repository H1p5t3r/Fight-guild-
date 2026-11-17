#include "../core/fight.h"
#include <cstdio>
using namespace fight;
static int checks=0,failures=0;
#define CHECK(x) do {++checks;if(!(x)){++failures;std::fprintf(stderr,"FAIL %d: %s\n",__LINE__,#x);}}while(0)
static Simulation sim;
static void fresh(){sim.defaults();sim.reset(5,4,0,0);sim.preview_place(0,40000,0,10000);sim.preview_place(1,80000,0,10000);}
static void ticks(int n,int a=0,int b=0){for(int i=0;i<n;++i)sim.step(a,b);}
static int count(){return sim.box_count(0,ProjectileBox)+sim.box_count(1,ProjectileBox);}
static void shot(int owner=0,int kind=1){
 int c=sim.world.players[owner].character;auto& m=sim.moves[c][0];
 m.v[ProjectileKind]=kind;m.v[ProjectileOffsetX]=5000;m.v[ProjectileOffsetY]=8000;
 m.v[ProjectileSpeedX]=1000;m.v[ProjectileWidth]=4000;m.v[ProjectileHeight]=6000;
 m.v[Hitstop]=0;m.v[Pushback]=m.v[AirPushback]=m.v[Launch]=m.v[AirLaunch]=0;
 sim.preview_begin(owner,0);
}
int main(){
 for(int style=0;style<4;++style){
  fresh();CHECK(sim.mobility_set(5,ForwardStyle,style));
  sim.step(Right,0);sim.step(0,0);sim.step(Right,0);
  CHECK(style==0?sim.world.players[0].running:sim.world.players[0].dash>0);
  int before=sim.world.players[0].x;ticks(8,Right);
  CHECK(sim.world.players[0].x>before);
  if(style==HoverDash)CHECK(sim.world.players[0].y>0);
  if(style==Teleport)CHECK(sim.world.players[0].vx==0);
 }
 fresh();sim.step(Left,0);sim.step(0,0);sim.step(Left,0);CHECK(sim.world.players[0].dash>0);CHECK(sim.world.players[0].vx<0);
 fresh();sim.mobility_set(5,BackStyle,ForwardRun);sim.step(Left|Dash,0);ticks(8,Left);CHECK(sim.world.players[0].running);CHECK(sim.world.players[0].vx<0);
 fresh();auto& f=sim.world.players[0];f.stun=3;f.guarding=f.guard_break=1;
 sim.step(Left,0);sim.step(0,0);sim.step(Left|Dash,0);sim.step(0,0);CHECK(f.dash==0);
 fresh();sim.preview_place(1,50000,0,10000);sim.mobility_set(5,ForwardStyle,Teleport);sim.mobility_set(5,TeleportDistance,20000);
 sim.step(Dash,0);ticks(5);CHECK(sim.world.players[0].x>sim.world.players[1].x);CHECK(sim.world.players[0].momentum==10000);
 fresh();sim.step(Up,0);ticks(7);int uses=sim.world.players[0].air_dash_used;sim.step(Dash,0);CHECK(sim.world.players[0].air_dash_used==uses);
 sim.mobility_set(5,AirDashEnabled,1);sim.step(0,0);sim.step(Dash,0);CHECK(sim.world.players[0].air_dash_used==1);
 ticks(18);sim.step(Dash,0);CHECK(sim.world.players[0].air_dash_used==1);ticks(100);CHECK(sim.world.players[0].air_dash_used==0);
 fresh();sim.mobility_set(5,AirJumps,1);sim.step(Up,0);ticks(10);sim.step(Up,0);CHECK(sim.world.players[0].air_jump_used==1);CHECK(sim.world.players[0].vy>1200);
 fresh();sim.mobility_set(5,JumpSpeed,2000);sim.step(Up,0);ticks(5);CHECK(sim.world.players[0].vy>1700);
 fresh();sim.mobility_set(5,FdDrain,100);sim.step(Left|Faultless,0);CHECK(sim.world.players[0].momentum==9900);
 sim.mobility_set(5,FdEnabled,0);sim.step(Left|Faultless,0);CHECK(!sim.world.players[0].faultless);CHECK(sim.world.players[0].momentum==9900);
 fresh();shot();ticks(5);CHECK(count()==1);CHECK(sim.box_count(0,HitBox)==0);int x=sim.world.projectiles[0].x;ticks(1);CHECK(sim.world.projectiles[0].x>x);
 ticks(45);CHECK(sim.world.players[1].health<1000);CHECK(sim.world.players[0].contact_count==1);CHECK(count()==0);
 fresh();shot(0,2);ticks(5);x=sim.world.projectiles[0].x;int y=sim.world.projectiles[0].y;ticks(15);CHECK(count()==1);CHECK(sim.world.projectiles[0].x==x&&sim.world.projectiles[0].y==y);
 fresh();shot();ticks(5);sim.world.hitstop=8;x=sim.world.projectiles[0].x;int life=sim.world.projectiles[0].life;ticks(8);CHECK(sim.world.projectiles[0].x==x&&sim.world.projectiles[0].life==life);
 auto snapshot=sim.world;ticks(35);auto expected=sim.checksum();sim.world=snapshot;ticks(35);CHECK(sim.checksum()==expected);
 fresh();shot();ticks(5);sim.world.players[0].stun=10;ticks(1);CHECK(count()==0);
 fresh();sim.moves[5][0].v[ProjectilePersist]=1;shot();ticks(5);sim.world.players[0].stun=10;ticks(1);CHECK(count()==1);
 fresh();sim.preview_place(1,54000,0,10000);shot();shot(1);ticks(5);CHECK(count()==0);CHECK(sim.world.players[0].health==1000&&sim.world.players[1].health==1000);
 fresh();sim.preview_place(1,50000,0,10000);shot(0,2);auto& m=sim.moves[5][0];m.v[ProjectileOffsetX]=10000;m.v[ProjectileHits]=3;m.v[ProjectileRehit]=10;m.v[Hitstun]=30;
 ticks(40);CHECK(sim.world.players[0].contact_count==3);CHECK(sim.world.players[0].combo==3);CHECK(count()==0);
 fresh();shot();ticks(5);sim.world.wall_break_time=60;ticks(1);CHECK(count()==0);
 fresh();sim.preview_place(1,46000,0,10000);shot();auto& fast=sim.moves[5][0];fast.v[ProjectileWidth]=100;fast.v[ProjectileHeight]=100;fast.v[ProjectileOffsetX]=3000;fast.v[ProjectileSpeedX]=4000;fast.v[ProjectileOffsetY]=13000;ticks(5);CHECK(sim.world.players[1].health<1000);
 fresh();sim.preview_place(1,46000,0,10000);sim.mobility_set(4,BackWalkSpeed,1);shot();auto& fast_block=sim.moves[5][0];fast_block.v[ProjectileWidth]=100;fast_block.v[ProjectileHeight]=100;fast_block.v[ProjectileOffsetX]=3000;fast_block.v[ProjectileSpeedX]=4000;fast_block.v[ProjectileOffsetY]=13000;ticks(5,0,Right);CHECK(sim.world.players[1].health==1000);CHECK(sim.world.players[0].event==Blocked);
 fresh();sim.preview_place(1,60000,0,10000);shot();ticks(5);sim.world.projectiles[0].x=59500;sim.world.projectiles[1]=sim.world.projectiles[0];ticks(1);CHECK(sim.world.players[0].combo==2);CHECK(sim.world.players[0].contact_count==2);
 std::printf("Movement / projectiles: %d checks, %d failures\n",checks,failures);return failures?1:0;
}
