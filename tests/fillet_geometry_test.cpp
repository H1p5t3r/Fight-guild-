#include "../core/fight.h"
#include "fillet_geometry_reference.h"
#include <cstdio>
using namespace fight;
static Simulation sim;
static bool equal(Box actual,Box expected,const Fighter& f){
    Box world={f.x+(f.facing>0?expected.left:-expected.right),f.y+expected.bottom,f.x+(f.facing>0?expected.right:-expected.left),f.y+expected.top};
    return actual.left==world.left&&actual.right==world.right&&actual.bottom==world.bottom&&actual.top==world.top;
}
int main(){
    int failures=0,checks=0;sim.defaults();
    for(int player=0;player<2;++player)for(int facing=-1;facing<=1;facing+=2)for(const auto& row:REFERENCE_FRAMES){
        sim.reset(5,5,0,0);auto& f=sim.world.players[player];f.move=row.move;f.age=row.frame;f.facing=facing;f.y=sim.moves[5][row.move].v[Air]?20000:0;
        bool ok=sim.box_count(player,HurtBox)==row.hurt_count&&sim.box_count(player,HitBox)==row.hit_count;
        for(int i=0;i<row.hurt_count;++i)ok&=equal(sim.box(player,HurtBox,i),row.hurt[i],f);
        for(int i=0;i<row.hit_count;++i)ok&=equal(sim.box(player,HitBox,i),row.hit[i],f);
        ok&=equal(sim.box(player,PushBox),row.push,f);++checks;
        if(!ok){if(failures<15)std::fprintf(stderr,"Geometry mismatch: slot %d frame %d, player %d facing %d; hurt %d/%d hit %d/%d\n",row.move,row.frame,player,facing,sim.box_count(player,HurtBox),row.hurt_count,sim.box_count(player,HitBox),row.hit_count);++failures;}
    }
    std::printf("Fillet canonical geometry: %d checks, %d failures\n",checks,failures);return failures?1:0;
}
