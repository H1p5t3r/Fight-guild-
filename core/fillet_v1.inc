// Selected character policy, independent of sprites. Legacy saves opt out by
// leaving their extension tables empty. All clocks and interpolation are integer.
bool Simulation::has_bleed(const Fighter& f) const {
    const auto& target=world.players[1-(&f-world.players)];
    return target.bleed_source>0&&target.bleed_time>0;
}
int Simulation::voluntary_speed(const Fighter& f,int speed,bool air) const {
    return extended(f)&&has_bleed(f)?min(4000,speed*character_extensions[f.character].v[air?CAirSpeed:CGroundSpeed]/100):speed;
}
bool Simulation::named_route(int c,int from,int to,int route) const {
    const int* v=extensions[c][from].v;
    return (static_cast<unsigned>(v[XRoutes+route*2+to/32])&(1u<<(to%32)))!=0;
}
bool Simulation::passing(const Fighter& f) const {
    if(!extended(f)||f.move<0||f.stun||f.reaction!=Free) return false;
    const int* x=extension(f);int tick=f.age+1;
    if(x[XPassStart]>0&&tick>=x[XPassStart]&&tick<=x[XPassEnd])return true;
    for(int i=0;i<x[XRoot];++i){const int* key=x+XRoot+1+i*5;if(key[4]==1&&tick>=key[0]&&tick<=key[1])return true;}
    return false;
}
bool Simulation::lifted_action(const Fighter& f) const {
    return extended(f)&&f.move>=0&&extension(f)[XGroundedLift]&&f.reaction==Free&&!f.stun;
}
const int* Simulation::extended_body(const Fighter& f,int offset) const {
    if(!extended(f)) return nullptr;
    if(f.move>=0&&f.reaction==Free&&!f.stun&&!f.prejump_time&&!f.faultless) {
        const int* x=extension(f); const int* key=nullptr;
        for(int i=0;i<x[XHurt]&&x[XHurt+1+i*18]<=max(1,f.age+offset);++i) key=x+XHurt+2+i*18;
        if(key) return key;
    }
    int index=0;
    if(f.reaction==Downed) index=f.knockdown==HardKnockdown?34:35;
    else if(f.reaction==Waking) index=36+min(3,max(0,(f.wakeup_frames-f.recovery_time)*4/max(1,f.wakeup_frames-1)));
    else if(f.reaction!=Free||(f.stun&&!f.guarding)) index=3;
    else if(f.prejump_time) index=41;
    else if(f.dash&&f.dash_air) index=f.dash_pause?42:43;
    else if(f.landing_time) index=44;
    else if(f.y>0) index=2;
    else if(f.guarding) index=(f.raw&Down)?1:28+min(5,(f.block_reaction-1)*2+(f.block_age>=4));
    else if(f.raw&Down) index=1;
    else if(f.dash) index=40;
    else if(f.running) index=20+f.gait_phase;
    else if(f.vx) index=(f.vx*f.facing<0?12:4)+f.gait_phase;
    return character_extensions[f.character].v+CProfiles+index*17;
}
void Simulation::clear_pair_motion(Fighter& f,bool keep_combo) {
    f.move=-1; f.age=f.stun=f.contact=f.hit_done=f.dash=f.dash_pause=f.running=0;
    f.vx=f.vy=f.carry_vx=f.carry_time=f.knockback_left=f.prejump_time=f.landing_time=0;
    f.slow_time=f.slow_phase=f.slow_held=f.guarding=f.faultless=f.guard_break=0;
    f.block_reaction=f.block_age=f.block_advantage=0;
    f.knockdown=f.down_frames=f.wakeup_frames=f.recovery_time=f.wall_time=f.wall_side=0;
    if(!keep_combo) {
        f.combo=f.combo_display=f.combo_time=f.combo_age=f.combo_received=f.repeat_gravity=0;
        f.combo_proration=f.combo_scale=100;for(auto& uses:f.move_uses)uses=0;
        clear_combo_physics(f);
    }
    f.pull_time=f.grab_time=f.legacy_throw_gate_paid=0;f.pull_owner=f.grab_owner=-1;f.armor_left=f.carried_armor=0;
    f.bounce_ground=f.bounce_wall=f.crumple_time=f.root_y=f.coast_pending=f.coast_mode=0;
    f.pair_recovery=f.pair_grace_pending=f.throw_grace=f.air_action=f.air_dash_used=f.air_jump_used=0;
    f.display_move=-1;
}
void Simulation::place_pair(int owner,int ax,int bx,int ay,int by) {
    auto& a=world.players[owner];auto& b=world.players[1-owner];
    int ah=extended(a)?character_extensions[a.character].v[CHalfWidth]:PUSH_PROFILES[a.character].half_width;
    int bh=extended(b)?character_extensions[b.character].v[CHalfWidth]:PUSH_PROFILES[b.character].half_width;
    int shift=max(0,max(ah-ax,bh-bx));ax+=shift;bx+=shift;
    shift=max(0,max(ax+ah-100000,bx+bh-100000));ax-=shift;bx-=shift;
    a.x=ax;b.x=bx;a.y=ay;b.y=by;
}
bool Simulation::capture_eligible(const Fighter& f,const Fighter& target,int kind) const {
    if(world.pair.kind||(f.y>0&&!(kind==5&&f.variant==2&&f.y<=8000))||f.prejump_time||f.stun||f.reaction!=Free) return false;
    if(kind==AntiAirCapture) {
        // Airborne opponents are throwable both in neutral and during a juggle.
        // Prejump and grounded targets are never caught by the anti-air super.
        if(target.y<=0||target.prejump_time||target.pair_recovery||target.grab_time||target.throw_grace
           ||(target.reaction!=Free&&target.reaction!=AirReel))return false;
        return (target.x-f.x)*f.facing>=0&&overlaps(f,target);
    }
    if(kind==WoundCapture) return !has_bleed(f)&&target.y==0&&target.reaction==Downed&&target.recovery_time>0&&overlaps(f,target);
    if(target.y>0||target.prejump_time||(target.stun&&!(kind!=CommandCapture&&target.guard_break&&target.guarding))||target.reaction!=Free||(!target.guard_break&&target.throw_grace)
       ||target.landing_time||target.pair_recovery||target.grab_time||semi_airborne(target)) return false;
    if(kind==CommandCapture&&(!has_bleed(f)||f.capture_failed)) return false;
    Box a=push_box(f),b=push_box(target);
    int gap=(a.right-a.left+b.right-b.left)/2+effective_move(f).v[ThrowRange];
    return (target.x-f.x)*f.facing>=0&&abs(target.x-f.x)<=gap;
}
bool Simulation::tech_input(Fighter& f) {
    for(int tick=world.frame;tick>=max(0,world.frame-rules.buffer+1);--tick) {
        auto* h=sample(f,tick);if(!h)continue;
        if((h->held&(P|K|S|Hs|D))!=(P|K)||(h->consumed&(P|K))||!(h->pressed&(P|K)))continue;
        h->consumed|=P|K;return true;
    }
    return false;
}
void Simulation::start_pair(int p,int kind,const Move& payload) {
    auto& f=world.players[p];auto& other=world.players[1-p];
    PairState pair{};pair.kind=kind;pair.owner=p;pair.move=f.move;pair.facing=f.facing;
    pair.origin_x=f.x;pair.victim_x=(other.x-f.x)*f.facing;pair.saved_age=f.age+1;pair.payload=payload;
    pair.victim_y=other.y;
    pair.combo=kind==AntiAirCapture&&(other.stun>0||other.reaction==AirReel);
    pair.down_pose=other.knockdown;const int* x=extension(f);
    int freeze=payload.v[Hitstop];
    if(kind==LegacyCapture) {
        pair.tech_ticks=6;
        // Ordinary one-stage throws may author a longer grip with GrabFrames.
        // Tapper already owns a second capture stage, so only pay his tech gate
        // here. Zero retains the six-tick behavior of older saved move data.
        pair.ticks=payload.v[ActionType]==4?6:max(6,payload.v[GrabFrames]);
    }
    else {
        freeze=x[XCaptureFreeze];pair.ticks=x[XPairTicks];pair.release_freeze=x[XReleaseFreeze];
        pair.owner_recovery=x[XOwnerRecovery];pair.victim_recovery=x[XVictimRecovery];pair.grace=x[XThrowGrace];
        pair.track=x[XPairTrack];pair.tech_ticks=x[XTechTicks];
    }
    if(kind==CommandCapture) { pair.grey=other.grey_life;clear_owned_status(p);clear_owned_status(1-p); }
    // Preserve the defender's fresh tech chord, but consume all other old actions.
    for(int i=0;i<2;++i) for(auto& h:world.players[i].history) {
        bool tech=i!=p&&pair.tech_ticks&&(h.held&(P|K|S|Hs|D))==(P|K)&&!(h.consumed&(P|K));
        h.consumed|=h.pressed&~(tech?(P|K):0);
    }
    clear_pair_motion(f,pair.combo);clear_pair_motion(other,pair.combo);
    f.reaction=other.reaction=Captured;f.last_move=pair.move;
    world.pair=pair;world.hitstop=max(world.hitstop,freeze);
}
void Simulation::tech_pair() {
    const int order=world.players[0].x<=world.players[1].x?1:-1;
    const int middle=(world.players[0].x+world.players[1].x)/2;
    for(auto& f:world.players) {
        clear_pair_motion(f);f.reaction=Free;f.pair_recovery=12;f.pair_grace_pending=5;
        for(auto& h:f.history)h.consumed|=h.pressed;
    }
    place_pair(0,middle-order*6000,middle+order*6000);
    world.players[0].facing=order;world.players[1].facing=-order;
    world.pair={};world.hitstop=max(world.hitstop,6);
}
bool Simulation::tick_pair() {
    auto& pair=world.pair;if(!pair.kind)return false;
    auto& f=world.players[pair.owner];auto& other=world.players[1-pair.owner];
    ++pair.clock;
    if(pair.clock<=pair.tech_ticks&&tech_input(other)) { tech_pair();return true; }
    if(pair.kind==NormalCapture&&pair.clock==pair.tech_ticks+1)clear_owned_status(1-pair.owner);
    if(pair.kind!=LegacyCapture) {
        const int* track=character_extensions[f.character].v+CPairTracks+pair.track*41;
        const int* left=track+1;const int* right=left;
        for(int i=1;i<track[0];++i) {right=track+1+i*5;if(right[0]>=pair.clock)break;left=right;}
        int positions[4];
        for(int i=0;i<4;++i) {
            int a=left[1+i],b=right[1+i];
            if(left[0]==0&&i==2)a=pair.victim_x;
            if(left[0]==0&&i==3)a=pair.victim_y;
            positions[i]=left==right?a:a+(b-a)*(pair.clock-left[0])/max(1,right[0]-left[0]);
        }
        place_pair(pair.owner,pair.origin_x+pair.facing*positions[0],pair.origin_x+pair.facing*positions[2],positions[1],positions[3]);
    }
    if(pair.clock>=pair.ticks)release_pair();
    return true;
}
void Simulation::release_pair() {
    const PairState pair=world.pair;world.pair={};
    if(pair.kind!=LegacyCapture&&pair.kind!=WoundCapture&&pair.kind!=GrapplerCapture&&pair.kind!=AntiAirCapture)
        contact_cue(pair.owner,pair.move,pair.payload,HitCue,pair.facing,false,-1);
    auto& f=world.players[pair.owner];auto& other=world.players[1-pair.owner];
    f.reaction=other.reaction=Free;
    if(pair.kind==LegacyCapture) {
        clear_owned_status(1-pair.owner);
        f.move=pair.move;f.age=pair.saved_age-1;f.hit_done=f.contact=1;
        auto payload=pair.payload;payload.v[Hitstop]=0;
        f.legacy_throw_gate_paid=payload.v[ActionType]==4&&payload.v[GrabFrames]>0;
        apply_contact(pair.owner,pair.move,payload,NormalHit,false,Free,pair.facing,false);
        ++f.age;if(f.age>=payload.v[Startup]-1+payload.v[Active]+payload.v[Recovery])f.move=-1;
        return;
    }
    f.y=other.y=0;f.facing=f.x<=other.x?1:-1;other.facing=-f.facing;
    const int gap=extensions[f.character][pair.move].v[XReleaseGap],middle=(f.x+other.x)/2;
    place_pair(pair.owner,middle-f.facing*(gap/2),middle+f.facing*(gap-gap/2));
    if(pair.kind==GrapplerCapture||pair.kind==AntiAirCapture) {
        // The authored root track already chooses the throw side. Pay damage
        // once, at the slam, through the usual scaling/knockdown/feedback path.
        auto payload=pair.payload;payload.v[Hitstop]=pair.release_freeze;
        payload.v[Pushback]=payload.v[AirPushback]=0;payload.v[Direction]=5;
        payload.v[Launch]=payload.v[AirLaunch]=0;
        f.move=pair.move;f.age=payload.v[Startup]-1+payload.v[Active];
        f.hit_done=f.contact=1;
        apply_contact(pair.owner,pair.move,payload,NormalHit,pair.combo,Free,f.facing,false);
        if(other.reaction==AirReel&&other.y<=1)land(other);
        f.move=-1;f.pair_recovery=pair.owner_recovery;
        f.teleported=other.teleported=1;
        return;
    }
    f.pair_recovery=pair.owner_recovery;other.pair_recovery=pair.victim_recovery;
    if(other.pair_recovery)other.pair_grace_pending=pair.grace;else other.throw_grace=pair.grace;
    if(pair.kind==WoundCapture) {
        const int* c=character_extensions[f.character].v;
        other.bleed_source=pair.move+1;other.bleed_time=c[CBleedDuration];other.bleed_clock=0;
        other.grey_life=min(min(c[CBleedCap],max(0,other.health-1)),c[CBleedInitial]);
    } else {
        clear_owned_status(1-pair.owner);
        const int base=pair.payload.v[Damage],damage=base+pair.grey;
        other.health=max(0,other.health-damage);f.last_damage=damage;f.last_base_damage=base;f.damage_scale=100;
        f.event=NormalHit;f.contact_count=(f.contact_count+1)%100000000;f.contact_ticks=0;
        gain_momentum(f,base*rules.attack_gain);gain_momentum(other,base*rules.damage_gain);
        world.foreground_player=pair.owner;
        if(other.bleed_source)other.grey_life=min(other.grey_life,max(0,other.health-1));
    }
    world.hitstop=max(world.hitstop,pair.release_freeze);
}
