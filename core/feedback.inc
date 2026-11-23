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
void Simulation::contact_cue(int p,int move,const Move& m,int kind,int facing,bool projectile,int serial,int impact_x,int impact_y) {
    const auto& target=world.players[1-p];
    // Locate the burst on the receiving body, at the height of the strike.
    // Weapon volume never becomes a hurt region. Throws use the torso.
    const int aim_x=projectile&&impact_x>=0?impact_x:target.x-facing*1800;
    int x=aim_x,y=target.y+8000;
    if(m.v[Category]!=Throw) {
        Fighter source=world.players[p];source.move=move;
        int distance=2147483647;
        for(int i=0;i<hurt_count(target,target.slow_held?0:1);++i) {
            const Box body=hurt_box(target,i,target.slow_held?0:1);
            const int aim_y=projectile&&impact_y>=0?impact_y:source.y+m.v[Bottom]+m.v[Height]/2;
            int cx=clamp(aim_x,body.left,body.right),cy=clamp(aim_y,body.bottom,body.top);
            int d=abs(cy-aim_y);
            if(!projectile)for(int b=0;b<attack_count(source,target,1);++b) {
                const Box hit=attack_box(source,target,b,1);
                const int left=max(body.left,hit.left),right=min(body.right,hit.right);
                const int bottom=max(body.bottom,hit.bottom),top=min(body.top,hit.top);
                if(left<right&&bottom<top){
                    // Prefer the intersecting body region nearest the strike's
                    // vertical center; the first listed hurtbox is usually legs.
                    int candidate_y=(bottom+top)/2;
                    int candidate_distance=abs(candidate_y-aim_y)-1000000;
                    if(candidate_distance<d){cx=(left+right)/2;cy=candidate_y;d=candidate_distance;}
                }
            }
            if(d<distance){distance=d;x=cx;y=cy;}
        }
    }
    emit_cue(kind,p,move,x,y,kind==CounterCue?max(m.v[AttackLevel],m.v[CounterTier]):m.v[AttackLevel],projectile?1:0,serial,facing);
}
