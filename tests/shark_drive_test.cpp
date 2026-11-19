#include "../core/fight.h"
#include <cstdio>
#include <initializer_list>
using namespace fight;
static int checks=0,failures=0;
#define CHECK(x) do{++checks;if(!(x)){++failures;std::fprintf(stderr,"Shark Drive %d: %s\n",__LINE__,#x);}}while(0)
static int magnitude(int x){return x<0?-x:x;}
static Simulation s;
static void ticks(int n,int b=0){while(n-->0)s.step(0,b);}
static void setup(int mirror=1){s.defaults();s.reset(4,0,0,0);s.preview_place(0,mirror>0?40000:60000,0,10000);s.preview_place(1,50000,0,10000);s.world.players[0].facing=mirror;s.world.players[1].facing=-mirror;}
static void start(int slot){s.preview_begin(0,slot);s.world.players[0].age=s.moves[4][slot].v[Startup]-1;}
static void mark(){CHECK(s.preview_status(1,2,14));}
static void tags(){
 setup();s.step(D,0);CHECK(s.world.players[0].move==13);setup();s.step(Right|D,0);CHECK(s.world.players[0].move==12);setup();s.step(Down|D,0);CHECK(s.world.players[0].move==22);
 for(int direction:{1,-1}){
  setup(direction);auto& b=s.world.players[1];start(13);s.step(0,0);CHECK(b.tether_source==14&&b.tether_time==180);CHECK(b.health==964);
  int time=b.tether_time;ticks(3);CHECK(b.tether_time==time);while(s.world.hitstop)s.step(0,0);
  ticks(1);CHECK(b.tether_time==179);b.tether_time=1;ticks(1);CHECK(!b.tether_source&&!b.tether_time);
  setup(direction);start(13);s.step(0,direction>0?Right:Left);CHECK(s.world.players[1].guarding);CHECK(!s.world.players[1].tether_source);
 }
 setup();mark();s.world.players[1].x=90000;ticks(1);CHECK(!s.world.players[1].tether_source);
 setup();mark();s.preview_begin(1,2);s.world.players[1].age=s.moves[0][2].v[Startup]-1;s.step(0,0);CHECK(s.world.players[0].stun>0);CHECK(!s.world.players[1].tether_source);
}
static void reels(){
 // Collision preview uses a display copy of the attacker; target lookup must
 // remain explicit rather than derive a player index from that copy's address.
 setup();mark();s.preview_begin(0,22);s.world.players[0].age=s.moves[4][22].v[Startup];
 CHECK(s.box_count(0,HitBox)==1);auto displayed=s.box(0,HitBox),target=s.box(1,PushBox);
 CHECK(displayed.left==target.left&&displayed.right==target.right&&displayed.top==target.top);

 for(int direction:{1,-1}){
  setup(direction);auto& a=s.world.players[0];auto& b=s.world.players[1];b.x=a.x+direction*20000;mark();start(22);s.step(0,0);
  CHECK(b.reaction==Reeled&&b.health==1000);CHECK(!b.tether_source);while(s.world.hitstop)s.step(0,0);ticks(10);CHECK(magnitude(b.x-a.x)==7400);CHECK(a.contact_count==1);
  setup(direction);mark();start(22);s.step(0,direction>0?Right:Left);CHECK(s.world.players[1].guarding);CHECK(s.world.players[1].reaction!=Reeled);CHECK(!s.world.players[1].tether_source);
 }
 setup();mark();start(22);s.step(0,Up);CHECK(!s.world.players[0].contact_count);CHECK(!s.world.players[1].tether_source);
 setup();mark();start(22);int x=s.world.players[1].x;s.step(0,Right|Faultless);CHECK(s.world.players[1].faultless);CHECK(s.world.players[1].x>=x);CHECK(!s.world.players[1].tether_source);
 setup();start(22);s.step(0,0);CHECK(!s.world.players[0].contact_count);CHECK(!s.world.players[1].stun);
 // A simultaneous strike interrupts the reel's sustained pull regardless of side.
 for(int mirror:{1,-1}){setup(mirror);mark();start(22);s.preview_begin(1,2);s.world.players[1].age=s.moves[0][2].v[Startup]-1;s.step(0,0);ticks(30);CHECK(s.world.players[0].stun||s.world.players[0].health<1000);CHECK(s.world.players[1].reaction!=Reeled);}
}
static void chase(){
 for(int direction:{1,-1}){
  setup(direction);auto& a=s.world.players[0];auto& b=s.world.players[1];b.x=a.x+direction*22000;mark();s.preview_begin(0,12);int x=a.x;ticks(7);CHECK(a.x==x);ticks(1);CHECK((a.x-x)*direction==1400);CHECK(!b.tether_source&&a.tether_chase);CHECK(s.box_count(0,HitBox)==0);ticks(9);CHECK((a.x-x)*direction==14000);CHECK(b.health==1000);
  setup(direction);mark();start(12);ticks(20);CHECK(magnitude(s.world.players[1].x-s.world.players[0].x)>=6000);
 }
 setup();start(12);int x=s.world.players[0].x;ticks(12);CHECK(s.world.players[0].x==x&&!s.world.players[0].tether_chase);
 setup();mark();s.preview_begin(0,12);s.world.players[1].x=30000;ticks(20);CHECK(!s.world.players[0].tether_chase);CHECK(s.world.players[0].x==40000);
 setup();mark();s.preview_begin(0,12);ticks(9);auto snapshot=s.world;ticks(40);unsigned hash=s.checksum();s.world=snapshot;ticks(40);CHECK(s.checksum()==hash);
 s.reset(4,0,0,0);CHECK(!s.world.players[1].tether_time&&!s.world.players[0].tether_chase);
 CHECK(!s.move_set(4,13,TetherDuration,0));CHECK(!s.move_set(4,13,TetherRange,0));CHECK(!s.move_set(4,13,Mechanic,6));
}
int main(){tags();reels();chase();std::printf("Shark Drive: %d checks, %d failures\n",checks,failures);return failures?1:0;}
