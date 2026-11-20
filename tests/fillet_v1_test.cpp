#include "../core/fight.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <initializer_list>
using namespace fight;
static Simulation sim;
static int checks=0;
static void check(bool ok,const char* text){++checks;if(!ok){std::fprintf(stderr,"Fillet v1: %s (frame %d, move %d/%d, ages %d/%d, pair %d C%d)\n",text,sim.world.frame,sim.world.players[0].move,sim.world.players[1].move,sim.world.players[0].age,sim.world.players[1].age,sim.world.pair.kind,sim.world.pair.clock);std::fprintf(stderr,"x %d %d stun %d health %d stop %d event %d\n",sim.world.players[0].x,sim.world.players[1].x,sim.world.players[1].stun,sim.world.players[1].health,sim.world.hitstop,sim.world.players[0].event);std::exit(1);}}
static void setup(int a=5,int b=4,int gap=6200){sim.defaults();sim.reset(a,b,0,0);sim.world.players[0].x=40000;sim.world.players[1].x=40000+gap;}
static void ticks(int n,int a=0,int b=0){while(n--)sim.step(a,b);}
static void bleed(int time=420,int grey=20){auto& b=sim.world.players[1];b.bleed_source=14;b.bleed_time=time;b.grey_life=grey;}
static void begin(int m){check(sim.preview_begin(0,m),"preview start");}
static void unfreeze(){while(sim.world.hitstop)sim.step(0,0);}
static void otg_routes(){
    // Roots only: every knockdown and Wound uses normal inputs. Test the new
    // recovery cancels with a six-tick confirmation delay, not a staged Downed.
    for(int receiver=0;receiver<CHARACTER_COUNT;++receiver)for(int owner:{0,1})for(int facing:{-1,1})
    for(int source:{SLASH_SWEEP,26,27})for(int delay:{0,6})for(int gap:{6200,10000}){
        setup(owner?receiver:5,owner?5:receiver);
        auto& a=sim.world.players[owner];auto& b=sim.world.players[1-owner];
        a.x=50000;b.x=50000+facing*gap;a.facing=facing;b.facing=-facing;
        auto step=[&](int input=0){sim.step(owner?0:input,owner?input:0);};
        const int forward=facing>0?Right:Left;
        if(source==SLASH_SWEEP)step(Down|S);
        else{
            step(Down);step(Down|forward);step(forward|S);
            for(int n=0;n<80&&!a.contact_count;++n)step();
            check(a.contact_count==1,"Opening connects through ordinary inputs");
            while(sim.world.hitstop)step();
            step((source==26?forward:Down)|S);
        }
        check(a.move==source,"input selects knockdown finisher");
        const int contacts=source==SLASH_SWEEP?1:2;
        for(int n=0;n<80&&a.contact_count<contacts;++n)step();
        check(a.contact_count==contacts,"finisher connects");
        while(sim.world.hitstop)step();
        // A D press buffered during the landing must wait for Downed.
        for(int n=0;n<delay;++n)step();
        check(a.move==source,"confirmation still inside finisher recovery");
        const int health=b.health,momentum=a.momentum,defender_momentum=b.momentum;
        step(D);
        for(int n=0;n<5&&a.move==source;++n)step();
        check(a.move==13,"hit-only Wound cancels finisher recovery");
        const auto saved=sim.world;const int frame=sim.world.frame;
        for(int n=0;n<40&&!sim.world.pair.kind;++n)step();
        check(sim.world.pair.kind==WoundCapture,"Wound reaches natural knockdown before wakeup");
        for(int n=0;n<40&&(sim.world.pair.kind||sim.world.hitstop);++n)step();
        check(b.bleed_time==420&&b.grey_life==20&&b.reaction==Free,"Wound releases into owned bleed");
        check(b.health==health&&a.momentum==momentum&&b.momentum==defender_momentum,"Wound adds no damage or meter");
        const unsigned hash=sim.checksum();const int elapsed=sim.world.frame-frame;
        sim.world=saved;for(int n=0;n<elapsed;++n)step();
        check(sim.checksum()==hash,"OTG cancel and release replay identically");
    }
    for(int source:{SLASH_SWEEP,26,27})for(bool whiff:{false,true}){
        setup(5,4,whiff?35000:6200);
        // Keep standing guard from walking out of Crown's reach before impact.
        if(!whiff){sim.world.players[0].x=90000;sim.world.players[1].x=96200;}
        begin(source);const int guard=source==26?Right:Right|Down;
        for(int n=0;n<sim.moves[5][source].v[Startup];++n)sim.step(0,guard);
        auto& a=sim.world.players[0];auto& b=sim.world.players[1];
        check(whiff?!a.contact:a.event==Blocked,"negative fixture whiffs or blocks");
        if(!whiff&&source==SLASH_SWEEP)check(b.block_advantage==-8,"sweep retains its punishable -8 block advantage");
        while(sim.world.hitstop)sim.step(0,guard);
        sim.step(D,guard);for(int n=0;n<6;++n)sim.step(0,guard);
        check(a.move==source&&!sim.world.pair.kind&&!b.bleed_time,"Wound cannot cancel block or whiff recovery");
    }
    setup();
    check(sim.can_cancel(5,6,13,1)&&sim.can_cancel(5,26,13,1)&&sim.can_cancel(5,27,13,1),"three explicit Wound destinations");
    check(!sim.can_cancel(5,6,13,0)&&!sim.can_cancel(5,0,13,1)&&!sim.can_cancel(5,7,13,1),"no implicit or whiff Wound route");
    sim.extensions[5][6].v[XRoutes+2]=0;
    check(!sim.can_cancel(5,6,13,1),"removing authored route disables cancel");
    setup();sim.moves[5][6].v[Knockdown]=NoKnockdown;
    check(!sim.can_cancel(5,6,13,1),"Wound route requires knockdown property");
}
static void capture_boundaries(){
    // Real normal-throw inputs, mirrored roles and sides. C6 remains techable;
    // C7 is committed. The setup changes roots only, never the input resolver.
    for(int p=0;p<2;++p)for(int facing=-1;facing<=1;facing+=2)for(int tech:{1,6,7}){
        setup(p?4:5,p?5:4);auto& owner=sim.world.players[p];auto& target=sim.world.players[1-p];
        owner.x=50000;target.x=50000+facing*7000;owner.facing=facing;target.facing=-facing;
        int command=(facing>0?Right:Left)|P|K;
        sim.step(p?0:command,p?command:0);sim.step(0,0);
        check(sim.world.pair.kind==NormalCapture&&sim.world.pair.owner==p,"input-selected ordinary pair, both roles/facings");
        unfreeze();ticks(tech-1);sim.step(p?(P|K):0,p?0:(P|K));
        check((sim.world.pair.kind==0)==(tech<=6),"C1/C6 tech accepted, C7 too late");
        if(tech<=6){check(owner.health==1000&&target.health==1000,"tech no health mutation");check((target.x-owner.x)*facing==12000,"tech preserves side order and 120px separation");}
    }
    setup(5,4,7000);begin(FORWARD_THROW);ticks(2);sim.step(0,P|K);while(sim.world.hitstop)sim.step(0,P|K);sim.step(0,P|K);
    check(sim.world.pair.kind==NormalCapture,"expired capture-freeze chord does not auto-tech from held buttons");
    setup(5,4,7000);begin(FORWARD_THROW);ticks(2);unfreeze();sim.step(0,Faultless);
    check(sim.world.pair.kind==NormalCapture,"FD macro is not a throw-tech chord");
    // Opponent owns a bleed on Fillet. A tech preserves it, but an unteched
    // normal throw clears it at commit, before the later health event.
    setup(5,5,7000);sim.world.players[0].bleed_source=14;sim.world.players[0].bleed_time=420;sim.world.players[0].grey_life=20;
    begin(FORWARD_THROW);ticks(2);unfreeze();ticks(6);check(sim.world.players[0].bleed_time>0,"precommit retains victim-owned bleed");ticks(1);check(!sim.world.players[0].bleed_time,"C7 clears committed normal-throw victim's owned bleed");
    setup(3,4,7000);begin(FORWARD_THROW);ticks(2);check(sim.world.pair.kind==LegacyCapture,"Tapper normal throw uses shared gate");unfreeze();ticks(6);
    check(sim.world.players[0].grab_time>0&&sim.world.hitstop==0,"Tapper resumes authored capture after gate without second freeze");
    while(sim.world.players[0].grab_time)sim.step(0,0);
    check(sim.world.players[1].health<1000&&sim.world.hitstop==0&&sim.world.players[0].stance==1,"Tapper finisher preserves damage/stance and pays no second capture stop");
    setup(5,4,7000);begin(FORWARD_THROW);ticks(2);unfreeze();ticks(24);unfreeze();
    auto& attacker=sim.world.players[0];auto& defender=sim.world.players[1];
    defender.x=attacker.x+6000;defender.pair_recovery=0;defender.pair_grace_pending=0;
    check(sim.preview_begin(1,0),"isolate strike against paired release recovery");defender.age=sim.moves[4][0].v[Startup]-1;sim.step(0,0);
    check(attacker.health<1000&&attacker.stun>0&&attacker.pair_recovery==0,"hit interrupts the victim's independent paired recovery");
    setup(5,4,7000);begin(FORWARD_THROW);ticks(2);unfreeze();sim.world.remaining=1;sim.step(0,0);
    check(sim.world.winner>=0&&!sim.world.pair.kind&&sim.world.players[1].health==1000,"timeout cancels uncommitted paired damage");
}

