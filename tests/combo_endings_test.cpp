#include "../core/fight.h"
#include <cstdio>
#include <memory>
using namespace fight;
static int checks=0,failures=0;
#define CHECK(x) do {++checks;if(!(x)){++failures;std::fprintf(stderr,"Combo ending FAIL %d: %s\n",__LINE__,#x);}}while(0)

static void splat_consumes_bounces() {
    for(int c=0;c<CHARACTER_COUNT;++c)for(int p=0;p<2;++p)for(int side=0;side<2;++side) {
        auto s=std::make_unique<Simulation>();s->defaults();s->reset(p?c:2,p?2:c,0,0);
        auto& a=s->world.players[p];auto& b=s->world.players[1-p];
        const auto box=s->box(1-p,PushBox);const int half=(box.right-box.left)/2;
        const int edge=side?100000-half:half;
        const int facing=side?1:-1;
        b.x=edge;b.y=5000;b.reaction=AirReel;b.stun=15;
        a.x=edge-facing*8000;a.facing=facing;b.facing=-facing;
        s->world.wall_health[side]=0;
        // Smoke's actual c.S grants a ground bounce on an airborne contact.
        s->preview_begin(p,CLOSE_SLASH);a.age=s->moves[2][CLOSE_SLASH].v[Startup]-1;
        s->step(0,0);
        CHECK(a.contact_count==1&&b.bounce_ground>0);
        while(s->world.hitstop)s->step(0,0);
        s->step(0,0);
        CHECK(b.reaction==WallSplat);
        CHECK(b.bounce_ground==0&&b.bounce_wall==0);
        const auto saved=s->world;
        bool bounced=false,downed=false,free=false;
        for(int i=0;i<180;++i) {
            const int old_vy=b.vy;
            s->step(0,0);
            if(old_vy<0&&b.vy>0&&b.y==1)bounced=true;
            downed|=b.reaction==Downed;free|=downed&&b.reaction==Free;
        }
        CHECK(!bounced&&downed&&free);
        const auto checksum=s->checksum();s->world=saved;
        for(int i=0;i<180;++i)s->step(0,0);
        CHECK(s->checksum()==checksum);
    }
}
static void live_wall_bounce() {
    for(int c=0;c<CHARACTER_COUNT;++c)for(int p=0;p<2;++p)for(int side=0;side<2;++side) {
        auto s=std::make_unique<Simulation>();s->defaults();s->reset(c,c,0,0);
        auto& b=s->world.players[p];const auto box=s->box(p,PushBox);
        const int half=(box.right-box.left)/2;const int outward=side?1:-1;
        s->world.players[1-p].x=50000;
        b.x=side?100000-half:half;b.y=5000;b.reaction=AirReel;b.stun=30;
        b.vx=outward*200;b.bounce_wall=1200;b.bounce_ground=700;
        s->step(0,0);
        CHECK(b.reaction==AirReel&&b.vx==-outward*1200);
        CHECK(s->world.wall_health[side]==800&&b.bounce_wall==0&&b.bounce_ground==700);
    }
}
static void break_transition() {
    for(int c=0;c<CHARACTER_COUNT;++c)for(int p=0;p<2;++p)for(int side=0;side<2;++side) {
        auto s=std::make_unique<Simulation>();s->defaults();s->reset(p?c:2,p?2:c,0,0);
        auto& a=s->world.players[p];auto& b=s->world.players[1-p];
        const auto box=s->box(1-p,PushBox);const int half=(box.right-box.left)/2;
        const int facing=side?1:-1;
        b.x=side?100000-half:half;b.y=5000;b.reaction=AirReel;b.stun=15;
        a.x=b.x-facing*8000;a.facing=facing;b.facing=-facing;
        a.momentum=3000;b.momentum=4000;s->world.wall_health[side]=0;
        s->preview_begin(p,CLOSE_SLASH);a.age=s->moves[2][CLOSE_SLASH].v[Startup]-1;
        s->step(0,0);while(s->world.hitstop)s->step(0,0);s->step(0,0);
        CHECK(b.reaction==WallSplat);
        // A real Hs cancel follows the contact; wall-splatted targets cannot guard.
        const int defense=side?Right:Left;
        s->step(p?defense:Hs,p?Hs:defense);
        for(int i=0;i<60&&!s->world.wall_break_time;++i)s->step(p?defense:0,p?0:defense);
        CHECK(s->world.wall_break_time==s->rules.wall_break_frames);
        CHECK(s->world.wall_break_actor==p&&s->world.wall_break_side==facing);
        CHECK(a.combo==2&&b.health<900);
        const auto saved=s->world;
        for(int i=0;i<s->rules.wall_break_frames;++i)s->step(P|Dash,K|Dash);
        CHECK(s->world.wall_break_time==0&&s->world.stage==(side?1:2));
        CHECK(s->world.remaining==saved.remaining);
        CHECK(a.health==saved.players[p].health&&b.health==saved.players[1-p].health);
        CHECK(a.momentum==saved.players[p].momentum&&b.momentum==saved.players[1-p].momentum);
        CHECK(a.positive_time==s->rules.positive_frames&&a.reaction==Free&&b.reaction==Free);
        CHECK(a.move==-1&&b.move==-1&&a.combo==0&&b.combo_decay==0&&b.repeat_gravity==0);
        CHECK(b.bounce_ground==0&&b.bounce_wall==0&&b.vx==0&&b.vy==0);
        CHECK(s->world.wall_health[0]==s->rules.wall_threshold&&s->world.wall_health[1]==s->rules.wall_threshold);
        CHECK(a.x==(side?42000:58000)&&b.x==(side?58000:42000));
        const auto checksum=s->checksum();s->world=saved;
        for(int i=0;i<s->rules.wall_break_frames;++i)s->step(P|Dash,K|Dash);
        CHECK(s->checksum()==checksum);
    }
}
int main(){splat_consumes_bounces();live_wall_bounce();break_transition();std::printf("Combo endings: %d checks, %d failures\n",checks,failures);return failures?1:0;}
