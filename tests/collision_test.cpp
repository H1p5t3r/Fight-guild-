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
    Simulation s; s.defaults();
    CHECK(Simulation::collision_hash()!=0);
    for(int c=0;c<6;++c) for(int phase=0;phase<(c>=4?5:3);++phase) for(int p=0;p<(phase==0?12:phase<=2?6:4);++p) {
        int count=Simulation::pose_box_count(c,phase,p);
        CHECK(count>=3&&count<=4&&count<=MAX_HURTBOXES);
        auto outside=Simulation::pose_box(c,phase,p,MAX_HURTBOXES);
        CHECK(outside.left==0&&outside.bottom==0&&outside.right==0&&outside.top==0);
        for(int i=0;i<count;++i) {
            auto b=Simulation::pose_box(c,phase,p,i);
            CHECK(b.left<b.right&&b.bottom<b.top);
        }
    }
    for(int c=0;c<6;++c) for(int m=0;m<MOVE_COUNT;++m) {
        for(int field=0;field<FIELD_COUNT;++field) CHECK(s.move_set(c,m,field,s.moves[c][m].v[field]));
        CHECK(s.moves[c][m].v[Startup]>=5);
        CHECK(s.moves[c][m].v[HitboxBack]<s.moves[c][m].v[Reach]);
        int value=s.moves[c][m].v[Startup];
        for(int invalid=0;invalid<5;++invalid) CHECK(!s.move_set(c,m,Startup,invalid));
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
        Simulation s; s.defaults(); s.reset(c,d,0,0); flush(s,mirror);
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
    Simulation s; s.defaults();
    for(int c=0;c<6;++c) for(int slot=0;slot<5;++slot) {
        int m=slot==4?13:slot;
        s.reset(c,(c+1)%6,0,0); flush(s);
        for(int tick=1;tick<=s.moves[c][m].v[Startup];++tick) {
            s.step(P<<slot,0);
            if(tick<s.moves[c][m].v[Startup]) { CHECK(s.world.players[1].health==1000); CHECK(s.box_count(0,HitBox)==0); CHECK(s.get(0,29)==1); }
        }
        CHECK(s.box_count(0,HitBox)==1&&s.get(0,29)==0&&s.get(0,30)==slot+1);
        CHECK(s.world.players[1].health==1000-s.moves[c][m].v[Damage]);
    }
    // Contact with Anvil's extended P shield alone cannot hurt him. A tiny probe
    // through the head can. Mirror the entire setup to catch anchor/flip mistakes.
    for(int mirror=0;mirror<2;++mirror) for(int body=0;body<2;++body) {
        s.defaults(); s.reset(1,0,0,0);
        auto& attacker=s.world.players[0]; auto& defender=s.world.players[1];
        attacker.x=mirror?30000:70000; attacker.facing=mirror?1:-1;
        defender.x=50000; defender.facing=mirror?-1:1; defender.move=0; defender.age=6; defender.hit_done=1;
        Pose pose=s.pose(defender,1);
        CHECK(pose.phase==0&&pose.index==1);
        // Authored Anvil P: head center ~+6px /125px; shield outer edge ~+65px/65px.
        int local_x=body?560:6500, y=body?12500:6500;
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
int main() {
    poses(); pushes(); contact_and_weapons();
    std::printf("Collision / sprite geometry: %d checks, %d failures\n",checks,failures);
    return failures?1:0;
}
