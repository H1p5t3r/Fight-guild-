#include "../core/fight.h"
#include <cstdio>
#include <initializer_list>
using namespace fight;
static int checks=0,failures=0,owner=0;
#define CHECK(x) do{++checks;if(!(x)){++failures;std::fprintf(stderr,"Shark Drive %d: %s\n",__LINE__,#x);}}while(0)
static int magnitude(int x){return x<0?-x:x;}
static Simulation s;
static Fighter& a(){return s.world.players[owner];}
static Fighter& b(){return s.world.players[1-owner];}
static void step(int input=0){if(owner==0)s.step(0,input);else s.step(input,0);}
static void ticks(int n,int input=0){while(n-->0)step(input);}
static void setup(int mirror=1,int player=0){owner=player;s.defaults();s.reset(player?0:4,player?4:0,0,0);s.preview_place(owner,mirror>0?40000:60000,0,10000);s.preview_place(1-owner,a().x+mirror*20000,0,10000);a().facing=mirror;b().facing=-mirror;}
static void start(int slot=22){s.preview_begin(owner,slot);a().age=s.moves[4][slot].v[Startup]-1;}
static void mark(){CHECK(s.preview_status(1-owner,2,14));}
static void no_strike(){CHECK(b().health==1000&&!a().contact_count&&!a().contact&&!a().combo&&!b().combo_received&&!s.world.hitstop);}
static void tags(){
 setup();s.step(D,0);CHECK(a().move==13);setup();s.step(Right|D,0);CHECK(a().move!=12);setup();s.step(Down|D,0);CHECK(a().move==22);
 CHECK(is_super(s.moves[4][12])&&!s.moves[4][12].v[Mechanic]);CHECK(!s.move_set(4,13,Mechanic,6));
 for(int direction:{1,-1}){
  setup(direction);b().x=a().x+direction*10000;start(13);step();CHECK(b().tether_source==14&&b().tether_time==180);CHECK(b().health==964);
  int time=b().tether_time;ticks(3);CHECK(b().tether_time==time);while(s.world.hitstop)step();
  ticks(1);CHECK(b().tether_time==179);b().tether_time=1;ticks(1);CHECK(!b().tether_source&&!b().tether_time);
  setup(direction);b().x=a().x+direction*10000;start(13);step(direction>0?Right:Left);CHECK(b().guarding);CHECK(!b().tether_source);
 }
 setup();mark();b().x=90000;ticks(1);CHECK(!b().tether_source);
 CHECK(!s.move_set(4,13,TetherDuration,0));CHECK(!s.move_set(4,13,TetherRange,0));
}
static void free_pull(){
 for(int player:{0,1})for(int direction:{1,-1})for(int guard:{0,1,2}){
  setup(direction,player);mark();start();const int input=guard?(direction>0?Right:Left)|(guard==2?Faultless:0):0;
  const int x=b().x;step(input);CHECK(b().line_pull_time==9&&!b().line_pull_hold);CHECK(!b().tether_source);
  CHECK((x-b().x)*direction>0);CHECK(!b().stun&&b().reaction==Free);CHECK(s.box_count(owner,HitBox)==0);no_strike();
  if(guard==2)CHECK(b().faultless);
  ticks(9,input);CHECK(!b().line_pull_time&&!b().line_pull_hold);CHECK(magnitude(b().x-a().x)==7400);CHECK(!b().stun&&b().reaction==Free);no_strike();
 }
 // The first active tick cannot interrupt a newly pressed normal.
 setup();mark();start();step(P);CHECK(b().move==0&&b().age==1&&!b().stun&&b().line_pull_time==9);no_strike();
 step();CHECK(b().move==0&&b().age==2&&!b().stun);
 // Jump and air dash remain available; no forced hit reaction or velocity reset.
 setup();mark();start();step(Up);CHECK(b().prejump_time>0&&!b().stun&&b().line_pull_time==9);
 ticks(4);CHECK(b().y>0&&b().vy>0&&b().reaction==Free&&!b().line_pull_hold);
 setup();b().y=16000;b().vy=500;mark();start();step();CHECK(b().y==16500&&b().vy>0&&!b().line_pull_hold);no_strike();
 s.mobility[0].v[AirDashEnabled]=1;s.mobility[0].v[AirDashPauseFrames]=2;step(Dash);CHECK(b().dash>0&&b().dash_pause==1&&!b().stun);
 // Backdash cannot evade the line, but still starts and keeps its own motion.
 setup();mark();start();step(Right|Dash);CHECK(b().dash>0&&!b().stun&&b().line_pull_time==9);
 setup();start();int x=b().x;ticks(12);CHECK(b().x==x&&!b().line_pull_time);no_strike();
 setup();mark();b().tether_time=1;start();step();CHECK(!b().line_pull_time);no_strike();
 setup();mark();b().reaction=Downed;b().recovery_time=30;start();step();CHECK(!b().line_pull_time&&b().reaction==Downed);no_strike();
}
static void held_stun(){
 for(int player:{0,1})for(int guard:{0,1})for(int stun:{1,12}){
  setup(1,player);mark();b().stun=stun;b().guarding=guard;b().block_reaction=guard?1:0;b().throw_grace=0;start();
  for(int tick=0;tick<10;++tick){step(P);CHECK(b().stun==stun);CHECK(b().move<0);CHECK(b().guarding==guard);CHECK(!b().throw_grace);CHECK(b().line_pull_time==9-tick);}
  CHECK(!b().line_pull_hold);no_strike();step();CHECK(b().stun==stun-1);
 }
 // Guard-break flags and ordinary blockstun throw protection survive the pull.
 for(int broken:{0,1}){
  setup();mark();b().stun=12;b().guarding=1;b().guard_break=broken;start();step();
  CHECK(b().guard_break==broken);CHECK(s.get(1,21)==!broken);CHECK(b().line_pull_hold);
 }
 // Air hitstun keeps its existing reaction, knockdown and vertical trajectory.
 setup();mark();b().y=20000;b().vy=400;b().reaction=AirReel;b().stun=14;b().knockdown=SoftKnockdown;start();step();
 int y=b().y,vy=b().vy;ticks(9);CHECK(b().stun==14&&b().y==y&&b().vy==vy&&b().reaction==AirReel);CHECK(b().knockdown==SoftKnockdown);step();CHECK(b().stun==13&&b().y==y+vy);
 // Shared hitstop pauses both clocks; ending the pull early adds no leftover stun.
 setup();mark();b().stun=12;start();step();s.world.hitstop=3;ticks(3);CHECK(b().line_pull_time==9&&b().stun==12);
 a().stun=15;ticks(1);CHECK(!b().line_pull_time&&!b().line_pull_hold&&b().stun==11);
}
static void interruption_and_payload(){
 // Either player's strike interrupts the pull on its first active tick.
 for(int player:{0,1})for(int direction:{1,-1}){
  setup(direction,player);b().x=a().x+direction*10000;mark();start();s.preview_begin(1-owner,2);b().age=s.moves[0][2].v[Startup]-1;step();
  CHECK(a().health<1000);CHECK(!b().line_pull_time&&!b().tether_source);CHECK(b().reaction==Free);
 }
 // Retained strike fields never turn the utility into damage, a projectile or a throw.
 for(int category:{Drive,Throw}){
  setup();mark();auto& m=s.moves[4][22];m.v[Category]=category;m.v[Damage]=500;m.v[Hitstun]=80;m.v[Hitstop]=20;m.v[Blockstun]=70;
  m.v[ProjectileKind]=1;m.v[ProjectileSpawnFrame]=1;m.v[ThrowRange]=20000;start();step();
  CHECK(b().line_pull_time==9&&!b().stun&&!s.world.pair.kind);CHECK(s.box_count(owner,ProjectileBox)==0);no_strike();
 }
 // An independent later hit uses its normal hitstun when the pull began on a free target.
 setup();mark();start();step();CHECK(!b().line_pull_hold);b().stun=7;step();CHECK(b().stun==6&&!b().line_pull_hold);
}
static void rollback(){
 for(int guard:{0,1}){
  setup();mark();b().stun=guard?9:0;b().guarding=guard;start();step();ticks(3);auto snapshot=s.world;
  ticks(45);unsigned hash=s.checksum();s.world=snapshot;ticks(45);CHECK(s.checksum()==hash);
 }
 s.reset(4,0,0,0);CHECK(!s.world.players[1].line_pull_time&&!s.world.players[1].line_pull_hold);
}
int main(){tags();free_pull();held_stun();interruption_and_payload();rollback();std::printf("Shark Drive: %d checks, %d failures\n",checks,failures);return failures?1:0;}
