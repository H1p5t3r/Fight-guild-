#include "legacy_fillet_data.h"
#include "../core/fight.h"
#include <cstdio>
#include <initializer_list>
using namespace fight;
static int checks=0, failures=0;
#define CHECK(x) do {++checks;if(!(x)){++failures;std::fprintf(stderr,"Hit timeline FAIL %d: %s\n",__LINE__,#x);}}while(0)
static Simulation fresh(bool reverse=false) {
    Simulation s;legacy_fillet::defaults(s);s.reset(5,4,0,0);
    s.preview_place(0,reverse?50000:40000,0,0);s.preview_place(1,reverse?40000:50000,0,0);
    auto& m=s.moves[5][0];m.v[Active]=7;m.v[Recovery]=5;m.v[Hitstop]=0;
    m.v[Pushback]=m.v[AirPushback]=0;m.v[Hitstun]=90;m.v[Blockstun]=90;
    m.v[StarterProration]=100;m.v[ComboScaling]=0;
    return s;
}
static HitKey key(int frame,int group,int count=2) {
    HitKey k{frame,group,count,10,90,90,0,{}};
    k.boxes[0]={0,0,25000,20000};k.boxes[1]=k.boxes[0];return k;
}
static void ticks(Simulation& s,int count,int guard=0){while(count-->0)s.step(0,guard);}
int main(){
    for(bool reverse:{false,true}) for(int multi:{0,1}) {
        auto s=fresh(reverse);CHECK(s.hit_clear(5,0,multi));
        auto a=key(1,1),b=key(3,2),c=key(5,1);b.damage=15;
        CHECK(s.hit_add(5,0,a)&&s.hit_add(5,0,b)&&s.hit_add(5,0,c));
        s.preview_begin(0,0);ticks(s,5);CHECK(s.world.players[1].health==990);
        CHECK(s.box_count(0,HitBox)==2);auto box=s.box(0,HitBox,0);
        CHECK(box.left==(reverse?25000:40000)&&box.right==(reverse?50000:65000));
        auto snapshot=s.world;ticks(s,12);auto hash=s.checksum();
        CHECK(s.world.players[1].health==(multi?975:990));
        s.world=snapshot;ticks(s,12);CHECK(s.checksum()==hash);
    }
    auto s=fresh();s.hit_clear(5,0,1);auto a=key(1,1),b=key(3,2);a.count=0;b.damage=33;
    CHECK(s.hit_add(5,0,a)&&s.hit_add(5,0,b));s.preview_begin(0,0);ticks(s,6);
    CHECK(s.world.players[1].health==1000&&s.box_count(0,HitBox)==0);s.step(0,0);
    CHECK(s.world.players[1].health==967&&s.world.players[0].last_damage==33);
    // Hitstop holds the key frame; the same group cannot repeatedly hit while frozen.
    s=fresh();s.hit_clear(5,0,1);a=key(1,1);a.hitstop=5;b=key(3,2);b.hitstop=2;
    CHECK(s.hit_add(5,0,a)&&s.hit_add(5,0,b));s.preview_begin(0,0);ticks(s,5);
    CHECK(s.world.hitstop==5);ticks(s,5);CHECK(s.world.players[1].health==990);ticks(s,2);
    CHECK(s.world.players[1].health==980&&s.world.hitstop==2);
    // Multiple blocked hits consume a group just like unblocked hits.
    s=fresh();s.hit_clear(5,0,1);a=key(1,1);b=key(3,2);s.hit_add(5,0,a);s.hit_add(5,0,b);
    s.moves[5][0].v[BlockPushback]=0;s.moves[5][0].v[ChipDamage]=3;
    s.preview_begin(0,0);ticks(s,12,Right);CHECK(s.world.players[1].health==994);
    CHECK(s.world.players[0].hit_groups==3u);
    // Appending malformed keys is atomic and cleared tracks are canonical.
    int count=s.hit_get(5,0,1);a=key(2,3);CHECK(!s.hit_add(5,0,a));
    a=key(4,33);CHECK(!s.hit_add(5,0,a));a=key(4,3);a.boxes[0].top=50001;CHECK(!s.hit_add(5,0,a));
    a=key(4,3);a.hitstop=31;CHECK(!s.hit_add(5,0,a));CHECK(s.hit_get(5,0,1)==count);
    CHECK(s.hit_clear(5,0,0));for(int i=0;i<HIT_TRACK_FIELDS;++i)CHECK(s.hit_get(5,0,i)==0);
    CHECK(!s.hit_clear(5,0,2));
    // A base-geometry key still inherits the authored hit shape and defaults.
    s=fresh();s.moves[5][0].v[Reach]=25000;a=key(1,1,-1);
    a.damage=a.hitstun=a.blockstun=a.hitstop=-1;s.hit_add(5,0,a);s.preview_begin(0,0);ticks(s,5);
    CHECK(s.world.players[1].health==1000-s.moves[5][0].v[Damage]);
    std::printf("Active hitbox timeline: %d checks, %d failures\n",checks,failures);return failures?1:0;
}