int main(){
    setup();int enabled=0;for(auto& m:sim.moves[5])enabled+=m.v[Enabled];check(enabled==26,"26 enabled actions");
    for(int c=0;c<6;++c){check(sim.extension_set(c,-1,sim.character_extensions[c].v),"character extension validates");for(int m=0;m<MOVE_COUNT;++m)check(sim.extension_set(c,m,sim.extensions[c][m].v),"action extension validates");}
    check(sim.can_cancel(5,CLOSE_SLASH,FAR_SLASH,1)&&sim.can_cancel(5,CLOSE_SLASH,SLASH_SWEEP,1),"named c.S routes");
    check(!sim.can_cancel(5,5,6,1)&&!sim.can_cancel(5,6,14,1),"no implicit 2K sweep or sweep special route");
    begin(CLOSE_SLASH);ticks(6);ticks(1,0,Right|Down);check(sim.world.players[1].stun==17&&sim.world.players[1].x==46800,"c.S first block, 6px push");
    unfreeze();sim.step(S,Right);check(sim.world.players[0].move==FAR_SLASH&&sim.world.players[0].age==1,"c.S bypasses proximity into f.S");
    setup(5,4,35000);begin(8);ticks(3);check(sim.box_count(0,HurtBox)==1,"6P only legs from frame 3");ticks(10);check(sim.box_count(0,HurtBox)==4,"6P restores body on frame 13");
    setup(5,4,25000);begin(25);ticks(20);check(sim.world.players[0].x==55000,"passing cut moves 150px");
    setup(5,4,9000);begin(25);ticks(21);check(sim.world.players[0].x>sim.world.players[1].x&&sim.world.players[0].facing==-1,"passing cut crosses and refaces once");
    setup();sim.step(Left|Faultless|Up,0);check(sim.world.players[0].prejump_time==4&&!sim.world.players[0].faultless,"legal Up beats ground FD");
    setup(5,4,35000);auto& a=sim.world.players[0];a.y=20000;a.vy=0;sim.step(Dash,0);check(a.dash_pause==3&&a.vx==0,"air dash starts four-tick pause");ticks(3);check(a.dash_pause==0&&a.vx==0,"full pause");ticks(5);check(a.vx==2000&&a.coast_pending,"five burst ticks");ticks(1);check(a.vx==650&&a.coast_mode,"650 coast before inputs");
    setup();bleed();ticks(419);check(sim.world.players[1].bleed_time==1&&sim.world.players[1].grey_life==59,"bleed growth through 419");ticks(1);check(!sim.world.players[1].bleed_source,"expiry before tick 420 growth");
    setup();auto& victim=sim.world.players[1];victim.reaction=Downed;victim.knockdown=HardKnockdown;victim.recovery_time=56;victim.wakeup_frames=8;
    begin(13);ticks(24);check(sim.world.pair.kind==WoundCapture&&victim.health==1000,"Wound captures Downed without damage");
    unfreeze();ticks(20);check(!sim.world.pair.kind&&victim.bleed_time==420&&victim.grey_life==20,"Wound applies bleed only at C20");
    check(victim.x-sim.world.players[0].x==12000&&victim.throw_grace==5&&victim.reaction==Free,"Wound standing reset and grace");
    setup();begin(13);ticks(45);check(!sim.world.pair.kind&&!sim.world.players[1].bleed_time&&sim.world.players[0].move==-1,"standing Wound whiffs finitely");
    setup(5,4,7000);begin(FORWARD_THROW);ticks(2);check(sim.world.pair.kind==NormalCapture&&sim.world.players[1].health==1000,"throw has precommit pair");
    unfreeze();sim.step(0,P|K);check(!sim.world.pair.kind&&sim.world.players[0].pair_recovery==12&&sim.world.players[1].health==1000,"C1 fresh chord techs without damage");
    setup(5,4,7000);begin(FORWARD_THROW);ticks(2);unfreeze();ticks(24);check(sim.world.players[1].health==955&&sim.world.players[0].momentum==360&&sim.world.players[1].momentum==180,"throw release damage/meter once");
    check(sim.world.players[0].pair_recovery==12&&sim.world.players[1].pair_recovery==14,"+2 independent recovery");
    unfreeze();ticks(12);check(!sim.world.players[0].pair_recovery&&sim.world.players[1].pair_recovery==2,"owner unlocks two ticks earlier");
    setup(5,4,24000);bleed(420,59);begin(VAULT_CASHOUT);ticks(22);check(sim.world.pair.kind==CommandCapture&&!sim.world.players[1].bleed_source,"cashout capture consumes snapshotted bleed");
    unfreeze();ticks(28);check(sim.world.players[1].health==886&&sim.world.players[1].x-sim.world.players[0].x==17000,"55 + 59 release, 170px reset");
    setup(5,4,24000);bleed();begin(SKIM_CASHOUT);sim.step(0,Up);ticks(60);check(!sim.world.pair.kind&&sim.world.players[1].health==1000&&sim.world.players[0].move==-1,"jump failure latch and finite whiff");
    setup(4,5,7000);begin(FORWARD_THROW);ticks(2);check(sim.world.pair.kind==LegacyCapture,"other fighters get precommit gate");unfreeze();sim.step(0,P|K);check(sim.world.players[1].health==1000&&!sim.world.pair.kind,"legacy throw tech preserves health");
    setup(5,4,7000);begin(FORWARD_THROW);sim.preview_begin(1,FORWARD_THROW);ticks(2);check(!sim.world.pair.kind&&sim.world.players[0].pair_recovery==12,"simultaneous captures tech symmetrically");
    capture_boundaries();
    otg_routes();
    std::printf("Fillet v1: %d runtime checks passed\n",checks);
}
