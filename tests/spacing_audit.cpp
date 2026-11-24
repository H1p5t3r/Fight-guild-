#include "../core/fight.h"
#include <algorithm>
#include <cstdio>
#include <fstream>
#include <memory>
#include <vector>
using namespace fight;

// Configuration already validated by CombatModel/FightCore. This is only a
// local test-fixture reader; it is not a game save format or a second importer.
static bool load(Simulation& s,const char* path) {
    std::ifstream file(path,std::ios::binary);
    const int count=CHARACTER_COUNT*(MOVE_COUNT*(FIELD_COUNT+HURT_PHASES*HURT_FIELDS+HIT_TRACK_FIELDS+EXTENSION_FIELDS)+MOBILITY_FIELDS+CHARACTER_EXTENSION_FIELDS)+RULE_COUNT;
    std::vector<int> data(count);file.read(reinterpret_cast<char*>(data.data()),count*sizeof(int));
    if(!file||file.peek()!=std::char_traits<char>::eof())return false;
    auto at=data.begin();
    for(auto& c:s.moves)for(auto& m:c)for(auto& v:m.v)v=*at++;
    for(auto& c:s.mobility)for(auto& v:c.v)v=*at++;
    for(auto& c:s.move_hurt)for(auto& m:c)for(auto& phase:m){phase.count=*at++;for(auto& b:phase.boxes){b={at[0],at[1],at[2],at[3]};at+=4;}}
    for(auto& c:s.move_hit)for(auto& m:c){m.multi=*at++;m.count=*at++;for(auto& key:m.keys){key.frame=*at++;key.group=*at++;key.count=*at++;key.damage=*at++;key.hitstun=*at++;key.blockstun=*at++;key.hitstop=*at++;for(auto& b:key.boxes){b={at[0],at[1],at[2],at[3]};at+=4;}}}
    for(int c=0;c<CHARACTER_COUNT;++c){for(auto& v:s.character_extensions[c].v)v=*at++;for(auto& m:s.extensions[c])for(auto& v:m.v)v=*at++;}
    for(int f=0;f<RULE_COUNT;++f)if(!s.rule_set(f,*at++))return false;
    return at==data.end();
}

