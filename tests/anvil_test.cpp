#include "../core/fight.h"
#include <cstdio>
#include <initializer_list>
using namespace fight;
static Simulation s;
static int checks=0,failures=0,owner=0;
#define CHECK(x) do{++checks;if(!(x)){++failures;std::fprintf(stderr,"Anvil %d: %s\n",__LINE__,#x);}}while(0)
static Fighter& a(){return s.world.players[owner];}
static Fighter& b(){return s.world.players[1-owner];}
static void advance(int input=0,int other=0){if(owner)s.step(other,input);else s.step(input,other);}
static void ticks(int n,int input=0,int other=0){while(n-->0)advance(input,other);}
static void setup(int facing=1,int player=0){
    owner=player;s.defaults();s.reset(player?2:0,player?0:2,0,0);
    a().x=facing>0?30000:70000;b().x=a().x+facing*22000;a().facing=facing;b().facing=-facing;
}
static int direction(int d){
    int f=a().facing>0?Right:Left,r=a().facing>0?Left:Right;
    return d==6?f:d==3?(f|Down):d==2?Down:d==1?(r|Down):d==4?r:0;
}
static void hcb(int button,int held=0){for(int d:{6,3,2,1})advance(direction(d)|held);advance(direction(4)|button|held);}
static void stance(){CHECK(s.preview_begin(owner,13));ticks(6,D);CHECK(a().move==13&&a().armor_left==2);}
static void body_fixture(){
    Box boxes[3]={{-3500,0,3500,6000},{-4000,6000,4000,12500},{-1800,12500,1800,15500}};
    for(int slot:{13,14,15,28})for(int phase=0;phase<3;++phase)CHECK(s.hurt_set(0,slot,phase,3,boxes));
}
static void strike(int bottom=8500,int level=0,int height=1500){
    s.world.hitstop=0;b().move=-1;b().stun=0;b().reaction=Free;b().y=0;b().x=a().x+a().facing*7500;
    auto& m=s.moves[b().character][0];m.v[HitboxBack]=0;m.v[Reach]=18000;m.v[Bottom]=bottom;m.v[Height]=height;
    m.v[HitLevel]=level;m.v[Damage]=10;m.v[Hitstop]=0;m.v[Launch]=0;m.v[Knockdown]=0;
    s.hit_clear(b().character,0,0);
    CHECK(s.preview_begin(1-owner,0));b().age=m.v[Startup]-1;advance(D);
}
static void inputs(){
    for(int p:{0,1})for(int face:{-1,1})for(int slot:{14,15,16}){
        setup(face,p);a().momentum=10000;hcb(slot==14?P:slot==15?K:Hs);CHECK(a().move==slot);
    }
    setup();for(int d:{2,1})advance(direction(d));advance(direction(4)|P);CHECK(a().move!=14);
    setup();advance(direction(6));advance(direction(2));advance(direction(4)|P);CHECK(a().move==14); // Cardinal leniency.
    for(int face:{-1,1})for(int release:{0,2,4}){
        setup(face);ticks(30,direction(4));ticks(release,direction(6));advance(direction(6)|Hs);CHECK(a().move==28);
    }
    setup();ticks(29,direction(4));advance(direction(6)|Hs);CHECK(a().move!=28);
    setup();ticks(30,direction(4));ticks(7);advance(direction(6)|Hs);CHECK(a().move!=28);
}
static void armor(){
    for(int p:{0,1})for(int face:{-1,1}){
        setup(face,p);body_fixture();stance();const int x=a().x,meter=a().momentum;
        ticks(8,D|direction(6));CHECK((a().x-x)*face==8*220);CHECK(a().momentum==meter&&!a().contact_count);
        strike();CHECK(a().move==13&&a().armor_left==1&&a().health==990&&!a().stun);
        strike(13000);CHECK(a().move==13&&a().armor_left==0&&a().health==980&&!a().stun);
        strike();CHECK(a().move<0&&a().stun>0&&a().health==970);
        setup(face,p);body_fixture();stance();strike(1000,0);CHECK(a().move<0&&a().stun>0); // A mid that actually hits the legs.
        setup(face,p);body_fixture();stance();strike(1000,0,16000);CHECK(a().move<0&&a().stun>0); // A full-height mid still reaches the vulnerable legs.
        setup(face,p);body_fixture();stance();strike(8500,1);CHECK(a().move<0&&a().stun>0); // Low guard level always defeats upper armor.
        setup(face,p);stance();advance();CHECK(a().age>=6&&a().armor_left==0);ticks(15);CHECK(a().move<0);
    }
    setup();stance();b().x=a().x+7500;CHECK(s.preview_begin(1-owner,24));b().age=1;
    advance(D);CHECK(s.world.pair.kind==LegacyCapture); // Shield armor never stops a throw.
    for(int remaining:{0,1,2}){
        setup();stance();a().armor_left=remaining;hcb(P,D);
        CHECK(a().move==14&&a().carried_armor==(remaining>0));
        setup();stance();a().armor_left=remaining;CHECK(s.preview_begin(owner,28));
        CHECK(a().armor_left==1&&a().carried_armor==(remaining>0));
    }
    setup();body_fixture();stance();CHECK(s.preview_begin(owner,28));strike();
    CHECK(a().move==28&&a().carried_armor==0&&a().armor_left==1);
    strike(1000,1);CHECK(a().move==28&&a().armor_left==0);strike();CHECK(a().move<0);
    setup();body_fixture();stance();CHECK(s.preview_begin(owner,14));strike();
    CHECK(a().move==14&&a().carried_armor==0);strike();CHECK(a().move<0);
    setup();body_fixture();stance();CHECK(s.preview_begin(owner,14));a().age=8;strike();CHECK(a().move<0); // No carried armor in recovery.
}
static void grabs(){
    for(int p:{0,1})for(int face:{-1,1})for(int slot:{14,15}){
        setup(face,p);b().x=a().x+face*8500;CHECK(s.preview_begin(owner,slot));
        ticks(s.moves[0][slot].v[Startup]);CHECK(s.world.pair.kind==GrapplerCapture&&b().health==1000);
        int ticks_left=300;while(s.world.pair.kind&&ticks_left-->0)advance();
        CHECK(ticks_left>0&&b().health==667&&a().last_damage==333);
        CHECK(b().reaction==Downed&&b().knockdown==HardKnockdown);
        const Pose finish=s.pose(a());const Fighter copied=a();const Pose collision_finish=s.pose(copied);
        CHECK(finish.phase==14&&collision_finish.phase==finish.phase&&collision_finish.index==finish.index);
        CHECK(s.box_count(owner,HurtBox)==Simulation::pose_box_count(0,finish.phase,finish.index));
        CHECK(a().facing==(slot==14?face:-face));ticks(120);CHECK(b().health==667);
    }
    for(int invalid:{0,1,2,3,4}){
        setup();b().x=a().x+8000;
        if(invalid==0){b().y=10000;b().vy=1000;}
        if(invalid==1)b().prejump_time=20;
        if(invalid==2){b().stun=20;b().guarding=1;}
        if(invalid==3)b().throw_grace=20;
        if(invalid==4)b().stun=20;
        CHECK(s.preview_begin(owner,14));ticks(8);CHECK(!s.world.pair.kind&&b().health==1000);
    }
}
static void super(){
    setup();a().momentum=4999;CHECK(!s.preview_begin(owner,16)&&a().momentum==4999);
    for(int p:{0,1})for(int face:{-1,1}){
        setup(face,p);a().momentum=10000;b().y=16000;b().vy=300;b().vx=-200;
        CHECK(s.preview_begin(owner,16));CHECK(a().momentum==5000&&s.world.super_time==54&&s.world.super_actor==owner);
        const int x=b().x,y=b().y,vy=b().vy,time=s.world.remaining;
        ticks(54);CHECK(b().x==x&&b().y==y&&b().vy==vy&&s.world.remaining==time&&a().age==0&&!s.world.super_time);
        ticks(5);CHECK(s.world.pair.kind==AntiAirCapture);
        ticks(150);CHECK(b().health==667&&a().momentum==5000);
    }
    setup();a().momentum=5000;b().x=a().x+8000;CHECK(s.preview_begin(owner,16));ticks(110);
    CHECK(!s.world.pair.kind&&b().health==1000&&a().momentum==0); // Grounded opponent is safe.
    setup();a().momentum=5000;b().y=16000;b().stun=30;b().reaction=AirReel;
    a().combo=3;b().combo_received=3;b().combo_proration=70;b().combo_scale=80;
    CHECK(s.preview_begin(owner,16));ticks(59);CHECK(s.world.pair.kind==AntiAirCapture&&s.world.pair.combo);
    ticks(150);CHECK(b().health>667&&b().health<1000&&a().last_damage<333);
    setup();a().momentum=5000;b().y=16000;CHECK(s.preview_begin(owner,16));ticks(12);
    const State saved=s.world;ticks(200);unsigned expected=s.checksum();s.world=saved;ticks(200);CHECK(s.checksum()==expected);
}
static void dive_and_routes(){
    setup();a().y=30000;a().vx=1000;a().vy=500;b().x=a().x+10000;
    CHECK(s.preview_begin(owner,21));CHECK(a().vx==0&&a().vy==0);int x=a().x;
    ticks(8);CHECK(a().y==30000&&a().x==x);advance();CHECK(a().y==29100&&a().vx==0);
    int limit=200;while(a().y>0&&limit-->0)advance();
    CHECK(limit>0&&a().move==21&&a().age>=98&&a().vx==0&&a().contact_count>=2&&a().contact_count<=5);
    ticks(30);CHECK(a().move<0&&a().armor_left==0);
    setup();for(int from:{0,1,2,3,4,5,6,7,8,11,32}){
        for(int to:{0,1,2,3,4,5,6,7,8,11,32})CHECK(!s.can_cancel(0,from,to,1));
        for(int to:{14,15,16,28})CHECK(s.can_cancel(0,from,to,1)&&!s.can_cancel(0,from,to,0));
    }
    for(int to:{14,15,16,28})CHECK(s.can_cancel(0,13,to,0));
    for(int to:{0,1,2,13,24})CHECK(!s.can_cancel(0,13,to,0));
    setup();CHECK(s.preview_begin(owner,28));ticks(23);advance(P);CHECK(a().move==30&&a().armor_left==0&&a().carried_armor==0);
}
int main(){inputs();armor();grabs();super();dive_and_routes();std::printf("Anvil grappler: %d checks, %d failures\n",checks,failures);return failures?1:0;}
