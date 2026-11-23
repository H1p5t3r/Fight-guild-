// Cosmetic events only; never write simulation state from this file.
int Simulation::cue_get(int index,int field) const {
    return index>=0&&index<cue_count&&field>=0&&field<CUE_FIELDS?cues[index].v[field]:0;
}
void Simulation::emit_cue(int kind,int p,int move,int x,int y,int strength,int flags,int serial,int facing) {
    if(cue_count>=MAX_CUES)return;
    const auto& f=world.players[p];
    cues[cue_count++]={{world.frame,kind,p,f.character,move,serial<0?f.attack_serial:serial,
        x,y,facing?facing:f.facing,clamp(strength,0,4),flags,f.variant}};
}
static int region_flags(int region) { return region==0?CueLegs:region==2?CueHead:CueChest; }
ContactVisual Simulation::contact_visual(const Fighter& source,const Fighter& target,const Move& m) const {
    // Choose an actual intersected body region, nearest the active strike's
    // center. Hit level (low/mid/high) is a guard rule, not an anatomical region.
    ContactVisual result={target.x-source.facing*1800,target.y+8000,CueChest|(target.y>0?CueAirborne:0)};
    if(m.v[Category]!=Throw) {
        int distance=2147483647;
        for(int i=0;i<hurt_count(target,target.slow_held?0:1);++i) {
            const Box body=hurt_box(target,i,target.slow_held?0:1);
            for(int b=0;b<attack_count(source,target,1);++b) {
                const Box hit=attack_box(source,target,b,1);
                const int left=max(body.left,hit.left),right=min(body.right,hit.right);
                const int bottom=max(body.bottom,hit.bottom),top=min(body.top,hit.top);
                if(left<right&&bottom<top){
                    const int d=abs((bottom+top)/2-(hit.bottom+hit.top)/2);
                    if(d<distance){
                        distance=d;result.x=(left+right)/2;result.y=(bottom+top)/2;
                        result.flags=region_flags(hurt_region(target,i,target.slow_held?0:1))|(target.y>0?CueAirborne:0);
                    }
                }
            }
        }
    }
    return result;
}
void Simulation::contact_cue(int p,int move,const Move& m,int kind,int facing,bool projectile,int serial,int impact_x,int impact_y,const ContactVisual* visual) {
    Fighter source=world.players[p];source.move=move;source.facing=facing;
    ContactVisual result=visual?*visual:contact_visual(source,world.players[1-p],m);
    if(projectile&&!visual){if(impact_x>=0)result.x=impact_x;if(impact_y>=0)result.y=impact_y;}
    emit_cue(kind,p,move,result.x,result.y,kind==CounterCue?max(m.v[AttackLevel],m.v[CounterTier]):m.v[AttackLevel],result.flags|(projectile?CueProjectile:0),serial,facing);
}
