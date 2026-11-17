#include "../core/fight.h"
#include <cstdio>
using namespace fight;
static int checks=0,failures=0;
#define CHECK(x) do { ++checks; if(!(x)){std::fprintf(stderr,"Mechanics FAIL %d: %s\n",__LINE__,#x);++failures;} } while(0)
static void ticks(Simulation& s,int n,int a=0,int b=0){while(n-->0)s.step(a,b);}
static void thaw(Simulation& s){while(s.world.hitstop)s.step(0,0);}
static void setup(Simulation& s,int c=5){s.defaults();s.reset(c,c==5?4:5,0,0);s.preview_place(0,40000,0,10000);s.preview_place(1,48000,0,10000);}
static void contact(Simulation& s,int p=0,int move=13,int guard=0){
 auto& f=s.world.players[p];f.stun=f.reaction=f.guarding=f.landing_time=f.throw_grace=0;f.move=-1;
 s.preview_begin(p,move);f.age=s.moves[f.character][move].v[Startup]-1;
 s.step(p?guard:0,p?0:guard);
}
static void bleed(){
 Simulation s;setup(s);auto& a=s.world.players[0];auto& b=s.world.players[1];auto& m=s.moves[5][13];
 contact(s);CHECK(b.bleed_source==14);CHECK(b.grey_life==20);CHECK(b.bleed_time==420);CHECK(b.health==1000-m.v[Damage]);
 int hp=b.health;int timer=b.bleed_time;ticks(s,3);CHECK(b.bleed_time==timer); // shared hitstop pauses status clocks
 thaw(s);ticks(s,30);CHECK(b.grey_life==22);CHECK(b.health==hp);CHECK(b.bleed_time==390);
 b.stun=b.reaction=b.knockdown=b.y=b.vy=b.vx=b.knockback_left=0;b.x=48000;a.x=40000;
 s.moves[5][0].v[Damage]=50;contact(s,0,0,Right);CHECK(b.guarding);CHECK(b.grey_life==32);CHECK(b.bleed_time==389);
 thaw(s);b.stun=b.guarding=b.reaction=b.throw_grace=0;b.x=48000;a.x=40000;
 b.bleed_time=100;contact(s,0,0);CHECK(b.bleed_time==420);
 thaw(s);b.bleed_time=1;ticks(s,1);CHECK(!b.bleed_source&&!b.grey_life);
 // Combo scaling affects the initial marker, not later periodic ticks.
 setup(s);b.stun=20;b.combo_proration=50;b.combo_scale=60;a.combo=2;contact(s);CHECK(a.damage_scale==30);CHECK(b.grey_life==6);
 // Grey life never deducts HP and never reaches the last point of health.
 setup(s);m.v[Damage]=0;b.health=3;m.v[BleedInitial]=1000;m.v[BleedTickDamage]=1000;contact(s);CHECK(b.health==3&&b.grey_life==2);
 thaw(s);ticks(s,31);CHECK(b.health==3&&b.grey_life==2);
 // Either direct strikes or projectiles use apply_contact; ordinary hit clears all owner statuses.
 setup(s);contact(s);thaw(s);a.x=40000;b.x=48000;contact(s,1,2);CHECK(!b.bleed_source&&!b.grey_life);
}
static void cashout(){
 Simulation s;setup(s);auto& a=s.world.players[0];auto& b=s.world.players[1];
 // Start through the actual D input, with a status that a prior hit would leave.
 b.bleed_source=14;b.bleed_time=420;b.grey_life=100;s.step(D,0);CHECK(a.variant==2);CHECK(a.y>0);
 int start=a.x;for(int i=0;i<70&&!a.contact_count;++i)s.step(0,0);
 CHECK(a.contact_count==1);CHECK(a.last_damage>=160);CHECK(b.health<=840);CHECK(!b.bleed_source&&!b.grey_life);CHECK(a.x>start);CHECK(b.knockdown==SoftKnockdown);
 // Command grab beats guard, but respects jump, blockstun and throw grace.
 for(int immunity=0;immunity<4;++immunity){
  setup(s);b.bleed_source=14;b.bleed_time=420;b.grey_life=100;s.preview_begin(0,13);a.y=a.vy=0;a.age=s.moves[5][13].v[VariantStartup]-1;
  if(immunity==0){b.raw=Right;}
  if(immunity==1){b.y=10000;}
  if(immunity==2){b.stun=12;b.guarding=1;}
  if(immunity==3){b.throw_grace=4;}
  s.step(0,Right);CHECK((a.contact_count>0)==(immunity==0));
 }
 // Whiff preserves status; cashout bonus may kill even though its marker cannot.
 setup(s);b.x=85000;b.bleed_source=14;b.bleed_time=420;b.grey_life=100;s.step(D,0);ticks(s,75);CHECK(!a.contact_count&&b.grey_life>=100&&b.bleed_source);
 setup(s);b.health=100;b.bleed_source=14;b.bleed_time=420;b.grey_life=99;s.step(D,0);ticks(s,60);CHECK(b.health==0&&s.world.winner==0);
}
static void tether(){
 Simulation s;setup(s,4);auto& a=s.world.players[0];auto& b=s.world.players[1];
 contact(s);CHECK(b.tether_source==14&&!b.tether_used);thaw(s);ticks(s,100);CHECK(b.tether_source);
 a.x=40000;b.x=70000;int hp=b.health;s.step(D,0);CHECK(a.variant==1);
 for(int i=0;i<30&&!b.tether_used;++i)s.step(0,0);
 CHECK(b.tether_used);CHECK(b.vx<0);CHECK(b.health==hp);CHECK(b.tether_source);int x=b.x;ticks(s,4);CHECK(b.x<x);
 // The next contact consumes a used tether on block too.
 thaw(s);a.x=40000;b.x=48000;b.stun=b.reaction=b.y=b.vy=b.vx=b.knockback_left=0;contact(s,0,0,Right);CHECK(b.guarding);CHECK(!b.tether_source);
 // Initial block never attaches. 2D still has its authored hard knockdown.
 setup(s,4);contact(s,0,13,Right);CHECK(!b.tether_source);
 setup(s,4);contact(s,0,22);CHECK(b.tether_source==23);CHECK(b.knockdown==HardKnockdown);
 // Hitting the owner clears an unused tether as well.
 thaw(s);a.x=40000;b.x=48000;b.y=b.vy=0;contact(s,1,2);CHECK(!b.tether_source);
 // Mirror direction aims at the current owner position, not original facing.
 setup(s,4);a.x=70000;b.x=40000;a.facing=-1;b.facing=1;b.tether_source=14;s.step(D,0);for(int i=0;i<30&&!b.tether_used;++i)s.step(0,0);CHECK(b.vx>0);
}
static void edge_cases(){
 Simulation s;setup(s);auto& a=s.world.players[0];auto& b=s.world.players[1];
 // FD prevents chip, but blocked attacks still accumulate refundable grey life.
 b.bleed_source=14;b.bleed_time=420;b.grey_life=20;s.moves[5][0].v[Damage]=50;
 contact(s,0,0,Right|Faultless);CHECK(b.health==1000&&b.grey_life==30);CHECK(b.bleed_time==419);
 // A real simultaneous trade clears both characters' newly applied statuses.
 for(int first=0;first<2;++first){
  setup(s,first?4:5);a.move=b.move=13;
  a.age=s.moves[a.character][13].v[Startup]-1;b.age=s.moves[b.character][13].v[Startup]-1;
  s.step(0,0);CHECK(a.health<1000&&b.health<1000);CHECK(!a.bleed_source&&!b.bleed_source&&!a.tether_source&&!b.tether_source);
 }
 // Reusing a spent pull cannot drag again; it is still the conditional move.
 setup(s,4);b.tether_source=14;b.tether_used=1;s.step(D,0);ticks(s,30);CHECK(a.variant==1&&b.tether_used&&b.stun==0);
 // Projectiles apply the same status, even without an accompanying melee hit.
 setup(s);auto& m=s.moves[5][13];m.v[ProjectileKind]=1;m.v[ProjectileMelee]=0;m.v[ProjectileSpeedX]=1000;
 s.step(D,0);for(int i=0;i<80&&!b.bleed_source;++i)s.step(0,0);CHECK(b.bleed_source==14&&b.grey_life==20);
 // A grounded victim also receives the upward component of an airborne pull.
 setup(s,4);s.moves[4][13].v[Air]=1;a.y=10000;b.tether_source=14;
 s.preview_begin(0,13);a.age=s.moves[4][13].v[VariantStartup]-1;s.step(0,0);CHECK(b.vy>0&&b.y>0&&b.reaction==AirReel);
}
static void snapshots(){
 Simulation a,b;setup(a);a.world.players[1].bleed_source=14;a.world.players[1].bleed_time=420;a.world.players[1].grey_life=100;a.step(D,0);ticks(a,8);
 b=a;for(int i=0;i<200;++i){a.step(0,0);b.step(0,0);CHECK(a.checksum()==b.checksum());}
 a.reset(5,4,0,0);CHECK(!a.world.players[1].grey_life&&!a.world.players[1].bleed_source&&!a.world.players[0].variant);
 CHECK(!a.move_set(5,13,VariantStartup,4));CHECK(!a.move_set(5,13,BleedTickFrames,0));CHECK(!a.move_set(5,13,Mechanic,3));
}
int main(){bleed();cashout();tether();edge_cases();snapshots();std::printf("Drive mechanics: %d checks, %d failures\n",checks,failures);return failures?1:0;}
