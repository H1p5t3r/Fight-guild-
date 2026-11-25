#include "legacy_fillet_data.h"
#include "../core/fight.h"
#include <cstdio>
#include <cstring>
using namespace fight;
static int checks=0,failures=0;
#define CHECK(x) do { ++checks; if(!(x)) { std::fprintf(stderr,"Collision FAIL %d: %s\n",__LINE__,#x); ++failures; } } while(0)
static bool overlap(Box a,Box b) {
    return a.left<b.right&&a.right>b.left&&a.bottom<b.top&&a.top>b.bottom;
}
static void spaced(const Simulation& s) {
    auto a=s.box(0,PushBox),b=s.box(1,PushBox);
    CHECK(!overlap(a,b));
    CHECK(a.left>=0&&a.right<=100000&&b.left>=0&&b.right<=100000);
}
static void flush(Simulation& s,bool mirror=false,bool corner=false) {
    int a=(s.box(0,PushBox).right-s.box(0,PushBox).left)/2;
    int b=(s.box(1,PushBox).right-s.box(1,PushBox).left)/2;
    s.world.players[1].x=corner?(mirror?b:100000-b):50000;
    s.world.players[0].x=s.world.players[1].x+(mirror?1:-1)*(a+b);
}
static void poses() {
    Simulation s; legacy_fillet::defaults(s);
    CHECK(Simulation::collision_hash()!=0);
    for(int c=0;c<6;++c) for(int phase=0;phase<(c>=4?8:3);++phase) for(int p=0;p<(phase==0?12:phase<=2?6:phase<=4?4:phase==5?1:8);++p) {
        int count=Simulation::pose_box_count(c,phase,p);
        CHECK(count>=3&&count<=4&&count<=MAX_HURTBOXES);
        auto outside=Simulation::pose_box(c,phase,p,MAX_HURTBOXES);
        CHECK(outside.left==0&&outside.bottom==0&&outside.right==0&&outside.top==0);
        for(int i=0;i<count;++i) {
            auto b=Simulation::pose_box(c,phase,p,i);
            CHECK(b.left<b.right&&b.bottom<b.top);
        }
    }
    // Locomotion follows travelled distance, not render time. A restored snapshot
    // and hitstop must preserve both the drawing and its fitted body geometry.
    for(int c=4;c<6;++c) {
        s.reset(c,c,0,0);
        auto& f=s.world.players[0];
        CHECK(s.pose(f).phase==(c==4?11:5));
        s.step(Right,0);
        CHECK(s.pose(f).phase==6);
        const auto saved=s.world;
        const auto walk=s.pose(f);
        s.world.hitstop=8;
        for(int i=0;i<8;++i) { s.step(Right,0); CHECK(s.pose(f).phase==6&&s.pose(f).index==walk.index); }
        s.world=saved;
        CHECK(s.pose(f).index==walk.index);
        f.running=1;
        CHECK(s.pose(f).phase==7);
        for(int mirror=0;mirror<2;++mirror) {
            f.facing=mirror?-1:1;
            int visited=0;
            for(int i=0;i<8;++i) {
                f.x=(i+1)*s.mobility[c].v[RunSpeed]*3;
                CHECK(s.pose(f).index>=0&&s.pose(f).index<8);
                visited|=1<<s.pose(f).index;
                CHECK(s.box_count(0,HurtBox)==(c==4?4:3));
            }
            CHECK(visited==255);
        }
        f.vx=0;
        CHECK(s.pose(f).phase==(c==4?11:5));
        CHECK(Simulation::pose_box_count(c,5,1)==0);
        CHECK(Simulation::pose_box_count(c,8,0)==0);
    }
    CHECK(Simulation::pose_box_count(0,6,0)==3); // Anvil now has a fitted walk cycle.
    for(int c=0;c<6;++c) for(int m=0;m<MOVE_COUNT;++m) {
        for(int field=0;field<FIELD_COUNT;++field) CHECK(s.move_set(c,m,field,s.moves[c][m].v[field]));
        CHECK(s.moves[c][m].v[Startup]>=startup_minimum(s.moves[c][m]));
        CHECK(s.moves[c][m].v[HitboxBack]<s.moves[c][m].v[Reach]);
        int value=s.moves[c][m].v[Startup];
        for(int invalid=0;invalid<startup_minimum(s.moves[c][m]);++invalid) CHECK(!s.move_set(c,m,Startup,invalid));
        CHECK(s.moves[c][m].v[Startup]==value);
    }
    // Both facings transform the same body rectangles around the exact sprite anchor.
    for(int c=0;c<6;++c) {
        s.reset(c,c,0,0);
        for(int pose=0;pose<12;++pose) {
            // Explicit local geometry is shared by renderer review and runtime transforms.
            if(pose>0&&pose<6) { s.world.players[0].move=pose==5?13:pose-1; s.world.players[0].age=s.moves[c][s.world.players[0].move].v[Startup]; }
            else { s.world.players[0].move=-1; s.world.players[0].raw=pose==11?Down:0; s.world.players[0].stun=pose==9?1:0; s.world.players[0].y=pose==8?5000:0; }
            auto& f=s.world.players[0];
            for(int i=0;i<s.box_count(0,HurtBox);++i) {
                f.facing=1; auto right=s.box(0,HurtBox,i);
                f.facing=-1; auto left=s.box(0,HurtBox,i);
                CHECK(right.left-f.x==f.x-left.right&&right.right-f.x==f.x-left.left);
                CHECK(right.bottom==left.bottom&&right.top==left.top);
            }
        }
    }
}
static void pushes() {
    for(int c=0;c<6;++c) for(int d=0;d<6;++d) for(int mirror=0;mirror<2;++mirror) {
        Simulation s; legacy_fillet::defaults(s); s.reset(c,d,0,0); flush(s,mirror);
        int toward=mirror?Left:Right,other_toward=mirror?Right:Left;
        for(int i=0;i<80;++i) { s.step(toward|(i%12==0?Dash:0),other_toward); spaced(s); }
        // Largest legal advancing move cannot tunnel, even when it would end past the other center.
        s.moves[c][13].v[Advance]=10000;
        s.step(D,0); spaced(s);
        CHECK((s.world.players[0].x<s.world.players[1].x)==!mirror);
        s.reset(c,d,0,0); flush(s,mirror,true);
        int x=s.world.players[0].x;
        for(int i=0;i<40;++i) { s.step(toward,0); spaced(s); }
        CHECK(s.world.players[0].x==x&&s.world.players[0].momentum==0);
        // Crouch and landing overlap resolve without shoving a fighter through the wall.
        s.world.players[0].y=1; s.world.players[0].vy=-100;
        s.world.players[0].x=s.world.players[1].x;
        s.step(Down,Down); spaced(s);
        s.reset(c,d,0,0); flush(s,mirror);
        // A real jump over an approaching opponent can pass above the body.
        s.step(Up|toward,other_toward);
        for(int i=0;i<40;++i) { s.step(toward,other_toward); spaced(s); }
        CHECK(s.world.players[0].y==0);
        CHECK((s.world.players[0].x>s.world.players[1].x)==!mirror);
    }
}
static void contact_and_weapons() {
    Simulation s; legacy_fillet::defaults(s);
    for(int c=0;c<6;++c) for(int slot=0;slot<5;++slot) {
        int m=slot==4?13:slot; if(slot==2)m=CLOSE_SLASH;
        s.reset(c,(c+1)%6,0,0); flush(s);
        for(int tick=1;tick<=s.moves[c][m].v[Startup];++tick) {
            s.step(tick==1?P<<slot:0,0);
            if(tick<s.moves[c][m].v[Startup]) { CHECK(s.world.players[1].health==1000); CHECK(s.box_count(0,HitBox)==0); const int phase=s.get(0,29); CHECK((c==0||c==1||c==2)?(phase==11||phase==12||phase==14||phase==3):c==4?(phase==5||phase==14||phase==3):phase==(s.moves[c][m].v[ArtPose]?3:1)); }
        }
        const auto& track=s.move_hit[c][m];
        const int boxes=track.count&&track.keys[0].frame==1&&track.keys[0].count>=0?track.keys[0].count:1;
        CHECK(s.box_count(0,HitBox)==(s.world.players[0].grab_time||s.moves[c][m].v[Mechanic]==5?0:boxes)&&((c==0||c==1||c==4)?s.get(0,29)==14:s.get(0,29)==(s.moves[c][m].v[ArtPose]?4:0)&&s.get(0,30)==(s.moves[c][m].v[ArtPose]?s.moves[c][m].v[ArtPose]-1:slot+1)));
        for(int n=0;n<s.moves[c][m].v[GrabFrames];++n)s.step(0,0);
        CHECK(s.world.players[1].health==1000-s.moves[c][m].v[Damage]);
    }
    // Contact with Anvil's extended f.S shield alone cannot hurt him. A tiny probe
    // through the head can. Mirror the entire setup to catch anchor/flip mistakes.
    for(int mirror=0;mirror<2;++mirror) for(int body=0;body<2;++body) {
        legacy_fillet::defaults(s); s.reset(1,0,0,0);
        auto& attacker=s.world.players[0]; auto& defender=s.world.players[1];
        attacker.x=mirror?10000:90000; attacker.facing=mirror?1:-1;
        defender.x=50000; defender.facing=mirror?-1:1; defender.move=2; defender.age=s.moves[0][2].v[Startup]-1; defender.hit_done=1;
        Pose pose=s.pose(defender,1);
        CHECK(pose.phase==14);
        const Box head=Simulation::pose_box(0,pose.phase,pose.index,2);
        // Bull f.S shield plate: source (650,450), root (245,659), scale 150/300.
        int local_x=body?(head.left+head.right)/2:20250, y=body?(head.bottom+head.top)/2:10450;
        int target=defender.x+defender.facing*local_x;
        auto& probe=s.moves[1][0];
        int center=(target-attacker.x)*attacker.facing;
        probe.v[HitboxBack]=center-50; probe.v[Reach]=center+50;
        probe.v[Bottom]=y-50; probe.v[Height]=100; probe.v[Pushback]=0;
        attacker.move=0; attacker.age=probe.v[Startup]-1;
        State before=s.world;
        s.step(0,0); auto hash=s.checksum();
        CHECK((defender.health<1000)==bool(body));
        s.world=before; s.step(0,0); CHECK(hash==s.checksum());
    }
}
static void edited_attack_hurtboxes() {
    Simulation s; legacy_fillet::defaults(s);s.reset(5,0,0,0);
    Box high[4]={{-1000,30000,1000,33000},{-1200,33000,1200,36000},{-800,36000,800,38000},{1000,34000,3000,35000}};
    CHECK(s.hurt_set(5,0,0,3,high));CHECK(s.hurt_set(5,0,1,4,high));CHECK(s.hurt_set(5,0,2,3,high));
    auto& f=s.world.players[0];f.move=0;
    for(int phase=0;phase<3;++phase){
        f.age=phase==0?1:phase==1?s.moves[5][0].v[Startup]:s.moves[5][0].v[Startup]+s.moves[5][0].v[Active];
        CHECK(s.box_count(0,HurtBox)==(phase==1?4:3));
        for(int facing=-1;facing<=1;facing+=2){f.facing=facing;auto b=s.box(0,HurtBox,0);CHECK(b.bottom==30000);CHECK(b.left==f.x-1000&&b.right==f.x+1000);}
    }
    f.move=4;f.age=s.moves[5][4].v[Startup];CHECK(s.box(0,HurtBox,0).bottom<30000); // same sprite, different move
    f.move=0;f.stun=1;CHECK(s.box(0,HurtBox,0).bottom<30000);f.stun=0;
    CHECK(!s.hurt_set(5,0,0,5,high));CHECK(!s.hurt_set(5,0,0,2,high));
    high[0].right=high[0].left;CHECK(!s.hurt_set(5,0,0,3,high));CHECK(s.hurt_get(5,0,0,3)==1000);high[0].right=1000;
    high[0].bottom=-2147483647;CHECK(!s.hurt_set(5,0,0,3,high));high[0].bottom=30000;
    CHECK(s.hurt_set(5,0,0,0,nullptr));CHECK(s.hurt_get(5,0,0,0)==0);CHECK(s.hurt_get(5,0,0,2)==0);
    // Collision uses the defender's current action tick, including the exact
    // startup→active boundary. A replay with custom data gives the same result.
    for(int mirror=0;mirror<2;++mirror)for(int enters_active=0;enters_active<2;++enters_active){
        legacy_fillet::defaults(s);s.reset(0,5,0,0);auto& a=s.world.players[0];auto& d=s.world.players[1];
        a.x=mirror?70000:30000;a.facing=mirror?-1:1;d.x=50000;d.facing=-a.facing;
        CHECK(s.hurt_set(5,0,0,3,high));
        Box low[4]={high[0],high[1],high[2],high[3]};low[0]={-1000,0,1000,6000};
        CHECK(s.hurt_set(5,0,1,3,low));
        auto& attack=s.moves[0][0];attack.v[HitboxBack]=19000;attack.v[Reach]=21000;attack.v[Bottom]=4000;attack.v[Height]=500;attack.v[Pushback]=0;
        a.move=0;a.age=attack.v[Startup]-1;d.move=0;d.age=s.moves[5][0].v[Startup]-(enters_active?1:2);d.hit_done=1;
        State before=s.world;s.step(0,0);CHECK((d.health<1000)==bool(enters_active));auto hash=s.checksum();
        s.world=before;s.step(0,0);CHECK(s.checksum()==hash);
    }
    legacy_fillet::defaults(s);CHECK(s.hurt_get(5,0,1,0)==0);
}
static void phased_hurtbox_toggles() {
    const Box body[4]={{-1000,0,1000,5000},{-1200,5000,1200,11000},{-800,11000,800,14000},{1200,7000,3000,9000}};
    for(int c=0;c<CHARACTER_COUNT;++c) {
        Simulation s;legacy_fillet::defaults(s);s.reset(c,0,0,0);auto& f=s.world.players[0];f.move=8;
        for(int p=0;p<3;++p) CHECK(s.hurt_set(c,8,p,4,body));
        for(int phase=0;phase<3;++phase) {
            f.age=phase==0?1:phase==1?s.moves[c][8].v[Startup]:s.moves[c][8].v[Startup]+s.moves[c][8].v[Active];
            CHECK(s.box_count(0,HurtBox)==(phase==2?4:c==4&&phase==0?2:1));CHECK(s.box(0,HurtBox,0).top==5000);
            CHECK(s.box_count(0,PushBox)==1);
        }
        s.move_set(c,8,HurtWindowStart,0); // Isolate phase-mask editing from Tapper’s finer move-frame window.
        f.age=1;CHECK(s.move_set(c,8,HurtMaskWindup,5));CHECK(s.box_count(0,HurtBox)==2);
        CHECK(s.box(0,HurtBox,1).bottom==11000); // Legs + head retain their role order.
        CHECK(s.move_set(c,8,HurtMaskWindup,0));CHECK(s.box_count(0,HurtBox)==0);CHECK(s.box_count(0,PushBox)==1);
        CHECK(s.move_set(c,8,HurtMaskWindup,15));CHECK(s.box_count(0,HurtBox)==4);
        CHECK(s.hurt_get(c,8,0,6)==5000); // Disabled coordinates are never erased.
        CHECK(!s.move_set(c,8,HurtMaskWindup,16));CHECK(!s.move_set(c,8,HurtMaskActive,-1));
        for(int phase=0;phase<3;++phase)for(int low=0;low<2;++low)for(int projectile=0;projectile<2;++projectile) {
            legacy_fillet::defaults(s);s.reset(0,c,0,0);auto& a=s.world.players[0];auto& d=s.world.players[1];
            a.x=30000;d.x=50000;a.facing=1;d.facing=-1;d.move=8;
            for(int p=0;p<3;++p)CHECK(s.hurt_set(c,8,p,4,body));
            auto& defend=s.moves[c][8];defend.v[Advance]=0;defend.v[TravelSpeed]=0;
            d.age=phase==0?defend.v[Startup]-2:phase==1?defend.v[Startup]:defend.v[Startup]+defend.v[Active]-1;
            auto& attack=s.moves[0][0];attack.v[HitboxBack]=19000;attack.v[Reach]=21000;
            attack.v[Bottom]=low?2000:7000;attack.v[Height]=500;attack.v[Pushback]=0;
            if(projectile){
                attack.v[ProjectileKind]=1;attack.v[ProjectileHeight]=500;attack.v[ProjectileWidth]=2000;
                auto& q=s.world.projectiles[0];q.life=20;q.owner=0;q.character=0;q.move=0;q.serial=1;
                q.x=49000;q.y=low?2250:7250;q.vx=1000;q.facing=1;q.hits=1;q.durability=1;
            }else{a.move=0;a.age=attack.v[Startup]-1;}
            const State before=s.world;s.step(0,0);CHECK((d.health<1000)==bool(low||phase==2));
            auto hash=s.checksum();s.world=before;s.step(0,0);CHECK(s.checksum()==hash);
        }
    }
}
int main() {
    poses(); pushes(); contact_and_weapons();edited_attack_hurtboxes();phased_hurtbox_toggles();
    std::printf("Collision / sprite geometry: %d checks, %d failures\n",checks,failures);
    return failures?1:0;
}