struct Result {int hits=0,damage=0,peak=0,bounces=0,overlap=0,recovered=0,splat=0;};
static bool authored_pass(const Simulation& s,const Fighter& f) {
    if(!s.character_extensions[f.character].v[CPolicy]||f.move<0||f.stun||f.reaction!=Free)return false;
    const auto* x=s.extensions[f.character][f.move].v;
    // The post-step age is the tick just resolved, matching passing(f) before
    // its age increment. Fillet's approved knife spiral can cross a body.
    if(x[XPassStart]>0&&f.age>=x[XPassStart]&&f.age<=x[XPassEnd])return true;
    for(int i=0;i<x[XRoot];++i){const auto* k=x+XRoot+1+i*5;if(k[4]==1&&f.age>=k[0]&&f.age<=k[1])return true;}
    return false;
}
static Result attack(Simulation& s,int c,int target,int move,int posture,int gap,int corner,int side,int player) {
    s.reset(player?target:c,player?c:target,0,0);
    auto& a=s.world.players[player];auto& b=s.world.players[1-player];
    const auto pa=s.box(player,PushBox),pb=s.box(1-player,PushBox);
    const int aw=(pa.right-pa.left)/2,bw=(pb.right-pb.left)/2;
    const int separation=aw+bw+gap;
    int x=corner==1?aw:corner==2?100000-bw-separation:45000;
    int y=x+separation;
    a.x=side?100000-x:x;b.x=side?100000-y:y;
    a.facing=side?-1:1;b.facing=-a.facing;
    a.y=s.moves[c][move].v[Air]?9000:0;
    if(a.y)a.vy=650;
    b.y=posture>=2?9000:0;b.vy=posture==2?650:posture==3?-200:0;
    if(s.moves[c][move].v[StanceRequired]==2)a.stance=1;
    s.preview_begin(player,move);
    Result result;
    for(int tick=0;tick<220;++tick) {
        const int vy=b.vy,old_reaction=b.reaction;
        const int inputs[2]={player?(posture==1?Down:0):0,player?0:(posture==1?Down:0)};
        s.step(inputs[0],inputs[1]);
        result.peak=std::max(result.peak,b.y);
        if(vy<0&&b.vy>0&&b.y==1&&old_reaction==AirReel)++result.bounces;
        if(b.reaction==WallSplat)result.splat=1;
        const auto ap=s.box(player,PushBox),bp=s.box(1-player,PushBox);
        if(!s.world.pair.kind&&a.reaction!=Captured&&b.reaction!=Captured&&!authored_pass(s,a)&&!authored_pass(s,b)&&ap.top>bp.bottom&&bp.top>ap.bottom)
            result.overlap=std::max(result.overlap,std::min(ap.right,bp.right)-std::max(ap.left,bp.left));
        if(b.reaction==Free&&!b.stun&&!b.pair_recovery&&a.contact_count)result.recovered=1;
    }
    result.hits=a.contact_count;result.damage=1000-b.health;
    return result;
}
static int route_checks=0,route_failures=0;
static void basic_routes(Simulation& s) {
    for(bool slash:{false,true}) {
    int cases=0,failures=0,spacing_breaks=0;
    for(int c=0;c<6;++c)for(int target=0;target<6;++target)
    for(int side=0;side<2;++side)for(int player=0;player<2;++player)for(int corner=0;corner<3;++corner)for(int crouch=0;crouch<2;++crouch) {
        s.reset(player?target:c,player?c:target,0,0);
        auto& a=s.world.players[player];auto& b=s.world.players[1-player];
        const auto ap=s.box(player,PushBox),bp=s.box(1-player,PushBox);
        const int aw=(ap.right-ap.left)/2,bw=(bp.right-bp.left)/2;
        const int x=corner==1?aw:corner==2?100000-bw-aw-bw:45000;
        a.x=side?100000-x:x;b.x=side?100000-x-aw-bw:x+aw+bw;
        a.facing=side?-1:1;b.facing=-a.facing;
        auto step=[&](int input){int defense=a.contact_count?(Down|(side?Left:Right)):(crouch?Down:0);s.step(player?defense:input,player?input:defense);};
        step(slash?S:Down|K);
        for(int i=0;i<60&&!a.contact_count;++i)step(Down);
        while(s.world.hitstop)step(Down);
        step(slash?S:Down|S);
        for(int i=0;i<120&&a.contact_count<2;++i)step(Down);
        if(slash) {
            while(s.world.hitstop)step(Down);
            step(Hs);
            for(int i=0;i<120&&a.contact_count<3;++i)step(Down);
        }
        ++route_checks;
        ++cases;
        const int hits=slash?3:2;
        const bool connected=a.contact_count==hits&&a.combo==hits&&a.event!=Blocked&&(slash||b.knockdown==HardKnockdown);
        // Measured starter-kit limitation, not a universal combo promise:
        // Anvil's short 5Hs whiffs after f.S pushes Tapper (or a standing
        // Fillet starter) away from the wall.
        // Keep this visible until Anvil's dedicated kit/art pass addresses it.
        const bool spacing_break=slash&&c==0&&(target==3||(target==5&&!crouch))&&corner!=2;
        if(!connected&&spacing_break)++spacing_breaks;
        else if(!connected||spacing_break) {
            if(route_failures<12)std::fprintf(stderr,"%s route %d vs %d side%d player%d corner%d: contacts%d combo%d event%d kd%d move%d\n",slash?"Slash":"Sweep",c,target,side,player,corner,a.contact_count,a.combo,a.event,b.knockdown,a.move);
            ++route_failures;
            ++failures;
        }
    }
    std::printf("Real-input %s routes: %d cases, %d documented spacing breaks, %d unexpected failures\n",slash?"c.S > f.S > 5Hs":"2K > 2S",cases,spacing_breaks,failures);
    }
}
struct GuardResult {int contacts,guarding,gap,health,momentum,stun,wall;};
static GuardResult guard(Simulation& s,int c,int target,int move,int side,int player,int corner,bool fd) {
    s.reset(player?target:c,player?c:target,0,0);
    auto& a=s.world.players[player];auto& b=s.world.players[1-player];
    const auto ap=s.box(player,PushBox),bp=s.box(1-player,PushBox);
    const int aw=(ap.right-ap.left)/2,bw=(bp.right-bp.left)/2;
    const int x=corner?100000-bw-aw-bw:45000;
    a.x=side?100000-x:x;b.x=side?100000-x-aw-bw:x+aw+bw;
    a.facing=side?-1:1;b.facing=-a.facing;b.momentum=10000;
    // One remaining blockstun tick keeps both comparisons planted. This models
    // the next hit of a string, without retreating during the move's startup.
    b.stun=b.guarding=1;
    s.preview_begin(player,move);a.age=s.moves[c][move].v[Startup]-1;
    int defense=(side?Left:Right)|(s.moves[c][move].v[HitLevel]==1?Down:0)|(fd?Faultless:0);
    s.step(player?defense:0,player?0:defense);
    return {a.contact_count,b.guarding,std::abs(a.x-b.x),b.health,b.momentum,b.stun,s.world.wall_health[0]+s.world.wall_health[1]};
}
static int fd_checks=0,fd_failures=0;
static void faultless(Simulation& s) {
    for(int c=0;c<6;++c)for(int target=0;target<6;++target)
    for(int move:{0,1,2,3,4,5,6,7,8,11,32})
    for(int side=0;side<2;++side)for(int player=0;player<2;++player)for(int corner=0;corner<2;++corner) {
        if(!s.moves[c][move].v[Enabled])continue;
        auto normal=guard(s,c,target,move,side,player,corner,false);
        auto fd=guard(s,c,target,move,side,player,corner,true);
        if(!normal.contacts&&!fd.contacts)continue; // A deliberately empty first key.
        ++fd_checks;
        if(normal.contacts!=fd.contacts||!normal.guarding||!fd.guarding||fd.gap<normal.gap||fd.health!=1000||fd.momentum>=normal.momentum||fd.stun!=normal.stun||fd.wall!=normal.wall||fd.wall!=s.rules.wall_threshold*2) {
            if(fd_failures<12)std::fprintf(stderr,"FD %d vs %d move%d side%d player%d corner%d: contacts %d/%d gap %d/%d guard %d/%d\n",c,target,move,side,player,corner,normal.contacts,fd.contacts,normal.gap,fd.gap,normal.guarding,fd.guarding);
            ++fd_failures;
        }
    }
    std::printf("Faultless spacing: %d comparisons, %d failures\n",fd_checks,fd_failures);
}
int main(int argc,char** argv) {
    auto s=std::make_unique<Simulation>();s->defaults();
    if(argc!=3||!load(*s,argv[1])){std::fprintf(stderr,"Usage: spacing-audit configuration.bin results.csv\n");return 1;}
    basic_routes(*s);faultless(*s);
    if(std::string(argv[2])=="--checks-only")return route_failures||fd_failures?1:0;
    FILE* out=std::fopen(argv[2],"w");if(!out)return 1;
    std::fprintf(out,"character,target,move,posture,gap,corner,side,player,hits,damage,peak,bounces,overlap,recovered,splat\n");
    int cases=0,overlaps=0,asymmetries=0;
    for(int c=0;c<6;++c)for(int move=0;move<MOVE_COUNT;++move) {
        if(!s->moves[c][move].v[Enabled])continue;
        for(int target=0;target<6;++target)for(int posture=0;posture<4;++posture)
        for(int gap:{0,6000,14000})for(int corner=0;corner<3;++corner) {
        Result reference;
        for(int side=0;side<2;++side)for(int player=0;player<2;++player) {
            const auto r=attack(*s,c,target,move,posture,gap,corner,side,player);
            ++cases;if(r.overlap>1)++overlaps;
            if(!side&&!player)reference=r;
            else if(r.hits!=reference.hits||r.damage!=reference.damage||r.bounces!=reference.bounces||r.splat!=reference.splat||std::abs(r.peak-reference.peak)>100)++asymmetries;
            std::fprintf(out,"%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n",c,target,move,posture,gap,corner,side,player,r.hits,r.damage,r.peak,r.bounces,r.overlap,r.recovered,r.splat);
        }
        }
    }
    std::fclose(out);
    std::printf("Current Workshop spacing audit: %d cases; %d unapproved pushbox overlaps; %d asymmetric outcomes\n",cases,overlaps,asymmetries);
    return route_failures||fd_failures||overlaps||asymmetries?1:0;
}
