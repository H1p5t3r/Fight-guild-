#include "../core/fight.h"
#include <cstdio>
#include <initializer_list>
using namespace fight;
static Simulation s;
static int checks=0,failures=0,owner=0;
#define CHECK(x) do{++checks;if(!(x)){++failures;std::fprintf(stderr,"Supers %d (character %d / slot %d): %s\n",__LINE__,a().character,a().last_move,#x);}}while(0)
static Fighter& a(){return s.world.players[owner];}
static Fighter& b(){return s.world.players[1-owner];}
static void advance(int input=0,int other=0){if(owner)s.step(other,input);else s.step(input,other);}
static void ticks(int n,int input=0,int other=0){while(n-->0)advance(input,other);}
static void setup(int c,int second=0,int p=0,int facing=1){
 owner=p;s.defaults();s.reset(p?2:c,p?c:2,0,0);
 a().x=facing>0?35000:65000;b().x=a().x+facing*10000;a().facing=facing;b().facing=-facing;
 a().momentum=10000;if(c==3&&second)a().stance=1;
}
static int dir(int d){int f=a().facing==1?Right:Left,r=a().facing==1?Left:Right;return d==6?f:d==3?(Down|f):d==2?Down:d==1?(Down|r):d==4?r:d==8?Up:0;}
static void input(int c,int second){
 if(c==0){for(int d:{6,3,2,1})advance(dir(d));advance(dir(4)|(second?S:Hs));}
 else {for(int d:second?std::initializer_list<int>{2,1,4,2,1}:std::initializer_list<int>{2,3,6,2,3})advance(dir(d));advance(dir(second?4:6)|(second?Hs:S));}
}
static void until_pair(){int limit=100;while(!s.world.pair.kind&&limit-->0)advance();CHECK(s.world.pair.kind);}
static void finish(){int limit=400;while(s.world.pair.kind&&limit-->0)advance();CHECK(limit>0);}
static void inputs_and_cost(){
 for(int c=0;c<6;++c)for(int second:{0,1})for(int p:{0,1})for(int face:{-1,1}){
  int slot=SUPER_SLOTS[c][second];setup(c,second,p,face);a().momentum=SUPER_COST-1;
  CHECK(!s.preview_begin(owner,slot)&&a().momentum==SUPER_COST-1);
  setup(c,second,p,face);input(c,second);CHECK(a().move==slot);CHECK(a().momentum==10000-SUPER_COST);
  CHECK(s.world.super_actor==owner&&s.world.super_time==SUPER_FREEZE_TICKS);
  int time=s.world.remaining,x=b().x,age=a().age; ticks(SUPER_FREEZE_TICKS);CHECK(s.world.remaining==time&&b().x==x&&a().age==age);

 }
 for(int c=1;c<6;++c)for(int second:{0,1}){
  setup(c,second);for(int d:{2,3})advance(dir(d));advance(dir(6)|S);CHECK(a().move!=SUPER_SLOTS[c][0]);
 }
 setup(3);input(3,1);CHECK(a().move!=SUPER_SLOTS[3][1]);
 setup(3,1);input(3,0);CHECK(a().move!=SUPER_SLOTS[3][0]);
 for(int c=0;c<6;++c)for(int second:{0,1}){
  setup(c,second);int slot=SUPER_SLOTS[c][second];for(int to=0;to<MOVE_COUNT;++to)for(int contact:{0,1,2})CHECK(!s.can_cancel(c,slot,to,contact));
 }
}
static void cinematics(){
 for(int c=0;c<6;++c)for(int second:{0,1})for(int p:{0,1})for(int face:{-1,1}){
  if((c==1||c==2)&&second)continue;
  int slot=SUPER_SLOTS[c][second];setup(c,second,p,face);
  if(c==0&&!second){b().y=16000;b().vy=300;}
  CHECK(s.preview_begin(owner,slot));ticks(54);until_pair();
  CHECK(s.world.pair.kind==(c==0&&!second?AntiAirCapture:SuperCapture));
  CHECK(b().health==1000&&a().momentum==3333);int remaining=s.world.remaining;
  State saved=s.world;ticks(12,D|P|S,Dash|P|K);CHECK(s.world.pair.kind&&a().reaction==Captured&&b().reaction==Captured);
  CHECK(a().move<0&&b().move<0&&a().health==1000&&b().health==1000&&s.world.remaining==remaining);
  unsigned hash=s.checksum();s.world=saved;ticks(12,D|P|S,Dash|P|K);CHECK(s.checksum()==hash);
  finish();CHECK(b().health<1000&&b().knockdown==HardKnockdown&&a().pair_recovery>0);
  CHECK(a().momentum==3333&&a().contact_count==1&&a().last_damage>0);
  CHECK(s.world.remaining==remaining);int health=b().health;ticks(25);CHECK(b().health==health&&a().move<0);
  if(c==3)CHECK(a().stance==1);
  if(c==4&&second)CHECK((b().x-a().x)*face<0&&a().facing==-face);
  if(c==5&&!second)CHECK(b().bleed_time>0&&b().bleed_source==14);
 }
 // Scaled combo finishes retain the starter's proration and cannot pay twice.
 setup(1);b().stun=100;b().reaction=Free;b().combo_received=4;b().combo_proration=60;b().combo_scale=60;a().combo=4;
 CHECK(s.preview_begin(owner,12));ticks(54);until_pair();CHECK(s.world.pair.combo);finish();CHECK(a().last_damage<360&&a().last_damage>=108&&a().combo==5);
 // Cashout pays at most 150 stored grey once and consumes the bleed.
 setup(5,1);b().bleed_source=14;b().bleed_time=500;b().grey_life=250;b().bleed_clock=0;
 CHECK(s.preview_begin(owner,31));ticks(54);until_pair();CHECK(s.world.pair.grey==150&&!b().bleed_time&&!b().grey_life);finish();CHECK(a().last_damage==450&&b().health==550);
 // The last second and KO wait for the visual finish.
 setup(1);b().health=1;CHECK(s.preview_begin(owner,12));ticks(54);until_pair();s.world.remaining=1;ticks(50);CHECK(s.world.winner<0&&s.world.remaining==1);finish();CHECK(s.world.winner==owner&&b().health==0);
}
static void defense(){
 // Blocking and whiffing never create a capture or refund the spent meter.
 for(int c=0;c<6;++c)for(int second:{0,1}){
  if(((c==1||c==2)&&second)||(c==0&&!second))continue;
  setup(c,second);int slot=SUPER_SLOTS[c][second];s.mobility[2].v[BackWalkSpeed]=0;
  CHECK(s.preview_begin(owner,slot));ticks(180,0,Right);CHECK(!s.world.pair.kind&&a().move<0&&a().momentum==3333&&b().health>=970);
  setup(c,second);b().x=95000;a().x=10000;CHECK(s.preview_begin(owner,slot));ticks(180);CHECK(!s.world.pair.kind&&b().health==1000&&a().momentum==3333);
 }
 // Simultaneous confirmed strike supers clash without player-index bias.
 setup(1);b().character=4;b().momentum=10000;CHECK(s.preview_begin(0,12));CHECK(s.preview_begin(1,12));s.world.super_time=0;
 a().age=s.moves[1][12].v[Startup]-1;b().age=s.moves[4][12].v[Startup]-1;advance();CHECK(!s.world.pair.kind&&a().health==1000&&b().health==1000&&s.world.hitstop>0);
 // A cinematic confirmation beats a simultaneous ordinary strike; no stray
 // projectile can interrupt, damage, or remain queued during the pair.
 for(int p:{0,1}){
  setup(1,0,p);CHECK(s.preview_begin(owner,12));s.world.super_time=0;a().age=s.moves[1][12].v[Startup]-1;
  auto& m=s.moves[2][0];m.v[Reach]=20000;m.v[Height]=20000;m.v[Bottom]=0;b().move=0;b().age=m.v[Startup]-1;
  auto& shot=s.moves[2][14];shot.v[ProjectileKind]=1;shot.v[ProjectilePersist]=1;
  shot.v[ProjectileWidth]=shot.v[ProjectileHeight]=12000;
  s.world.projectiles[0]={100,1-owner,2,14,77,a().x,8000,0,0,-1,1,0,1};
  advance();CHECK(s.world.pair.kind==SuperCapture&&s.world.pair.owner==owner&&a().health==1000);
  CHECK(!s.world.projectiles[0].life);finish();CHECK(a().health==1000);
 }
}
static void utility(){
 for(int c:{1,2})for(int face:{-1,1}){
  setup(c,1,0,face);b().x=a().x+face*45000;
  CHECK(s.preview_begin(owner,31));ticks(54);int limit=100;while(a().move>=0&&limit-->0)advance();
  CHECK(limit>0&&!s.world.pair.kind&&a().reaction==Free);CHECK(s.preview_begin(owner,0));
  bool alive=false;for(auto& q:s.world.projectiles)alive|=q.life>0;CHECK(alive);
 }
 for(int face:{-1,1})for(int d:{4,5,6}){
  setup(2,1,0,face);b().x=face>0?95000:5000;CHECK(s.preview_begin(owner,31));ticks(54);ticks(24,dir(d));
  const auto& q=s.world.projectiles[0];CHECK(q.life>0&&q.x-a().x==face*(d==4?15000:d==6?35000:25000));
  a().stun=10;advance();CHECK(!s.world.projectiles[0].life&&!s.world.pair.kind);
 }
 setup(2,1);s.mobility[2].v[BackWalkSpeed]=0;b().x=a().x+25000;CHECK(s.preview_begin(owner,31));ticks(54);ticks(220,0,Right);
 CHECK(a().contact_count==3&&!s.world.pair.kind&&a().move<0&&b().health==1000-3*s.moves[2][31].v[ChipDamage]);
 setup(1,1);b().x=a().x+10000;CHECK(s.preview_begin(owner,31));ticks(54);ticks(22);CHECK(s.world.projectiles[0].life>0&&b().health==1000);
 const auto& wave=s.moves[1][31];
 ticks(wave.v[Startup]+wave.v[Active]+wave.v[Recovery]-22);
 CHECK(a().move<0&&b().health==1000);ticks(20);CHECK(a().contact_count==1&&b().health<1000&&!s.world.pair.kind);
}
int main(){inputs_and_cost();cinematics();defense();utility();std::printf("Supers: %d checks, %d failures\n",checks,failures);return failures?1:0;}
