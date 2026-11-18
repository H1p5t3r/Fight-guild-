#include "../core/fight.h"
#include <cstdio>
using namespace fight;
static int checks=0,failures=0;
#define CHECK(x) do {++checks;if(!(x)){std::fprintf(stderr,"Tapper FAIL %d: %s\n",__LINE__,#x);++failures;}} while(0)
static void setup(Simulation& s){s.defaults();s.reset(3,4,0,0);s.preview_place(0,40000,0,10000);s.preview_place(1,47000,0,10000);}
static void ticks(Simulation& s,int n,int a=0,int b=0){while(n-->0)s.step(a,b);}
static void thaw(Simulation& s){while(s.world.hitstop)s.step(0,0);}
static void hit(Simulation& s,int move,int guard=0){s.preview_begin(0,move);s.world.players[0].age=s.moves[3][move].v[Startup]-1;s.step(0,guard);}
static void inputs_and_stance(){
 Simulation s;setup(s);auto& a=s.world.players[0];auto& b=s.world.players[1];
 s.step(S,0);CHECK(a.move==CLOSE_SLASH);setup(s);b.x=60000;s.step(S,0);CHECK(a.move==2);
 setup(s);a.stance=1;s.step(S,0);CHECK(a.move==STANCE_S);CHECK(s.can_cancel(3,STANCE_S,STANCE_S,1));
 CHECK(s.can_cancel(3,STANCE_S,STANCE_HS,1));CHECK(s.can_cancel(3,STANCE_HS,STANCE_K,1));CHECK(s.can_cancel(3,STANCE_K,STANCE_EXIT,1));CHECK(!s.can_cancel(3,STANCE_K,STANCE_K,1));
 setup(s);a.stance=1;hit(s,STANCE_S,Right);CHECK(b.guarding);thaw(s);s.step(Down|D,Right);CHECK(a.move==STANCE_EXIT&&!a.stance);
 ticks(s,11);CHECK(a.move<0);CHECK(s.box_count(0,HitBox)==0);
 // Stance never grants either ordinary guard or Faultless Defense.
 setup(s);a.stance=1;s.preview_begin(1,0);b.age=s.moves[4][0].v[Startup]-1;s.step(Left|Faultless,0);CHECK(a.health<1000&&!a.guarding&&!a.faultless&&!a.stance);
 // Real 236D input; ordinary P+K cannot substitute for the stance command throw.
 setup(s);a.stance=1;s.step(Down,0);s.step(Down|Right,0);s.step(Right|D,0);CHECK(a.move==STANCE_THROW);
 setup(s);a.stance=1;s.step(Right|P|K,0);CHECK(a.move!=FORWARD_THROW&&a.move!=STANCE_THROW);
 // Step dash moves for a finite time and carries momentum into an attack.
 setup(s);b.x=85000;s.step(Dash,0);CHECK(a.dash_kind==StepDash&&!a.running);ticks(s,4);int x=a.x;s.step(P,0);CHECK(a.move==0&&a.x>x&&a.vx>0);
}
static void captures(){
 Simulation s;setup(s);auto& a=s.world.players[0];auto& b=s.world.players[1];
 hit(s,13);CHECK(b.reaction==Captured&&a.grab_time>0&&b.health==1000&&s.get(-1,21)==0);ticks(s,25);
 CHECK(a.stance==1&&b.health==935&&a.contact_count==1);CHECK(b.knockdown==SoftKnockdown);
 setup(s);s.moves[3][13].v[ArtPose]=s.moves[3][13].v[FinishArtPose]=0;hit(s,13);CHECK(s.get(0,30)>=0&&s.box_count(0,HurtBox)>0);
 setup(s);hit(s,13,Right);CHECK(b.guarding&&!a.stance&&!a.grab_time);
 for(int immune=0;immune<4;++immune){
  setup(s);a.stance=1;if(immune==1){b.stun=10;b.guarding=1;}if(immune==2)b.throw_grace=5;if(immune==3)b.y=10000;
  hit(s,STANCE_THROW,Right);CHECK((b.reaction==Captured)==(immune==0));
 }
 setup(s);a.stance=1;hit(s,STANCE_THROW,Right);CHECK(b.health==1000);ticks(s,25);CHECK(b.health==860&&a.stance&&a.contact_count==1&&b.knockdown==HardKnockdown);
 setup(s);hit(s,BACK_THROW);ticks(s,22);CHECK(a.x>b.x&&a.stance&&b.knockdown==HardKnockdown);
 setup(s);a.y=b.y=15000;b.x=a.x-7000;s.preview_begin(0,AIR_BACK_THROW);ticks(s,5);CHECK(b.health==840&&b.knockdown==HardKnockdown);
 // Real air back throw input takes priority over the P+K FD chord.
 setup(s);a.y=b.y=15000;s.step(Left|P|K,0);CHECK(a.move==AIR_BACK_THROW&&!a.faultless);ticks(s,4);CHECK(b.health==840&&b.knockdown==HardKnockdown);
}
static void guard_and_reactions(){
 Simulation s;setup(s);auto& a=s.world.players[0];auto& b=s.world.players[1];
 b.x=75000;s.step(S,0);ticks(s,30,S);CHECK(a.move==HELD_GUARD&&a.age==4);s.step(S|Hs,0);CHECK(a.move==GUARD_ATTACK&&a.armor_left==1);
 setup(s);b.x=75000;s.moves[3][HELD_GUARD].v[Enabled]=0;s.step(S,0);ticks(s,30,S);CHECK(a.move==2);
 setup(s);b.x=75000;s.moves[3][GUARD_ATTACK].v[Enabled]=0;s.step(S,0);ticks(s,30,S);s.step(S|Hs,0);CHECK(a.move==HELD_GUARD);
 setup(s);s.preview_begin(0,HELD_GUARD);a.age=4;s.preview_begin(1,0);b.age=s.moves[4][0].v[Startup]-1;s.step(S,0);CHECK(a.move==HELD_GUARD&&a.health==1000&&!a.stun&&s.get(-1,21)==1);
 setup(s);s.moves[4][5].v[HitLevel]=1;s.preview_begin(0,HELD_GUARD);a.age=4;s.preview_begin(1,5);b.age=s.moves[4][5].v[Startup]-1;s.step(S,0);CHECK(a.health<1000&&a.move<0);
 setup(s);s.preview_begin(0,GUARD_ATTACK);s.preview_begin(1,0);b.age=s.moves[4][0].v[Startup]-1;s.step(0,0);CHECK(a.health<1000&&a.move==GUARD_ATTACK&&!a.stun&&a.armor_left==0&&s.get(-1,21)==1);
 setup(s);hit(s,8);CHECK(b.reaction==Crumpled&&b.crumple_time==28);
 setup(s);b.y=10000;b.move=0;b.age=0;hit(s,8);CHECK(b.knockdown==HardKnockdown);
 setup(s);s.moves[4][5].v[HitLevel]=1;a.move=22;a.age=8;b.move=5;b.age=s.moves[4][5].v[Startup]-1;s.step(0,0);CHECK(a.health==1000);
 // Low projectiles respect the sweep window, and captured pairs cannot be hit mid-sequence.
 for(int scenario=0;scenario<3;++scenario){
  setup(s);const int owner=scenario==2?0:1;auto& shot=s.moves[owner?4:3][0];shot.v[ProjectileKind]=2;shot.v[ProjectilePersist]=1;shot.v[ProjectileWidth]=16000;shot.v[ProjectileHeight]=18000;shot.v[HitLevel]=1;
  s.world.projectiles[0]={20,owner,owner?4:3,0,1,owner?a.x:b.x,6000,0,0,-1,1,0,1};
  if(scenario==0){a.move=22;a.age=8;}else{a.stance=1;hit(s,STANCE_THROW);}
  s.step(0,0);CHECK(a.health==1000);if(scenario>0)CHECK(b.reaction==Captured&&a.grab_time>0);
 }
 // A spent wall bounces once; depleted wall takes priority and splats.
 for(int empty=0;empty<2;++empty){setup(s);b.x=98000;b.y=5000;b.reaction=AirReel;b.stun=20;b.vx=900;b.knockback_left=5000;b.bounce_wall=800;s.world.wall_health[1]=empty?0:1000;s.step(0,0);if(empty)CHECK(b.reaction==WallSplat);else CHECK(b.vx==-800&&b.bounce_wall==0&&s.world.wall_health[1]==100);}
 setup(s);b.y=100;b.vy=-200;b.stun=10;b.reaction=AirReel;b.bounce_ground=1000;s.step(0,0);CHECK(b.y>0&&b.vy==1000&&b.bounce_ground==0);
}
static void multi_dive_and_snapshots(){
 Simulation s,copy;setup(s);auto& a=s.world.players[0];auto& b=s.world.players[1];
 a.y=b.y=16000;s.mobility[3].v[Gravity]=s.mobility[4].v[Gravity]=0;
 s.moves[3][19].v[AirPushback]=0;s.moves[3][19].v[AirLaunch]=0;s.preview_begin(0,19);
 ticks(s,55);CHECK(a.contact_count==2&&a.combo==2);
 setup(s);a.y=20000;a.vy=500;a.vx=400;s.preview_begin(0,21);int y=a.y;ticks(s,10);CHECK(a.y==y&&a.vy==0&&a.vx==0);
 for(int n=0;n<160&&a.y>0;++n){s.step(0,0);}CHECK(a.y==0&&a.move==21);ticks(s,20);CHECK(a.move<0);
 setup(s);a.stance=1;hit(s,STANCE_THROW);ticks(s,7);copy=s;for(int i=0;i<100;++i){s.step(0,0);copy.step(0,0);CHECK(s.checksum()==copy.checksum());}
 s.reset(3,4,0,0);CHECK(!a.stance&&!a.grab_time&&a.grab_owner==-1);
 for(int c=0;c<CHARACTER_COUNT;++c)for(int m=0;m<MOVE_COUNT;++m)CHECK(s.moves[c][m].v[Startup]>=startup_minimum(s.moves[c][m]));
}
int main(){inputs_and_stance();captures();guard_and_reactions();multi_dive_and_snapshots();std::printf("Tapper kit: %d checks, %d failures\n",checks,failures);return failures?1:0;}
