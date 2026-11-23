#include "../core/fight.h"
#include <cstdio>
#include <initializer_list>
using namespace fight;
static Simulation s;
static int checks=0,failures=0,owner=0;
#define CHECK(x) do{++checks;if(!(x)){++failures;std::fprintf(stderr,"Hammer Drive %d: %s\n",__LINE__,#x);}}while(0)
static Fighter& a(){return s.world.players[owner];}
static Fighter& b(){return s.world.players[1-owner];}
static void advance(int input=0,int other=0){if(owner)s.step(other,input);else s.step(input,other);}
static void ticks(int n,int input=0,int other=0){while(n-->0)advance(input,other);}
static void setup(int facing=1,int player=0){owner=player;s.defaults();s.reset(player?0:1,player?1:0,0,0);a().x=facing>0?30000:70000;b().x=a().x+facing*40000;a().facing=facing;b().facing=-facing;}
static void start(int slot){CHECK(s.preview_begin(owner,slot));}
static void burst(){start(13);ticks(4);CHECK(a().age==4);}
static void travel(){
 for(int p:{0,1})for(int facing:{-1,1}){
  setup(facing,p);int x=a().x,distance=s.get(owner,113),meter=a().momentum;start(13);
  ticks(4);CHECK(a().x==x&&!s.box_count(owner,HitBox));ticks(12);
  CHECK(a().x==x+facing*distance);CHECK(!a().contact_count&&b().health==1000&&!s.world.hitstop);
  CHECK(a().momentum==meter&&a().drive_used);CHECK(a().vx*facing>0);
  ticks(6);CHECK(a().move<0&&a().vx==0);
  // Real point-blank distance: the same dash stops against the pushboxes.
  setup(facing,p);b().x=a().x+facing*10000;const int bx=b().x;start(13);ticks(16);
  auto pa=s.box(owner,PushBox),pb=s.box(1-owner,PushBox);
  CHECK(facing>0?pa.right==pb.left:pa.left==pb.right);CHECK(b().x==bx);
 }
 setup();int base=s.get(owner,113);s.moves[1][FAR_SLASH].v[Reach]+=2000;CHECK(s.get(owner,113)==base+2000);
 s.moves[1][FAR_SLASH].v[BlockPushback]+=900;CHECK(s.get(owner,113)==base+2900);
 s.moves[1][13].v[DriveDistance]=9000;CHECK(s.get(owner,113)==9000);burst();ticks(1);CHECK(a().vx==750);
 // A large timeline box participates; an empty disabled move does not.
 setup();int before=s.get(owner,113);HitKey k{1,1,1,-1,-1,-1,-1,{{1200,0,30000,5000}}};s.hit_add(1,0,k);
 CHECK(s.get(owner,113)>before);s.moves[1][0].v[Enabled]=0;CHECK(s.get(owner,113)==before);
}
static void cancels(){
 for(int slot:{0,1,2,3,4,5,6,7,8,11,32}){
  setup();CHECK(s.can_cancel(1,13,slot,0));burst();int speed=a().drive_speed,bonus=s.moves[1][13].v[DrivePlus];
  s.moves[1][slot].v[InertiaPercent]=0;int x=a().x;start(slot);
  CHECK(a().vx==speed&&a().drive_bonus==bonus);advance();CHECK(a().x==x+speed);
  CHECK(a().vx==speed-s.mobility[1].v[AttackFriction]);
 }
 for(int slot:{14,15,16}){
  setup();CHECK(s.can_cancel(1,slot,13,0));start(slot);ticks(s.moves[1][slot].v[Startup]);advance(D);
  CHECK(a().move==13&&a().drive_used); // Whiff cancel, real input.
  setup();start(slot);advance(D);CHECK(a().move==slot&&!a().drive_used); // Startup cannot be erased.
 }
 setup();burst();advance(P);CHECK(a().move==0&&a().drive_bonus==4);
 setup();burst();advance(Down|S);CHECK(a().move==6&&a().drive_bonus==4);
 setup();burst();advance(Right|P);CHECK(a().move==8&&a().drive_bonus==4);
 CHECK(!s.can_cancel(1,13,14,0)&&!s.can_cancel(1,13,24,0)&&!s.can_cancel(1,13,17,0));
 setup();burst();ticks(12);advance(P);CHECK(a().move==13); // Recovery is not a burst cancel.
}
static void advantage(){
 for(int slot:{0,1,2,3,4,5,6,7,8,11,32}){
  int normal=0,enhanced=0;
  for(int boost:{0,4}){
   setup();b().x=a().x+6500;start(slot);a().age=s.moves[1][slot].v[Startup]-1;a().drive_bonus=boost;
   advance(0,Right|(s.moves[1][slot].v[HitLevel]==1?Down:0));CHECK(a().event==Blocked);
   if(boost)enhanced=b().stun;else normal=b().stun;
  }CHECK(enhanced-normal==4);
 }
 // Per-hit payload overrides also receive the bonus exactly once.
 setup();b().x=a().x+6500;HitKey k{1,1,-1,-1,-1,10,-1,{}};s.hit_add(1,0,k);start(0);a().age=4;a().drive_bonus=4;advance(0,Right);CHECK(b().stun==14);
}
static void resource(){
 setup();burst();CHECK(!s.preview_begin(owner,13));start(0);a().drive_bonus=4;advance(D);CHECK(a().move==0&&a().drive_used);
 a().move=-1;a().vx=0;b().stun=20;b().guarding=1;ticks(19);CHECK(a().drive_used&&a().drive_neutral==0);
 ticks(4);CHECK(a().drive_used);start(0);advance();CHECK(a().drive_neutral==0);
 a().move=-1;a().vx=0;ticks(11);CHECK(a().drive_used);advance();CHECK(!a().drive_used);advance(D);CHECK(a().move==13);
 // Being hit does not immediately grant another use; hitstop also cannot recharge.
 setup();burst();a().move=-1;a().stun=20;s.world.hitstop=10;ticks(10);CHECK(a().drive_used&&!a().drive_neutral);
 ticks(5);CHECK(a().drive_used&&!a().drive_bonus);
 auto snap=s.world;ticks(100);auto hash=s.checksum();s.world=snap;ticks(100);CHECK(hash==s.checksum());
 setup();start(13);s.world.projectiles[0].life=40;s.world.projectiles[0].move=14;s.world.projectiles[0].owner=0;s.world.projectiles[0].character=1;
 a().move=-1;ticks(12);CHECK(a().drive_used);
 s.reset(1,0,0,0);CHECK(!a().drive_used&&!a().drive_bonus&&!a().drive_neutral);
}
static void utility(){
 setup();auto& m=s.moves[1][13];m.v[Damage]=500;m.v[ProjectileKind]=1;m.v[ProjectileSpawnFrame]=5;m.v[Category]=Throw;m.v[ThrowRange]=20000;
 m.v[Advance]=5000;m.v[StartupTravel]=2000;m.v[TravelSpeed]=3000;
 b().x=a().x+10000;const int origin=a().x;start(13);ticks(4);CHECK(a().x==origin);ticks(12);CHECK(!s.box_count(owner,HitBox)&&!s.box_count(owner,ProjectileBox));CHECK(b().health==1000&&!a().contact_count);
 CHECK(!s.move_set(1,13,DrivePlus,31)&&!s.move_set(1,13,DriveNeutralFrames,0));
 setup();a().y=1;CHECK(!s.preview_begin(owner,13));
}
int main(){travel();cancels();advantage();resource();utility();std::printf("Hammer Drive: %d checks, %d failures\n",checks,failures);return failures?1:0;}
