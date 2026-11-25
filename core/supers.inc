// Confirmed strike supers own one immutable paired sequence. Utility clouds and
// waves retain ordinary projectile contact so the caster can use their cover.
void Simulation::start_super_pair(int p,int move,const Move& payload,int contact,bool combo,int reaction,int facing,int serial) {
    auto& f=world.players[p];auto& other=world.players[1-p];
    PairState pair{};
    pair.kind=SuperCapture;pair.owner=p;pair.move=move;pair.facing=facing;
    pair.origin_x=f.x;pair.victim_x=(other.x-f.x)*facing;pair.victim_y=other.y;
    pair.payload=payload;pair.combo=combo;pair.contact=contact;
    // Hit-key damage describes each block/armor pulse. A confirmed cinematic
    // pays the authored whole-move damage exactly once, at its finish.
    pair.payload.v[Damage]=moves[f.character][move].v[Damage];
    pair.serial=serial<0?f.attack_serial:serial;
    pair.down_pose=reaction;pair.wall_side=other.wall_side;
    pair.track=super_role(f.character,move);pair.ticks=max(24,payload.v[GrabFrames]);
    pair.release_freeze=22;pair.owner_recovery=24;pair.grace=rules.throw_grace_frames;
    if(pair.track==Exsanguinate&&other.bleed_source&&other.bleed_time) {
        pair.grey=min(150,other.grey_life);clear_owned_status(p);
    }
    clear_pair_motion(f,combo);clear_pair_motion(other,combo);
    f.reaction=other.reaction=Captured;f.last_move=move;
    f.attack_serial=pair.serial;
    for(auto& player:world.players)for(auto& h:player.history)h.consumed=INPUT_MASK;
    // Cinematics clear all outstanding contacts, including a projectile that
    // was already touching the owner on the successful confirmation frame.
    for(auto& q:world.projectiles)q.life=0;
    world.pair=pair;world.foreground_player=p;
    world.hitstop=max(world.hitstop,10);
    contact_cue(p,move,payload,contact==CounterHit?CounterCue:HitCue,facing,false,pair.serial);
}

void Simulation::tick_super_pair() {
    auto& p=world.pair;++p.clock;
    // Percent / owner X,Y / receiver X,Y. Root movement is fixed point and
    // authored independently of art; it never changes anatomical sprite scale.
    static constexpr int times[5]={0,18,45,78,100};
    static constexpr int tracks[12][5][4]={
        {}, // Sky Foundry retains its approved existing track.
        {{0,0,0,0},{2500,0,8500,0},{7000,0,12500,3000},{11000,0,18000,0},{12000,0,20000,0}},
        {{0,0,0,0},{1000,0,8500,0},{3000,0,14500,6000},{6000,0,23000,2000},{8000,0,26000,0}},
        {}, // Grand Design is an actionable utility wave.
        {{0,0,0,0},{0,0,6500,3000},{0,0,11000,15000},{0,0,15000,7000},{0,0,15000,0}},
        {}, // The Air Is Mine is an actionable utility cloud.
        {{0,0,0,0},{1000,0,6500,6000},{2000,0,7500,14000},{3500,0,10000,1000},{4000,0,10500,0}},
        {{0,0,0,0},{1000,0,7000,0},{3500,0,9500,1500},{6000,0,12000,0},{7000,0,14000,0}},
        {{0,0,0,0},{2000,0,10000,0},{5000,0,14000,6500},{10000,0,23000,4000},{12000,0,27000,0}},
        {{0,0,0,0},{0,0,5000,1000},{1500,0,0,9000},{2500,0,-8000,4500},{2500,0,-14000,0}},
        {{0,0,0,0},{1000,0,6500,0},{3000,0,9500,4000},{5000,0,11500,1000},{6000,0,13000,0}},
        {{0,0,0,0},{1000,0,6500,0},{2500,0,9000,2500},{5000,0,11500,0},{6000,0,13500,0}},
    };
    const int percent=min(100,p.clock*100/max(1,p.ticks));
    int segment=0;while(segment<3&&percent>times[segment+1])++segment;
    int position[4];
    for(int axis=0;axis<4;++axis) {
        int a=tracks[p.track][segment][axis],b=tracks[p.track][segment+1][axis];
        if(segment==0&&axis==2)a=p.victim_x;
        if(segment==0&&axis==3)a=p.victim_y;
        position[axis]=a+(b-a)*(percent-times[segment])/(times[segment+1]-times[segment]);
    }
    place_pair(p.owner,p.origin_x+p.facing*position[0],p.origin_x+p.facing*position[2],position[1],position[3]);
    // Authored impacts hold their own frame. There are no extra damage events,
    // scaling resets, cancels or inputs between these cinematic beats.
    if(p.clock==p.ticks*45/100||p.clock==p.ticks*78/100) {
        emit_cue(HitCue,p.owner,p.move,world.players[1-p.owner].x,world.players[1-p.owner].y+8000,4);
        world.hitstop=max(world.hitstop,5);
    }
    if(p.clock>=p.ticks)release_pair();
}

void Simulation::release_super_pair(const PairState& p) {
    auto& f=world.players[p.owner];auto& other=world.players[1-p.owner];
    f.reaction=other.reaction=Free;f.y=other.y=0;
    f.facing=f.x<=other.x?1:-1;other.facing=-f.facing;
    auto payload=p.payload;
    payload.v[Hitstop]=p.release_freeze;
    payload.v[Launch]=payload.v[AirLaunch]=payload.v[GroundBounce]=payload.v[WallBounce]=0;
    payload.v[GroundHitSpeed]=payload.v[AirHitSpeed]=payload.v[Pushback]=payload.v[AirPushback]=0;
    payload.v[PullFrames]=0;payload.v[Knockdown]=HardKnockdown;
    f.move=p.move;f.age=payload.v[Startup]-1+payload.v[Active];f.hit_done=f.contact=1;
    other.wall_side=p.wall_side;
    apply_contact(p.owner,p.move,payload,p.contact,p.combo,p.down_pose,f.facing,false,p.serial,-1,-1,nullptr,true);
    if(p.track==Bloodletting) {
        const int* c=character_extensions[f.character].v;
        other.bleed_source=14;other.bleed_time=c[CBleedDuration];other.bleed_clock=0;
        other.grey_life=min(min(c[CBleedCap],max(0,other.health-1)),max(other.grey_life,c[CBleedInitial]));
    }
    if(p.track==Exsanguinate&&p.grey>0) {
        const int paid=min(p.grey,other.health);other.health-=paid;f.last_damage+=paid;
    }
    if(p.track==LastOrders||p.track==WhiskeyChaser)f.stance=1;
    if(other.reaction==AirReel&&other.y<=1&&!world.wall_break_time)land(other);
    f.move=-1;f.pair_recovery=p.owner_recovery;
    f.teleported=other.teleported=1;
    for(auto& player:world.players)for(auto& h:player.history)h.consumed=INPUT_MASK;
}
