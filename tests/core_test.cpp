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
    for(int c=0;c<CHARACTER_COUNT;++c) for(int from=0;from<MOVE_COUNT;++from) {
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
static void test_momentum() {
    fresh(); CHECK(world.players[0].momentum==0&&world.players[1].momentum==0);
    ticks(10,Right); CHECK(world.players[0].momentum==60);
    int earned=world.players[0].momentum;
    ticks(10,Left); CHECK(world.players[0].momentum==earned);
    ticks(10); CHECK(world.players[0].momentum==earned);
    fresh(); world.players[0].momentum=9999; step(Right,0);
    CHECK(world.players[0].momentum==MOMENTUM_MAX);
    fresh(); world.players[0].x=91600; world.players[1].x=97200;
    ticks(20,Right); CHECK(world.players[0].momentum==0); // Pushing the corner earns no meter.
    fresh(); ticks(30,P); CHECK(world.players[0].momentum==0); // Whiffed normal.
    fresh(1); step(Simple|Right|P,0);
    CHECK(world.players[0].momentum==rules.special_gain); // Special activation, once.
    ticks(10,Simple|Right|P); CHECK(world.players[0].momentum==rules.special_gain);
    fresh(); near(); ticks(5,P);
    CHECK(world.players[0].momentum==35*rules.attack_gain);
    CHECK(world.players[1].momentum==35*rules.damage_gain);
    earned=world.players[0].momentum; ticks(3); CHECK(world.players[0].momentum==earned);
    fresh(); near(); ticks(5,P,Right);
    CHECK(world.players[0].momentum==35*rules.block_attack_gain);
    CHECK(world.players[1].momentum==35*rules.guard_gain);
    fresh(); world.players[0].momentum=5000; world.players[1].health=1; near(); ticks(5,P);
    earned=world.players[0].momentum; ticks(60,Left|Faultless);
    CHECK(world.players[0].momentum==earned); // Round end freezes meter.
    reset(0,1,0,0); CHECK(world.players[0].momentum==0);
}
static void test_faultless() {
    fresh(); near(); world.players[1].momentum=5000;
    ticks(5,P,Right|Faultless);
    CHECK(world.players[1].faultless==1&&world.players[1].guarding==1);
    CHECK(world.players[1].health==1000);
    CHECK(world.players[1].momentum==5000-5*rules.fd_drain-rules.fd_block_cost-35*rules.fd_damage_cost);
    CHECK(world.players[1].x==52000+800*rules.fd_push_percent/100);
    CHECK(world.players[1].stun==moves[0][0].v[Blockstun]); // No extra FD blockstun.
    int held=world.players[1].momentum;
    step(0,Right|Faultless); CHECK(world.players[1].momentum==held-rules.fd_drain);
    step(0,0); CHECK(!world.players[1].faultless&&world.players[1].momentum==held-rules.fd_drain);
    fresh(); world.players[0].momentum=1000;
    step(Left|P|K,0); CHECK(world.players[0].faultless&&world.players[0].move==-1);
    step(Left,0); ticks(10); CHECK(world.players[0].move==-1); // FD chord cannot leak into buffered normals.
    fresh(); step(Left|P|K,0);
    CHECK(!world.players[0].faultless&&world.players[0].move==-1); // Empty-meter chord still guards.
    fresh(); world.players[0].momentum=1000; step(Left|P|D,0);
    CHECK(!world.players[0].faultless&&world.players[0].move==13); // D does not count toward the chord.
    fresh(); world.players[0].momentum=1000; step(Right|Faultless,0);
    CHECK(!world.players[0].faultless); // Holding toward is not a guard.
    fresh(); world.players[0].momentum=1000; step(Left|Right|Faultless,0);
    CHECK(!world.players[0].faultless); // SOCD neutral does not guard.
    fresh(); world.players[0].momentum=1; step(Left|Faultless,0);
    CHECK(world.players[0].faultless&&world.players[0].momentum==0);
    step(Left|Faultless,0); CHECK(!world.players[0].faultless&&world.players[0].momentum==0);
    fresh(); world.players[0].momentum=1000; step(P,0); step(Left|Faultless,0);
    CHECK(world.players[0].move==0&&!world.players[0].faultless); // No FD cancel out of attacks.
    fresh(); near(); world.players[1].momentum=1000; world.players[1].stun=1; moves[0][0].v[Startup]=1;
    step(P,Right|Faultless); CHECK(world.players[1].health==965&&!world.players[1].faultless);
    fresh(1); near(); ticks(14,Simple|Right|P,Right|Down);
    CHECK(world.players[1].health==1000-moves[0][14].v[ChipDamage]);
    fresh(1); near(); world.players[1].momentum=5000; ticks(14,Simple|Right|P,Right|Faultless);
    CHECK(world.players[1].health==1000&&world.players[1].guarding);
    fresh(1); near(); world.players[1].health=1; ticks(14,Simple|Right|P,Right|Down);
    CHECK(world.players[1].health==0&&world.winner==0); // Chip can close a round.
    fresh(1); near(); world.players[1].health=1; world.players[1].momentum=5000; ticks(14,Simple|Right|P,Right|Faultless);
    CHECK(world.players[1].health==1&&world.winner==-1);
    fresh(); near(); moves[0][0].v[HitLevel]=1; world.players[1].momentum=5000; ticks(5,P,Right|Faultless);
    CHECK(world.players[1].health==965&&!world.players[1].faultless); // FD still needs the correct high/low guard.
    fresh(); near(); moves[0][0].v[HitLevel]=1; world.players[1].momentum=5000; ticks(5,P,Right|Down|Faultless);
    CHECK(world.players[1].health==1000&&world.players[1].faultless);
    fresh(); near(); world.players[1].y=5000; world.players[1].momentum=5000; ticks(5,P,Right|Faultless);
    CHECK(world.players[1].health==1000&&world.players[1].faultless); // Air FD.
    fresh(); world.players[0].x=90200; world.players[1].x=97200; world.players[1].momentum=5000;
    ticks(5,P,Right|Faultless); CHECK(world.players[0].x==87800&&world.players[1].x==97200);
    fresh(); near(); world.players[0].momentum=5000; ticks(5,Left|Faultless,P);
    CHECK(world.players[0].faultless&&world.players[0].health==1000); // Mirrored guard.
    CHECK(!fg_rule_set(FDDrain,0)); CHECK(!fg_rule_set(FDPushPercent,99));
    CHECK(fg_move_set(0,0,ChipDamage,50)); CHECK(!fg_move_set(0,0,ChipDamage,-1));
}
static void test_no_negative_penalty() {
    fresh(); world.players[0].momentum=5000; ticks(1200);
    CHECK(world.players[0].momentum==5000);
    ticks(1200,Left); CHECK(world.players[0].momentum==5000);
}
static void test_block_reactions() {
    // Actual first-active-frame advantage: B - (active - 1 + recovery).
    fresh(); near(); moves[0][0].v[Blockstun]=10; ticks(5,P,Right|Down);
    CHECK(world.players[1].block_reaction==StableBlock&&world.players[1].block_advantage==-2);
    CHECK(fg_get(1,21)==1&&!world.players[1].guard_break);
    CHECK(world.players[1].block_age==0);
    ticks(6,0,Right|Down); CHECK(world.players[1].block_age==0); // Hitstop freezes the clip.
    ticks(4,0,Right|Down); CHECK(world.players[1].block_age==4);
    fresh(); near(); ticks(5,P,Right|Down);
    CHECK(world.players[1].block_reaction==StableBlock&&world.players[1].block_advantage==0);
    fresh(); near(); moves[0][0].v[Blockstun]=16; ticks(5,P,Right|Down);
    CHECK(world.players[1].block_reaction==PressureBlock&&world.players[1].block_advantage==4);
    CHECK(fg_get(1,21)==1);
    // A meaty contact on the third active frame changes an even move to +2.
    fresh(); world.players[1].x=80000; ticks(6,P,Right|Down);
    near(); step(0,Right|Down);
    CHECK(world.players[1].block_reaction==PressureBlock&&world.players[1].block_advantage==2);
    for(int mirrored=0;mirrored<2;++mirrored) {
        fresh(); near(); moves[0][0].v[GuardBreak]=1;
        if(mirrored) { world.players[0].x=52000; world.players[1].x=45000; }
        int away=mirrored?Left:Right;
        ticks(4,P,away|Down); State before=world;
        step(P,away|Down); unsigned contact_hash=checksum();
        CHECK(world.players[1].block_reaction==BrokenGuard&&world.players[1].guard_break);
        CHECK(fg_get(1,21)==0); // Guard break removes the ordinary blockstun throw protection.
        world=before; step(P,away|Down); CHECK(checksum()==contact_hash);
        while(world.hitstop||world.players[1].stun>2) step(0,away|Down);
        int x=world.players[1].x;
        step(0,away|Down|Dash); CHECK(world.players[1].x==x&&!world.players[1].dash);
        ticks(2,0,away|Down); CHECK(!world.players[1].dash); // Consumed, not queued for exit.
        CHECK(!world.players[1].guard_break&&world.players[1].block_reaction==NoBlock);
        step(0,away|Dash); CHECK(world.players[1].dash==9); // Fresh backdash after recovery works.
    }
    fresh(); near(); ticks(5,P,Right|Down);
    while(world.hitstop||world.players[1].stun>2) step(0,Right|Down);
    step(0,Right|Down|Dash); ticks(2,0,Right|Down);
    CHECK(world.players[1].dash==9); // Ordinary blockstun still accepts a buffered backdash.
    fresh(); near(); moves[0][0].v[GuardBreak]=1; world.players[1].momentum=5000;
    ticks(5,P,Right|Down|Faultless);
    CHECK(world.players[1].faultless&&world.players[1].guard_break&&fg_get(1,21)==0);
    fresh(); near(); moves[0][0].v[GuardBreak]=1; ticks(5,P);
    CHECK(!world.players[1].guard_break&&world.players[1].block_reaction==NoBlock&&fg_get(1,21)==1);
    CHECK(fg_move_set(0,0,GuardBreak,0)); CHECK(!fg_move_set(0,0,GuardBreak,2));
}
static void test_roster() {
    const int slots[5]={0,1,2,3,13};
    for(int c=0;c<CHARACTER_COUNT;++c) for(int button=0;button<5;++button) {
        defaults(); reset(c,(c+1)%CHARACTER_COUNT,0,0); near();
        CHECK(world.players[0].character==c);
        step(P<<button,0);
        const auto& move=moves[c][slots[button]];
        CHECK(world.players[0].move==slots[button]);
        ticks(move.v[Startup]-1);
        CHECK(world.players[1].health==1000-move.v[Damage]);
        CHECK(world.players[0].contact==1);
        thaw(); ticks(1,Right|(P<<button));
        CHECK(world.players[0].move==8+button); // Same-button command route for every fighter/button.
    }
    CHECK(fg_move_get(CHARACTER_COUNT,0,Damage)==-999);
    CHECK(!fg_move_set(-1,0,Damage,1));
}
static int random_input(unsigned& s) {
    unsigned n=next(s);
    return ((n%3)==0?Left:(n%3)==1?Right:0)
        |((n&16)?Down:0)|((n%29)==0?Up:0)
        |((n%5)==0?(P<<((n>>8)%5)):0)|((n%31)==0?Dash:0)|((n%13)==0?Faultless:0);
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
    test_routes(); test_motion(); test_combat(); test_replay(); test_roster();
    test_momentum(); test_faultless(); test_no_negative_penalty(); test_block_reactions();
    std::printf("%d checks, %d failures\n",checks,failures);
    return failures?1:0;
}
