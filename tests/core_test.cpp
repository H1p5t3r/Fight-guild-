#include "../core/fight.h"
#include <cstdio>
#include <cstring>
#include <cstdlib>
using namespace fight;
static int checks=0,failures=0;
#define CHECK(x) do { ++checks; if(!(x)) { std::fprintf(stderr,"FAIL line %d: %s\n",__LINE__,#x); ++failures; } } while(0)
static void fresh(int s0=0,int s1=0) { defaults(); reset(0,1,s0,s1); }
static void ticks(int n,int a=0,int b=0) { for(int i=0;i<n;++i) step(a,b); }
static void near() { world.players[0].x=45000; world.players[1].x=52000; }
static void thaw() { while(world.hitstop) step(0,0); }
static void test_routes() {
    fresh();
    CHECK(fg_can_cancel(0,0,4,1)); // 5P -> 2P
    CHECK(fg_can_cancel(0,0,1,1));
    CHECK(!fg_can_cancel(0,0,2,1));
    CHECK(!fg_can_cancel(0,1,2,1));
    CHECK(fg_can_cancel(0,2,3,1));
    CHECK(!fg_can_cancel(0,3,0,1));
    for(int c=0;c<2;++c) for(int from=0;from<MOVE_COUNT;++from) {
        const auto& source=moves[c][from];
        int command=8+source.v[Button];
        if(from!=command) CHECK(fg_can_cancel(c,from,command,1));
        CHECK(!fg_can_cancel(c,from,command,0));
        CHECK(!fg_can_cancel(c,from,from,1));
    }
    for(int from=1;from<4;++from) for(int to=8;to<13;++to) CHECK(fg_can_cancel(0,from,to,1));
    for(int from=0;from<8;++from) CHECK(fg_can_cancel(0,from,14,1));
    CHECK(!fg_can_cancel(0,14,15,1));
    CHECK(fg_can_cancel(1,13,14,1)); // Hammer Drive explicitly permits special cancels.
    CHECK(!fg_can_cancel(0,13,14,1));
    CHECK(!fg_move_set(0,0,Startup,0));
    CHECK(!fg_move_set(0,0,Damage,1001));
    CHECK(fg_move_set(0,0,SelfCancel,1));
    CHECK(fg_can_cancel(0,0,0,1));
    CHECK(fg_move_set(0,0,SpecialCancel,0));
    CHECK(!fg_can_cancel(0,0,14,1));
}
static void test_motion() {
    fresh(); ticks(1,Down); ticks(1,Down|Right); ticks(1,Right|P);
    CHECK(world.players[0].move==14);
    fresh(); ticks(1,Right); ticks(1,Down); ticks(1,Down|Right|Hs);
    CHECK(world.players[0].move==16);
    fresh(); ticks(1,Down); ticks(21); ticks(1,Down|Right); ticks(1,Right|P);
    CHECK(world.players[0].move==8); // Stale motion becomes forward P command normal.
    fresh(); ticks(1,0,Down); ticks(1,0,Down|Left); ticks(1,0,Left|P);
    CHECK(world.players[1].move==14); // Facing-left motions mirror correctly.
    fresh(1); ticks(1,Simple|Right|P);
    CHECK(world.players[0].move==14);
    fresh(); ticks(1,Simple|Right|P);
    CHECK(world.players[0].move==8); // Disabled simple mode cannot invoke a shortcut.
    fresh(1); ticks(1,Down); ticks(1,Down|Right); ticks(1,Right|P);
    CHECK(world.players[0].move==14); // Traditional motions remain available.
    fresh(1); ticks(1,Simple|P);
    CHECK(world.players[0].move==-1); // Unmapped modifier chord does not fall through.
    fresh(1); ticks(1,Simple|Up|Hs);
    CHECK(world.players[0].move==16&&world.players[0].y==0);
    fresh(); ticks(1,Left|Right|P);
    CHECK(world.players[0].move==0);
}
static void test_combat() {
    fresh(); near(); ticks(4,P);
    CHECK(world.players[1].health==1000);
    ticks(1,P);
    CHECK(world.players[1].health==965);
    CHECK(world.hitstop==6);
    ticks(40,P);
    CHECK(world.players[1].health==965); // Held attack does not repeatedly trigger.
    fresh(); near(); ticks(5,P,Right);
    CHECK(world.players[1].health==1000);
    CHECK(world.players[1].guarding==1);
    CHECK(world.players[0].contact==1);
    fresh(); near(); world.players[1].stun=1; moves[0][0].v[Startup]=1;
    ticks(1,P,Right);
    CHECK(world.players[1].health==965); // Last hitstun tick cannot block early.
    fresh(); near(); ticks(5,P,P);
    CHECK(world.players[0].health==970);
    CHECK(world.players[1].health==965);
    CHECK(world.players[0].move==-1&&world.players[1].move==-1);
    fresh(); near(); ticks(5,P); thaw(); ticks(1,K);
    CHECK(world.players[0].move==1); // P -> K on hit.
    fresh(); ticks(5,P); ticks(1,K);
    CHECK(world.players[0].move==0); // No whiff gatlings.
    fresh(); near(); ticks(8,K); thaw(); ticks(1,Up);
    CHECK(world.players[0].y>0&&world.players[0].move==-1);
    fresh(); near(); ticks(5,P); thaw(); ticks(1,Up);
    CHECK(world.players[0].y==0&&world.players[0].move==0);
    fresh(1); near(); ticks(1,Simple|Right|P); ticks(13); thaw(); ticks(1,Right|P);
    CHECK(world.players[0].move==8); // Special P -> command P.
    fresh(); ticks(1,Up); CHECK(world.players[0].y>0);
    ticks(1,S); CHECK(world.players[0].move==19);
    ticks(60); CHECK(world.players[0].y==0&&world.players[0].move==-1);
    fresh(); int start=world.players[0].x; ticks(3,Dash);
    CHECK(world.players[0].x-start==2550);
    fresh(); ticks(1,P); ticks(13); ticks(1,K); ticks(3);
    CHECK(world.players[0].move==1); // Buffered K starts once P recovery ends.
    fresh(); ticks(1,P); ticks(2); ticks(1,K); ticks(20);
    CHECK(world.players[0].move==-1); // Early buffer expires.
    fresh(); near(); world.players[1].health=1; ticks(5,P);
    CHECK(world.winner==0);
    fresh(); world.remaining=1; step(0,0); CHECK(world.winner==2);
}
static unsigned next(unsigned& s) { s^=s<<13; s^=s>>17; s^=s<<5; return s; }
static int random_input(unsigned& s) {
    unsigned n=next(s);
    return ((n%3)==0?Left:(n%3)==1?Right:0)
        |((n&16)?Down:0)|((n%29)==0?Up:0)
        |((n%5)==0?(P<<((n>>8)%5)):0)|((n%31)==0?Dash:0);
}
static void test_replay() {
    fresh(); unsigned seed=123456;
    for(int i=0;i<80;++i) { int a=random_input(seed),b=random_input(seed); step(a,b); }
    State snapshot=world; unsigned saved_seed=seed;
    for(int i=0;i<1000;++i) { int a=random_input(seed),b=random_input(seed); step(a,b); }
    unsigned expected=checksum();
    world=snapshot; seed=saved_seed;
    for(int i=0;i<1000;++i) { int a=random_input(seed),b=random_input(seed); step(a,b); }
    CHECK(checksum()==expected);
    // A wrong predicted input must be completely repairable by restoring and replaying.
    world=snapshot; ticks(12,Right|P,Left|S); world=snapshot; seed=saved_seed;
    for(int i=0;i<1000;++i) { int a=random_input(seed),b=random_input(seed); step(a,b); }
    CHECK(checksum()==expected);
    CHECK(fg_state_size()==sizeof(State));
}
int main(int argc,char** argv) {
    if(argc>1&&std::strcmp(argv[1],"--trace")==0) {
        fresh(); unsigned seed=123456;
        for(int i=0;i<1200;++i) {
            int a=random_input(seed),b=random_input(seed); step(a,b);
            std::printf("%d %d %u\n",a,b,checksum());
        }
        return 0;
    }
    test_routes(); test_motion(); test_combat(); test_replay();
    std::printf("%d checks, %d failures\n",checks,failures);
    return failures?1:0;
}
