#include "../core/fight.h"
#include <cstdio>
#include <initializer_list>
using namespace fight;
static int checks=0,failures=0;
#define CHECK(x) do {++checks;if(!(x)){std::fprintf(stderr,"Smoke FAIL %d: %s\n",__LINE__,#x);++failures;}} while(0)
static void setup(Simulation& s,int facing=1){s.defaults();s.reset(2,3,0,0);s.preview_place(0,facing==1?30000:70000,0,0);s.preview_place(1,facing==1?80000:20000,0,0);}
static void charge_inputs(){
 Simulation s,copy;
 for(int facing:{1,-1})for(int dust:{0,1}){
  setup(s,facing);auto& a=s.world.players[0];
  const int base=dust?13:11,charged=dust?CHARGED_D:CHARGED_HS,button=dust?D:Hs;
  const int input=button|(dust?0:(facing==1?Right:Left)),full=dust?28:36;
  for(int tick=1;tick<full;++tick){s.step(input,0);CHECK(a.move==base);CHECK(s.box_count(0,HitBox)==0);CHECK(s.pose(a).phase==3);}
  const int momentum=a.momentum;copy=s;
  s.step(input,0);copy.step(input,0);CHECK(s.checksum()==copy.checksum());
  CHECK(a.move==charged);CHECK(s.box_count(0,HitBox)>0);CHECK(a.momentum==momentum);
  for(int n=0;n<60;++n){s.step(0,0);copy.step(0,0);CHECK(s.checksum()==copy.checksum());}CHECK(a.move<0);
  // A tap always gets the source uncharged startup, never a hidden charged slot.
  setup(s,facing);s.step(input,0);const int startup=s.moves[2][base].v[Startup];
  for(int tick=2;tick<startup;++tick){s.step(0,0);CHECK(s.box_count(0,HitBox)==0);}
  s.step(0,0);CHECK(a.move==base);CHECK(s.box_count(0,HitBox)>0);
  // Disabling the follow-up falls back to an ordinary strike at full hold.
  setup(s,facing);s.moves[2][charged].v[Enabled]=0;
  for(int tick=1;tick<=full;++tick)s.step(input,0);
  CHECK(a.move==base&&s.box_count(0,HitBox)>0);
 }
 setup(s);s.step(Right|Hs,0);for(int i=1;i<27;++i)s.step(Right|Hs,0);
 s.step(0,0);for(int i=0;i<12;++i)s.step(Right|Hs,0);
 CHECK(s.world.players[0].move!=CHARGED_HS); // Repressing during recovery cannot charge again.
}
static void normals_and_multihits(){
 Simulation s;setup(s);auto& a=s.world.players[0];auto& b=s.world.players[1];
 b.x=a.x+7000;s.step(S,0);CHECK(a.move==CLOSE_SLASH);
 setup(s);s.step(S,0);CHECK(a.move==2);
 for(int slot:{2,3}){
  setup(s);b.x=a.x+12000;s.moves[2][slot].v[Pushback]=0;s.preview_begin(0,slot);
  const int expected=slot==2?5:3;
  for(int n=0;n<180&&a.contact_count<expected;++n)s.step(0,0);
  CHECK(a.contact_count==expected);CHECK(a.combo==expected);
  if(slot==3)CHECK(b.stun==89);
  for(int n=0;n<15;++n)s.step(0,0);
  CHECK(a.contact_count==expected);
 }
 // 2Hs changes red rectangles without re-hitting an already struck target.
 setup(s);s.preview_begin(0,7);a.age=s.moves[2][7].v[Startup];
 CHECK(s.box_count(0,HitBox)==2);a.age+=3;CHECK(s.box_count(0,HitBox)==3);
 setup(s);s.step(Right|P,0);
 for(int n=1;n<17;++n){CHECK(s.box_count(0,HurtBox)==1);s.step(0,0);}
 s.step(0,0);CHECK(s.box_count(0,HurtBox)>=3);
 CHECK(s.moves[2][6].v[HitLevel]==0&&s.moves[2][11].v[HitLevel]==0);
 CHECK(s.moves[2][CHARGED_HS].v[GuardBreak]==1&&s.moves[2][CHARGED_HS].v[Blockstun]==39);
 CHECK(!s.moves[2][9].v[Enabled]&&!s.moves[2][10].v[Enabled]&&!s.moves[2][12].v[Enabled]);
 CHECK(s.moves[2][22].v[Knockdown]==HardKnockdown);
}
static void air_projectile(){
 Simulation s,copy;
 for(int facing:{1,-1}){
  setup(s,facing);auto& a=s.world.players[0];a.y=20000;a.vx=facing*600;a.vy=300;
  s.step(D,0);CHECK(a.move==21);
  for(int tick=2;tick<=15;++tick){s.step(0,0);CHECK(s.box_count(0,ProjectileBox)==0);CHECK(a.y==20000);}
  copy=s;s.step(0,0);copy.step(0,0);CHECK(s.checksum()==copy.checksum());
  CHECK(s.box_count(0,ProjectileBox)==1);CHECK(s.box_count(0,HitBox)==0);CHECK(a.vx*facing<0);
  for(int tick=17;tick<=35;++tick){s.step(0,0);copy.step(0,0);CHECK(s.checksum()==copy.checksum());}
  CHECK(a.move<0);
 }
}
int main(){charge_inputs();normals_and_multihits();air_projectile();std::printf("Smoke normals / charge / projectile: %d checks, %d failures\n",checks,failures);return failures?1:0;}
