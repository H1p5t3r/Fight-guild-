#include "fight.h"
#include "combat_data.h"

namespace fight {
static_assert(sizeof(int)==4, "The snapshot ABI requires 32-bit int");
Simulation default_simulation{};
State& world=default_simulation.world;
Move (&moves)[CHARACTER_COUNT][MOVE_COUNT]=default_simulation.moves;
Rules& rules=default_simulation.rules;
static int min(int a,int b) { return a<b?a:b; }
static int max(int a,int b) { return a>b?a:b; }
static int clamp(int v,int lo,int hi) { return max(lo,min(v,hi)); }
static int abs(int v) { return v<0?-v:v; }
static int button_bit(int b) { return P<<b; }

void Simulation::defaults() {
    rules=Rules{};
    for(int c=0;c<CHARACTER_COUNT;++c) for(int i=0;i<MOVE_COUNT;++i) {
        moves[c][i]=STARTER_MOVES[c][i];
        move_hit[c][i]=STARTER_HITS[c][i];
        for(int p=0;p<HURT_PHASES;++p) move_hurt[c][i][p]=MoveHurt{};
    }
    for(int c=0;c<CHARACTER_COUNT;++c) mobility[c]=STARTER_MOBILITY[c];
}

void Simulation::reset(int c0,int c1,int s0,int s1) {
    world=State{};
    world.remaining=99*60;
    world.winner=-1;
    world.wall_break_actor=-1;
    world.wall_health[0]=world.wall_health[1]=rules.wall_threshold;
    for(int p=0;p<2;++p) {
        Fighter& f=world.players[p];
        f.character=clamp(p?c1:c0,0,CHARACTER_COUNT-1);
        f.simple=(p?s1:s0)!=0;
        f.x=p?58000:42000;
        f.facing=p?-1:1;
        f.health=1000;
        f.move=f.last_move=-1;
        f.pull_owner=f.grab_owner=-1;
        f.combo_proration=f.combo_scale=f.damage_scale=100; f.input_age=-1;
        for(auto& h:f.history) { h.frame=-1000; h.direction=5; }
    }
}

bool cancel_allowed(const Move& from,const Move& to,bool same,bool contact) {
    if(!from.v[Enabled]||!to.v[Enabled]||to.v[FollowFrom]>=0||to.v[FollowFrom2]>=0) return false;
    // Universal throws start from neutral, never as an unblockable gatling.
    if(to.v[Category]==Throw) return false;
    if((!contact&&!from.v[WhiffCancel])||(same&&!from.v[SelfCancel])) return false;
    // The universal same-button exception applies to ALL attack categories.
    if(to.v[Category]==Command && from.v[Button]==to.v[Button]) return true;
    if(to.v[Category]==Special||to.v[Category]==Drive) return from.v[SpecialCancel]!=0;
    const bool normal=from.v[Category]==Normal||from.v[Category]==Command;
    if(to.v[Category]==Command) {
        int mask=from.v[CommandRoutes];
        return mask>=0 ? (mask&(1<<to.v[Button]))!=0
            : normal&&(from.v[Button]==1||from.v[Button]==2||from.v[Button]==3);
    }
    int mask=from.v[NormalRoutes];
    if(mask>=0) return (mask&(1<<to.v[Button]))!=0;
    return normal&&((from.v[Button]==0&&(to.v[Button]==0||to.v[Button]==1))
                 ||(from.v[Button]==2&&to.v[Button]==3));
}

static int direction(int raw,int facing) {
    int x=((raw&Right)!=0)-((raw&Left)!=0);
    int y=((raw&Up)!=0)-((raw&Down)!=0);
    return 5+x*facing+y*3; // SOCD: opposite directions neutralize.
}
bool Simulation::faultless_requested(const Fighter& f) const {
    int horizontal=((f.raw&Right)!=0)-((f.raw&Left)!=0);
    if(horizontal*f.facing!=-1) return false;
    int buttons=f.raw&(P|K|S|Hs);
    // Grounded 4P+K belongs to back throw. FD remains on the macro or other pairs.
    if((f.y==0||moves[f.character][AIR_BACK_THROW].v[Enabled])&&direction(f.raw,f.facing)==4&&buttons==(P|K)&&!(f.raw&Faultless)) return false;
    return (f.raw&Faultless)||(buttons&&(buttons&(buttons-1)));
}
void Simulation::gain_momentum(Fighter& f,int amount) {
    if(f.faultless||amount<=0) return;
    if(f.positive_time>0) amount=amount*rules.positive_gain_percent/100;
    f.momentum=min(MOMENTUM_MAX,f.momentum+amount);
}
void Simulation::update_faultless(Fighter& f) {
    bool request=faultless_requested(f);
    f.faultless=request&&!f.stance&&mobility[f.character].v[FdEnabled]&&f.momentum>0&&f.move<0&&f.reaction==Free&&!f.landing_time&&!f.prejump_time&&(f.stun==0||f.guarding);
    // Reserve the chord even with an empty meter: it falls back to ordinary guard.
    // It cannot become a buffered attack, dash or jump when the shield is released.
    if(request) f.history[world.frame%HISTORY].consumed|=P|K|S|Hs|D|Dash|Up;
    if(f.faultless) f.momentum=max(0,f.momentum-mobility_or(f,f.y>0?FdAirDrain:FdDrain,f.y>0?rules.fd_air_drain:rules.fd_drain));
}
static Sample* sample(Fighter& f,int frame) {
    if(frame<0) return nullptr;
    Sample& h=f.history[frame%HISTORY];
    return h.frame==frame?&h:nullptr;
}
static const Sample* sample(const Fighter& f,int frame) {
    if(frame<0) return nullptr;
    const Sample& h=f.history[frame%HISTORY];
    return h.frame==frame?&h:nullptr;
}

bool Simulation::stance_allowed(const Fighter& f,const Move& m) const {
    return !m.v[StanceRequired]||(m.v[StanceRequired]==1?!f.stance:f.stance!=0);
}
bool Simulation::semi_airborne(const Fighter& f) const {
    if(f.move<0) return false;
    const auto& m=moves[f.character][f.move]; int tick=f.age+1;
    return m.v[SemiAirStart]>0&&tick>=m.v[SemiAirStart]&&tick<=m.v[SemiAirEnd];
}
bool Simulation::guard_point(const Fighter& f,const Move& incoming) const {
    if(f.stance||f.move<0||f.stun||f.reaction!=Free) return false;
    const auto& m=moves[f.character][f.move];
    return m.v[ActionType]==1&&f.age+1>=m.v[Startup]&&f.age<m.v[Startup]-1+m.v[Active]
        &&incoming.v[Category]!=Throw&&incoming.v[HitLevel]!=1;
}
bool Simulation::motion_matches(const Fighter& f,int at,int motion) const {
    if(!motion) return true;
    const int sequence[3]={motion/100,(motion/10)%10,motion%10};
    int next=2, last=at;
    // Require exact direction transitions; neutral may separate transitions.
    for(int n=at;n>=0&&at-n<rules.motion_window;--n) {
        const Sample* h=sample(f,n);
        if(!h||last-n>rules.motion_gap) return false;
        if(h->direction==sequence[next]) {
            last=n;
            if(--next<0) return true;
        }
    }
    return false;
}

static bool dir_matches(int want,int got) {
    if(want==2) return got>=1&&got<=3;
    if(want==6) return got==6||got==3||got==9;
    return want==got;
}
int Simulation::requested(Fighter& f,Sample& h) const {
    const int presses=h.pressed&~h.consumed;
    const bool throw_chord=!f.stance&&(h.held&(P|K|S|Hs|D))==(P|K)
        &&(presses&(P|K))&&!(h.consumed&(P|K))&&!(h.held&(Simple|Faultless))
        &&(h.direction==4||h.direction==6);
    if(throw_chord) {
        int slot=f.y>0?(h.direction==4?AIR_BACK_THROW:AIR_FORWARD_THROW):(h.direction==4?BACK_THROW:FORWARD_THROW);
        return moves[f.character][slot].v[Enabled]&&stance_allowed(f,moves[f.character][slot])?slot:-1;
    }
    int best=-1,best_priority=-1;
    bool simplified=f.simple&&(h.held&Simple);
    for(int i=0;i<MOVE_COUNT;++i) {
        const Move& m=moves[f.character][i];
        if(!m.v[Enabled]||!stance_allowed(f,m)||m.v[ActionType]==1||(m.v[Category]==Throw&&!m.v[Motion])) continue;
        if(i==CLOSE_SLASH||i==GUARD_ATTACK||i==CHARGED_HS||i==CHARGED_D) continue;
        if(m.v[Air]!=(f.y>0)) continue;
        int priority=0;
        if(m.v[FollowFrom]>=0||m.v[FollowFrom2]>=0) {
            if(f.move<0||(f.move!=m.v[FollowFrom]&&f.move!=m.v[FollowFrom2])) continue;
            if(!(presses&button_bit(m.v[Button]))) continue;
            if(m.v[Direction]!=5&&!((m.v[Direction]==2&&dir_matches(2,h.direction))||h.direction==m.v[Direction])) continue;
            if(m.v[FollowHit]&&(!f.contact||f.event==Blocked)) continue;
            priority=1000+(m.v[Direction]==2?10:0);
        } else if(simplified) {
            if(!m.v[SimpleDirection]||!(presses&button_bit(m.v[SimpleButton]))
               ||h.direction!=m.v[SimpleDirection]) continue;
            priority=50+m.v[Button];
        } else {
            if(!(presses&button_bit(m.v[Button]))) continue;
            if((i==SWEEP||m.v[ActionType]==2)&&dir_matches(2,h.direction)) priority=45;
            else if(i==SWEEP||m.v[ActionType]==2) continue;
            else if(m.v[Motion]) {
                if(!motion_matches(f,h.frame,m.v[Motion])) continue;
                priority=m.v[Motion]==623?40:30;
            } else if(m.v[Category]==Command) {
                if(!dir_matches(m.v[Direction],h.direction)) continue;
                priority=20;
            } else if(m.v[Direction]==2) {
                if(!dir_matches(2,h.direction)) continue;
                priority=10;
            } else priority=1;
            priority=priority*8+m.v[Button];
        }
        if(priority>best_priority) { best=i; best_priority=priority; }
    }
    if(best>=0) {
        const auto& m=moves[f.character][best]; int close=m.v[ProximityMove];
        const auto& other=world.players[1-(&f-world.players)];
        if(close>=0&&close<MOVE_COUNT&&moves[f.character][close].v[Enabled]
           &&stance_allowed(f,moves[f.character][close])&&abs(other.x-f.x)<=m.v[ProximityRange]) best=close;
    }
    return best;
}
Move Simulation::effective_move(const Fighter& f) const {
    Move m=moves[f.character][f.move];
    // Charge anticipation stays vulnerable and has no active box before release.
    // The elapsed integer age is also the charge timer, so rollback needs no clock.
    if(m.v[ActionType]==5&&f.guard_button) m.v[Startup]=max(m.v[Startup],f.age+2);
    if(!f.variant) return m;
    m.v[Startup]=m.v[VariantStartup]; m.v[Active]=m.v[VariantActive]; m.v[Recovery]=m.v[VariantRecovery];
    m.v[Category]=f.variant==2?Throw:Drive;
    m.v[Damage]=f.variant==2?m.v[VariantDamage]:0;
    m.v[Hitstun]=m.v[VariantHitstun]; m.v[ThrowRange]=m.v[VariantRange];
    m.v[Knockdown]=m.v[VariantKnockdown];
    m.v[Launch]=m.v[AirLaunch]=0;
    m.v[SpecialCancel]=m.v[JumpCancel]=m.v[WhiffCancel]=m.v[SelfCancel]=0;
    m.v[NormalRoutes]=m.v[CommandRoutes]=0;
    m.v[ProjectileKind]=m.v[HitAngle]=m.v[PullFrames]=m.v[TravelSpeed]=m.v[GuardBreak]=0;
    m.v[Direction]=5; // A cash-out never inherits back-throw side switching.
    return m;
}
void Simulation::clear_owned_status(int owner) {
    auto& target=world.players[1-owner];
    target.tether_source=target.tether_used=0;
    target.bleed_source=target.bleed_time=target.bleed_clock=target.grey_life=0;
}
void Simulation::tick_statuses() {
    for(int p=0;p<2;++p) {
        auto& target=world.players[p];
        if(!target.bleed_source) continue;
        const auto& m=moves[world.players[1-p].character][target.bleed_source-1];
        if(--target.bleed_time<=0) {
            target.bleed_source=target.bleed_time=target.bleed_clock=target.grey_life=0;
            continue;
        }
        if(++target.bleed_clock>=m.v[BleedTickFrames]) {
            target.bleed_clock=0;
            target.grey_life=min(min(m.v[BleedCap],max(0,target.health-1)),target.grey_life+m.v[BleedTickDamage]);
        }
    }
}
void Simulation::trigger_tether(Fighter& f) {
    if(f.variant!=1||f.hit_done||!active(f)) return;
    f.hit_done=1;
    int p=&f-world.players;
    auto& target=world.players[1-p];
    if(!target.tether_source||target.tether_used) return;
    const auto& m=moves[f.character][f.move];
    target.tether_used=1;
    // Aim once toward the owner's current position, using deterministic integer math.
    int dx=f.x-target.x,dy=f.y-target.y,den=max(1,max(abs(dx),abs(dy)));
    target.vx=m.v[TetherSpeed]*dx/den;
    target.vy=m.v[TetherSpeed]*dy/den;
    target.knockback_left=abs(target.vx)*m.v[TetherFrames];
    target.stun=m.v[TetherFrames];
    if(target.vy>0) target.y=max(1,target.y);
    target.reaction=target.y>0?AirReel:Free;
    target.move=-1; target.dash=target.dash_pause=target.running=target.guarding=target.faultless=0;
    target.guard_break=target.block_reaction=target.throw_grace=target.prejump_time=target.landing_time=0;
    target.knockdown=target.down_frames=target.wakeup_frames=target.recovery_time=0;
    target.pull_time=0; target.pull_owner=-1;
    target.carry_vx=target.carry_time=0;
}
void Simulation::begin(Fighter& f,int move) {
    const auto& target=world.players[1-(&f-world.players)];
    int mechanic=moves[f.character][move].v[Mechanic];
    f.variant=mechanic==1&&target.tether_source?1:mechanic==2&&target.bleed_source?2:0;
    f.move=f.last_move=move;
    f.armor_left=moves[f.character][move].v[ArmorHits];
    if(moves[f.character][move].v[StanceChange]==2) f.stance=0;
    f.guard_button=0;
    if(moves[f.character][move].v[ActionType]==1) f.guard_button=button_bit(moves[f.character][move].v[HoldButton]);
    if(moves[f.character][move].v[ActionType]==5) f.guard_button=button_bit(moves[f.character][move].v[Button]);
    f.age=f.contact=f.hit_done=f.dash=f.dash_pause=0;
    f.projectile_spawned=0; f.attack_serial=(f.attack_serial+1)%100000000;
    f.hit_groups=0;
    f.running=0;
    if(moves[f.character][move].v[Air]) f.air_action=1;
    // Briefly retain run/step momentum while directions form a motion command.
    // Consume it once; later gatlings carry the attack's remaining velocity.
    if(f.carry_time>0&&abs(f.carry_vx)>abs(f.vx)) f.vx=f.carry_vx;
    f.carry_vx=f.carry_time=0;
    f.vx=clamp(f.vx*moves[f.character][move].v[InertiaPercent]/100,-4000,4000);
    if(moves[f.character][move].v[ActionType]==6) { f.vx/=3; f.vy=0; }
    if(!f.variant) f.x+=moves[f.character][move].v[Advance]*f.facing;
    if(f.variant==2&&moves[f.character][move].v[VariantLift]>0) {
        f.y=max(1,f.y); f.vy=moves[f.character][move].v[VariantLift];
    }
    int kind=moves[f.character][move].v[Category];
    if(kind==Special||kind==Drive) gain_momentum(f,rules.special_gain);
}
bool Simulation::active(const Fighter& f) const {
    if(f.move<0) return false;
    const Move& m=effective_move(f);
    return f.age+1>=m.v[Startup]&&((m.v[ActionType]==3&&f.y>0)||f.age+1<m.v[Startup]+m.v[Active]);
}
bool Simulation::double_forward(const Fighter& f,const Sample& h,int want) const {
    const int forward=(f.facing==1)==(want==6)?Right:Left;
    if(h.direction!=want||!(h.pressed&forward)||(h.consumed&forward)) return false;
    for(int n=h.frame-1;n>=max(0,h.frame-10);--n) {
        const Sample* old=sample(f,n);
        if(old&&old->direction==want&&(old->pressed&forward)&&!(old->consumed&forward)) return true;
    }
    return false;
}
void Simulation::control(Fighter& f) {
    if(f.grab_time>0||f.reaction==Captured) { f.vx=f.running=f.dash=f.dash_pause=0; return; }
    if(f.reaction==Crumpled) {
        f.vx=0; f.y=500; f.vy=0;
        if(--f.crumple_time<=0) { f.reaction=Free; f.y=f.stun=0; f.throw_grace=rules.throw_grace_frames; }
        return;
    }
    if(f.move>=0&&f.reaction==Free&&!f.stun) {
        const auto& m=moves[f.character][f.move];
        if(m.v[ActionType]==5&&f.guard_button) {
            const int target=m.v[HoldFollow];
            const bool full=f.age+1>=max(m.v[Startup],m.v[HoldFrame]);
            if(!(f.raw&f.guard_button)||full) {
                if(full&&(f.raw&f.guard_button)&&target>=0&&target!=f.move&&moves[f.character][target].v[Enabled]&&stance_allowed(f,moves[f.character][target])) {
                    const int momentum=f.momentum;
                    begin(f,target);
                    f.momentum=momentum; // One held input is one move, not two meter-gain events.
                    f.age=moves[f.character][target].v[Startup]-1;
                } else f.age=min(f.age,m.v[Startup]-1);
                f.guard_button=0;
            }
        }
        else if(m.v[ActionType]!=5&&m.v[HoldFollow]>=0&&moves[f.character][m.v[HoldFollow]].v[Enabled]&&stance_allowed(f,moves[f.character][m.v[HoldFollow]])&&m.v[HoldFrame]>0&&f.age+1>=m.v[HoldFrame]&&(f.raw&button_bit(m.v[Button]))) {
            int held=button_bit(m.v[Button]); begin(f,m.v[HoldFollow]); f.guard_button=held;
        }
        const auto& current=moves[f.character][f.move];
        if(current.v[ActionType]==1) {
            f.vx=0;
            if(f.age<current.v[Startup]-1+current.v[Active]) {
                const int opposite=f.guard_button==S?Hs:S;
                auto& h=f.history[world.frame%HISTORY];
                if(f.age>=current.v[Startup]-1&&(h.pressed&opposite)&&current.v[GuardFollow]>=0&&moves[f.character][current.v[GuardFollow]].v[Enabled]&&stance_allowed(f,moves[f.character][current.v[GuardFollow]])) { begin(f,current.v[GuardFollow]); h.consumed|=opposite; }
                else if(!(f.raw&f.guard_button)) f.age=current.v[Startup]-1+current.v[Active];
                else if(f.age>=current.v[Startup]-1) f.age=current.v[Startup]-1;
            }
            return;
        }
    }
    if(f.landing_time>0) {
        --f.landing_time; f.vx=f.running=f.dash=f.dash_pause=0;
        f.carry_vx=f.carry_time=0;
        return;
    }
    if(f.reaction!=Free) {
        if(f.reaction!=AirReel) f.vx=f.knockback_left=0;
        f.running=f.dash=f.dash_pause=0;
        f.carry_vx=f.carry_time=0;
        f.reversal_ready=1;
        f.stun=max(0,f.stun-1);
        if(f.reaction==WallSplat) {
            if(--f.wall_time<=0) {
                f.reaction=AirReel; f.knockdown=SoftKnockdown;
                f.down_frames=6; f.wakeup_frames=8; f.vy=0;
                // Wall health belongs to the wall and stays depleted after a missed follow-up.
            }
        } else if(f.reaction==Downed||f.reaction==Waking) {
            if(--f.recovery_time<=0) {
                if(f.reaction==Downed&&f.wakeup_frames>0) {
                    f.reaction=Waking; f.recovery_time=f.wakeup_frames;
                } else {
                    f.reaction=Free; f.knockdown=f.stun=f.combo_received=0;
                    f.recovery_time=0;
                    f.throw_grace=rules.throw_grace_frames;
                }
            }
        }
        return;
    }
    if(f.stun>0) {
        if(f.guarding) f.vx=f.knockback_left=0;
        f.running=f.dash=f.dash_pause=0;
        f.carry_vx=f.carry_time=0;
        f.reversal_ready=1;
        if(f.guarding) ++f.block_age;
        --f.stun;
        if(f.stun==0&&!f.guard_break) f.throw_grace=rules.throw_grace_frames;
        return;
    }
    if(f.knockback_left>0) f.vx=f.knockback_left=0;
    if(f.prejump_time>0) {
        if(--f.prejump_time>0) return;
        f.vy=mobility[f.character].v[JumpSpeed]; f.y=max(1,f.y);
        // FD can begin on takeoff, at the airborne rate; it cannot guard prejump.
        update_faultless(f);
    }
    // This opportunity exists for exactly the first actionable tick after stun.
    // The ordinary input buffer supplies execution leniency; it grants no invulnerability.
    bool reversal=f.reversal_ready!=0;
    f.reversal_ready=0;
    f.guarding=f.block_reaction=f.block_age=f.block_advantage=f.guard_break=0;
    if(f.dash>0&&f.dash_pause>0) { tick_dash(f); return; }
    // The burst starts after the entire pause. A buffered attack receives this
    // new velocity through its usual inertia rule, never the pre-dash velocity.
    if(f.dash>0&&f.dash_air&&f.dash_age==0&&f.dash_kind!=Teleport)
        f.vx=f.dash_direction*mobility[f.character].v[f.dash_backwards?AirBackdashSpeed:AirDashSpeed];
    if(!f.stance&&faultless_requested(f)&&f.move<0) {
        f.dash=f.dash_pause=f.running=0;
        f.carry_vx=f.carry_time=0;
        if(f.y==0) f.vx=0;
        return;
    }
    if(f.dash>0&&f.dash_kind==Teleport) { tick_dash(f); return; }
    for(int n=world.frame;n>=max(0,world.frame-rules.buffer+1);--n) {
        Sample* h=sample(f,n);
        if(!h) continue;
        if((h->pressed&Up)&&!(h->consumed&Up)&&(f.y==0||f.air_jump_used<mobility[f.character].v[AirJumps])&&!(f.simple&&(h->held&Simple))) {
            bool can=f.move<0;
            if(!can) {
                const Move& m=effective_move(f);
                can=m.v[JumpCancel]&&(f.contact||m.v[WhiffCancel])&&cancel_window(f,2);
            }
            if(can) {
                f.move=-1; f.contact=f.hit_done=f.dash=f.dash_pause=f.running=0;
                h->consumed|=Up;
                f.stance=0;
                bool airborne=f.y>0;
                if(airborne) ++f.air_jump_used;
                f.prejump_time=airborne?0:mobility_or(f,MovePrejumpFrames,rules.prejump_frames);
                int horizontal=((h->held&Right)!=0)-((h->held&Left)!=0);
                if(horizontal&&f.vx*horizontal<=0) f.vx=horizontal*mobility[f.character].v[horizontal*f.facing>0?JumpForwardSpeed:JumpBackSpeed];
                if(f.prejump_time>0) {
                    int horizontal=((h->held&Right)!=0)-((h->held&Left)!=0);
                    if(horizontal&&f.vx*horizontal<=0) f.vx=horizontal*mobility[f.character].v[horizontal*f.facing>0?JumpForwardSpeed:JumpBackSpeed];
                    return;
                }
                f.vy=mobility[f.character].v[JumpSpeed]; f.y=max(1,f.y);
                break;
            }
        }
        const int target=requested(f,*h);
        bool chain=target>=0&&(moves[f.character][target].v[FollowFrom]>=0||moves[f.character][target].v[FollowFrom2]>=0);
        bool chain_window=!chain||(f.move>=0&&(f.contact||f.age>=effective_move(f).v[Startup]-1+effective_move(f).v[Active]));
        int group=chain?3:target>=0&&(moves[f.character][target].v[Category]==Special||moves[f.character][target].v[Category]==Drive)?1:0;
        if(target>=0&&chain_window&&(f.move<0||(!f.variant&&can_cancel(f.character,f.move,target,f.contact!=0)&&cancel_window(f,group)))) {
            if(reversal&&f.move<0&&moves[f.character][target].v[ReversalEligible]) {
                f.reversal_time=NOTICE_TICKS;
                f.reversal_input_age=world.frame-h->frame;
            }
            begin(f,target);
            f.input_age=world.frame-h->frame;
            h->consumed|=h->pressed; // A chord cannot become multiple buffered attacks.
            // Older attacks must not fire after the newly chosen command.
            for(auto& old:f.history) if(old.frame<n) old.consumed|=old.pressed;
            return;
        }
        bool macro=(h->pressed&Dash)&&!(h->consumed&Dash);
        bool backwards=(macro&&h->direction%3==1)||double_forward(f,*h,4);
        bool dash_request=macro||double_forward(f,*h)||backwards;
        const auto& profile=mobility[f.character];
        bool air_allowed=f.y==0||(profile.v[backwards?AirBackdashEnabled:AirDashEnabled]&&f.air_dash_used<profile.v[AirDashUses]);
        if((f.move<0||(f.y>0&&effective_move(f).v[JumpCancel]&&f.contact&&cancel_window(f,2)))&&!f.dash&&dash_request&&air_allowed) {
            f.move=-1; f.contact=f.hit_done=0;
            start_dash(f,backwards);
            h->consumed|=Dash|Left|Right;
            for(auto& old:f.history) if(old.frame<h->frame) old.consumed|=Left|Right;
            break;
        }
    }
    if(f.move<0) {
        int horizontal=((f.raw&Right)!=0)-((f.raw&Left)!=0);
        const auto& profile=mobility[f.character];
        if(f.dash>0) {
            tick_dash(f);
        } else if(f.y>0) {
            // A run/step jump retains horizontal speed; steering can redirect to walking speed.
            if(horizontal&&(f.vx*horizontal<=0)) f.vx=horizontal*profile.v[horizontal*f.facing>0?JumpForwardSpeed:JumpBackSpeed];
        } else if(f.running&&(f.raw&Down)==0&&(horizontal==f.dash_direction||((f.raw&Dash)&&horizontal!=-f.dash_direction))) {
            int speed=max(0,f.vx*f.dash_direction);
            f.vx=f.dash_direction*min(profile.v[f.dash_direction==f.facing?RunSpeed:BackRunSpeed],speed+profile.v[RunAcceleration]);
        } else {
            f.running=0;
            f.vx=(f.raw&Down)?0:horizontal*profile.v[horizontal*f.facing<0?BackWalkSpeed:WalkSpeed];
        }
    }
}
void Simulation::collide_wall(Fighter& f,int velocity,bool in_hitstun) {
    int side=velocity<0?0:1;
    if(in_hitstun&&!f.guarding&&f.reaction!=WallSplat&&f.reaction!=Downed&&f.reaction!=Waking) {
        // Test health BEFORE this impact. Depleting a healthy wall cannot also splat.
        if(world.wall_health[side]==0) {
            f.reaction=WallSplat; f.wall_time=rules.wall_splat_frames;
            f.wall_side=side==0?-1:1;
            f.y=max(2000,f.y); f.vy=0; // A high airborne impact keeps its actual height.
            f.pull_time=0; f.pull_owner=f.grab_owner=-1;
        } else world.wall_health[side]=max(0,world.wall_health[side]-abs(velocity));
    }
    f.vx=f.knockback_left=f.carry_vx=f.carry_time=0;
    if(in_hitstun&&f.reaction!=WallSplat&&f.bounce_wall>0) {
        f.vx=velocity<0?f.bounce_wall:-f.bounce_wall; f.knockback_left=abs(f.vx)*HIT_TRAVEL_TICKS;
        f.bounce_wall=0; f.vy=max(f.vy,500); f.y=max(1,f.y); f.reaction=AirReel;
    }
}
void Simulation::move_horizontal(Fighter& f,bool was_hitstunned) {
    if(f.reaction==WallSplat||f.reaction==Downed||f.reaction==Waking||f.reaction==Reeled||f.reaction==Captured||f.reaction==Crumpled||f.guarding||f.grab_time) return;
    if(was_hitstunned||f.reaction==AirReel) {
        // Horizontal hit velocity advances on the defender's clock (including counter slowdown).
        // Hitstop freezes it. The remaining-distance budget preserves authored knockback values.
        int velocity=f.vx;
        if(!velocity) return;
        if(f.knockback_left>0) velocity=(velocity<0?-1:1)*min(abs(velocity),f.knockback_left);
        int proposed=f.x+velocity;
        int edge=clamp_x(f,velocity<0?0:100000);
        f.x=clamp_x(f,proposed);
        if((velocity<0&&proposed<=edge)||(velocity>0&&proposed>=edge)) {
            collide_wall(f,velocity,was_hitstunned);
        } else if(f.knockback_left>0) {
            f.knockback_left-=abs(velocity);
            f.vx=(velocity<0?-1:1)*min(abs(velocity),f.knockback_left);
        }
        return;
    }
    if(f.reaction!=Free||f.stun>0) return;
    if(f.move<0&&(f.running||f.dash)&&(!f.dash_air||f.dash_age>0)) {
        f.carry_vx=f.vx;
        f.carry_time=rules.buffer;
    }
    if(f.grab_time>0) return;
    f.x+=f.vx;
    if(f.move>=0) {
        if(f.variant==2&&f.age+1<effective_move(f).v[Startup]+effective_move(f).v[Active])
            f.x+=f.facing*effective_move(f).v[VariantSpeed];
        else if(effective_move(f).v[ActionType]==3) {
            if(active(f)) f.x+=f.facing*effective_move(f).v[DiveSpeedX];
            f.vx=0;
        }
        else if(active(f)) f.x+=f.facing*effective_move(f).v[TravelSpeed];
        else if(f.age+1<effective_move(f).v[Startup]) f.x+=f.facing*effective_move(f).v[StartupTravel];
        int drag=mobility[f.character].v[AttackFriction];
        f.vx=f.vx>0?max(0,f.vx-drag):min(0,f.vx+drag);
    }
}
static bool vertical_overlap(const Box& a,const Box& b) { return a.top>b.bottom&&a.bottom<b.top; }
static bool intersects(const Box& a,const Box& b) {
    return a.right>b.left&&a.left<b.right&&vertical_overlap(a,b);
}
static Box transform(Box b,const Fighter& f) {
    return {f.x+(f.facing==1?b.left:-b.right),f.y+b.bottom,
            f.x+(f.facing==1?b.right:-b.left),f.y+b.top};
}
static int pose_offset(int phase,int index) {
    const int offsets[]={0,12,18,24,56,88,89,97,105,109,115};
    return offsets[phase]+index;
}
Pose Simulation::pose(const Fighter& f,int tick_offset) const {
    const Pose ready=f.stance&&f.character==3?Pose{8,((f.idle_time+tick_offset)/7)%4}:Pose{LOCOMOTION_POSES[f.character]?5:0,0};
    const int recovery_phase=f.knockdown==HardKnockdown?9:10;
    if(f.reaction==Downed) return {recovery_phase,0};
    if(f.reaction==Waking) {
        const int elapsed=clamp(f.wakeup_frames-f.recovery_time+tick_offset,0,max(0,f.wakeup_frames-1));
        return {recovery_phase,f.wakeup_frames<=1?5:1+elapsed*4/(f.wakeup_frames-1)};
    }
    if(f.reaction==AirReel||f.reaction==WallSplat||f.reaction==Reeled||f.reaction==Captured||f.reaction==Crumpled) return {0,9};
    if(f.guarding&&f.block_reaction>0) return {2,(f.block_reaction-1)*2+(f.block_age>=4)};
    if(f.stun) return {0,9};
    if(f.prejump_time) return {0,11};
    if(f.faultless) return {2,1};
    if(f.move>=0) {
        const auto& m=effective_move(f);
        int age=f.age+tick_offset;
        if(f.grab_time>0) {
            int art=m.v[FinishArtPose]>0&&m.v[GrabFrames]-f.grab_time>=m.v[FinishArtFrame]?m.v[FinishArtPose]:m.v[ArtPose];
            return art>0?Pose{4,art-1}:Pose{0,1+m.v[Button]};
        }
        if(m.v[FinishArtPose]>0&&m.v[FinishArtFrame]>0&&age>=m.v[Startup]+m.v[FinishArtFrame]-1&&age<m.v[Startup]+m.v[Active]) return {4,m.v[FinishArtPose]-1};
        if(m.v[ArtPose]>0&&age<m.v[Startup]+m.v[Active]+(m.v[HitAngle]?8:0))
            return {age<m.v[Startup]?3:4,m.v[ArtPose]-1};
        if(age<m.v[Startup]) return {1,1+m.v[Button]};
        if(age<m.v[Startup]+m.v[Active]) return {0,1+m.v[Button]};
        if(f.y>0) return {0,8};
        return (f.raw&Down)?Pose{0,11}:ready;
    }
    if(f.y>0) return {0,8};
    if(f.stance) return ready;
    if(f.raw&Down) return {0,11};
    if(LOCOMOTION_POSES[f.character]) {
        // Distance-driven gait needs no render clock or extra rollback state.
        // It freezes during hitstop, reverses on back-walk and follows acceleration.
        if(f.dash>0&&f.character==3) return {7,min(7,f.dash_age*8/max(1,mobility[f.character].v[f.dash_direction==f.facing?StepFrames:BackFrames]))};
        if(!f.vx) return ready;
        const int phase=f.running?7:6;
        const auto& profile=mobility[f.character];
        const int stride=max(1,profile.v[f.running?RunSpeed:WalkSpeed])*(f.running?3:5);
        const int distance=f.facing==1?f.x:-f.x;
        const int step=distance>=0?distance/stride:-((-distance+stride-1)/stride);
        return {phase,(step%8+8)%8};
    }
    int horizontal=f.raw&(Left|Right);
    if(horizontal==Left||horizontal==Right||(f.raw&Dash)) return {0,6+((world.frame+tick_offset)/(f.running?4:8))%2};
    return {0,0};
}
int Simulation::pose_box_count(int c,int phase,int index) {
    if(c<0||c>=CHARACTER_COUNT||phase<0||phase>10||index<0) return 0;
    const int count=phase>=9?6:phase==8?(c==3?4:0):phase==0?12:phase<=2?6:phase<=4?SIGNATURE_POSES[c]:LOCOMOTION_POSES[c]?(phase==5?1:8):0;
    if(index>=count) return 0;
    return HURT_POSES[c][pose_offset(phase,index)].count;
}
Box Simulation::pose_box(int c,int phase,int index,int n) {
    if(n<0||n>=pose_box_count(c,phase,index)) return {};
    return HURT_POSES[c][pose_offset(phase,index)].boxes[n];
}
unsigned Simulation::collision_hash() { return COLLISION_HASH; }
const MoveHurt* Simulation::hurt_override(const Fighter& f,int tick_offset) const {
    if(f.move<0||f.reaction!=Free||f.stun||f.prejump_time||f.faultless
        ||(f.guarding&&f.block_reaction>0)) return nullptr;
    const auto& m=effective_move(f);
    int age=f.age+tick_offset;
    int phase=age<m.v[Startup]?0:age<m.v[Startup]+m.v[Active]?1:2;
    const auto& profile=move_hurt[f.character][f.move][phase];
    return profile.count?&profile:nullptr;
}
int Simulation::hurt_count(const Fighter& f,int tick_offset) const {
    Pose art=pose(f,tick_offset);
    const auto* profile=hurt_override(f,tick_offset);
    int count=profile?profile->count:pose_box_count(f.character,art.phase,art.index);
    int enabled=0,mask=hurt_mask(f,tick_offset);
    for(int i=0;i<count;++i) if(mask&(1<<i)) ++enabled;
    return enabled;
}
int Simulation::hurt_mask(const Fighter& f,int tick_offset) const {
    if(f.move<0||f.reaction!=Free||f.stun||f.prejump_time||f.faultless
        ||(f.guarding&&f.block_reaction>0)) return 15;
    const auto& m=effective_move(f);
    int age=f.age+tick_offset;
    int mask=m.v[age<m.v[Startup]?HurtMaskWindup:age<m.v[Startup]+m.v[Active]?HurtMaskActive:HurtMaskRecovery];
    if(m.v[HurtWindowStart]>0&&age>=m.v[HurtWindowStart]&&age<=m.v[HurtWindowEnd]) mask&=m.v[HurtWindowMask];
    return mask;
}
Box Simulation::hurt_box(const Fighter& f,int index,int tick_offset) const {
    if(index<0) return {};
    int mask=hurt_mask(f,tick_offset),region=0;
    for(;region<MAX_HURTBOXES;++region) if((mask&(1<<region))&&index--==0) break;
    if(region==MAX_HURTBOXES) return {};
    if(const auto* profile=hurt_override(f,tick_offset)) return transform(profile->boxes[region],f);
    Pose art=pose(f,tick_offset);
    return transform(pose_box(f.character,art.phase,art.index,region),f);
}
Box Simulation::push_box(const Fighter& f) const {
    const auto& profile=PUSH_PROFILES[f.character];
    Pose art=pose(f);
    int height=f.y>0?profile.air:art.phase==0&&art.index==11?profile.crouching:profile.standing;
    int bottom=f.y+(f.y>0?profile.air_bottom:0);
    return {f.x-profile.half_width,bottom,f.x+profile.half_width,bottom+height};
}
Box Simulation::weapon_span(const Fighter& f,int tick_offset) const {
    if(f.move<0) return {};
    const auto& m=effective_move(f);
    int age=f.age+tick_offset-m.v[Startup];
    if(!m.v[HitAngle]||age<0||age>=m.v[Active]+8) return {};
    int length=min(8000,abs(m.v[Reach]-m.v[HitboxBack]));
    int travel=max(0,m.v[Reach]-m.v[HitboxBack]-length);
    int extension=age<m.v[Active]?travel*age/max(1,m.v[Active]-1)
        :travel*(7-(age-m.v[Active]))/8;
    int back=m.v[HitboxBack]+extension, tip=back+length;
    // Endpoints, not an axis-aligned rectangle: shared by collision and rendering.
    return {f.x+f.facing*back,f.y+m.v[Bottom]+m.v[HitAngle]*extension,
        f.x+f.facing*tip,f.y+m.v[Bottom]+m.v[HitAngle]*(extension+length)};
}
const HitKey* Simulation::hit_key(const Fighter& f,int tick_offset) const {
    if(f.move<0||f.variant||effective_move(f).v[Category]==Throw) return nullptr;
    int frame=f.age+tick_offset-effective_move(f).v[Startup]+1;
    const auto& track=move_hit[f.character][f.move];
    const HitKey* result=nullptr;
    for(int i=0;i<track.count&&track.keys[i].frame<=frame;++i) result=&track.keys[i];
    return result;
}
unsigned Simulation::hit_bit(const Fighter& f,int tick_offset) const {
    const auto* key=hit_key(f,tick_offset);
    return 1u<<(key?key->group-1:0);
}
int Simulation::attack_count(const Fighter& f,int tick_offset) const {
    if(f.variant==1) return 0;
    const auto* key=hit_key(f,tick_offset);
    return key&&key->count>=0?key->count:effective_move(f).v[HitAngle]?8:1;
}
Box Simulation::attack_box(const Fighter& f,int segment,int tick_offset) const {
    const auto& m=effective_move(f);
    if(m.v[Category]==Throw) return transform({0,0,
        PUSH_PROFILES[f.character].half_width+m.v[ThrowRange],PUSH_PROFILES[f.character].standing},f);
    const auto* key=hit_key(f,tick_offset);
    if(key&&key->count>=0) return segment<key->count?transform(key->boxes[segment],f):Box{};
    if(m.v[HitAngle]) {
        Box span=weapon_span(f,tick_offset);
        int left=span.left+(span.right-span.left)*segment/8;
        int right=span.left+(span.right-span.left)*(segment+1)/8;
        int bottom=span.bottom+(span.top-span.bottom)*segment/8;
        int top=span.bottom+(span.top-span.bottom)*(segment+1)/8;
        return {min(left,right),min(bottom,top)-m.v[Height]/2,
            max(left,right),max(bottom,top)+(m.v[Height]+1)/2};
    }
    return transform({min(m.v[HitboxBack],m.v[Reach]),m.v[Bottom],
                      max(m.v[HitboxBack],m.v[Reach]),m.v[Bottom]+m.v[Height]},f);
}
int Simulation::box_count(int player,int kind) const {
    if(player<0) return kind==WallBox?2:0;
    if(player>1) return 0;
    const auto& f=world.players[player];
    if(kind==ProjectileBox) { int count=0; for(const auto& q:world.projectiles) if(q.life&&q.owner==player) ++count; return count; }
    if(kind==HurtBox) return hurt_count(f);
    if(kind==PushBox) return 1;
    if(kind==HitBox&&f.move>=0) {
        const auto& m=effective_move(f);
        if(m.v[ProjectileKind]&&!m.v[ProjectileMelee]) return 0;
        return f.age>=m.v[Startup]&&f.age<m.v[Startup]+m.v[Active]?attack_count(f):0;
    }
    return 0;
}
Box Simulation::box(int player,int kind,int index) const {
    if(index<0||index>=box_count(player,kind)) return {};
    if(kind==WallBox) return index==0?Box{-1000000,-1000000,0,1000000}:Box{100000,-1000000,1100000,1000000};
    if(kind==ProjectileBox) {
        for(const auto& q:world.projectiles) if(q.life&&q.owner==player&&index--==0) {
            const auto& m=moves[q.character][q.move];
            return {q.x-m.v[ProjectileWidth]/2,q.y-m.v[ProjectileHeight]/2,q.x+(m.v[ProjectileWidth]+1)/2,q.y+(m.v[ProjectileHeight]+1)/2};
        }
    }
    const auto& f=world.players[player];
    return kind==HurtBox?hurt_box(f,index):kind==PushBox?push_box(f):attack_box(f,index);
}
int Simulation::clamp_x(const Fighter& f,int x) const {
    int half=PUSH_PROFILES[f.character].half_width;
    return clamp(x,half,100000-half);
}
void Simulation::resolve_push(int previous_order,bool preserve_order) {
    auto& a=world.players[0]; auto& b=world.players[1];
    Box pa=push_box(a),pb=push_box(b);
    if(!vertical_overlap(pa,pb)) return;
    // Keep the previous order across a movement sweep. A large dash/advance cannot
    // teleport through a grounded opponent. An airborne crossing can change order.
    int sign=preserve_order?previous_order:(a.x<=b.x?1:-1);
    int separation=PUSH_PROFILES[a.character].half_width+PUSH_PROFILES[b.character].half_width;
    int overlap=separation-(b.x-a.x)*sign;
    if(overlap<=0) return;
    a.x=clamp_x(a,a.x-sign*((overlap+1)/2));
    b.x=clamp_x(b,b.x+sign*(overlap/2));
    overlap=separation-(b.x-a.x)*sign;
    if(overlap>0) {
        // Transfer whatever a wall blocked to the fighter with space available.
        int old=a.x;
        a.x=clamp_x(a,a.x-sign*overlap);
        overlap-=abs(a.x-old);
        b.x=clamp_x(b,b.x+sign*overlap);
    }
}
bool Simulation::overlaps(const Fighter& a,const Fighter& b) const {
    // Hits are evaluated before age increments. Use the pose that this tick shows.
    int count=attack_count(a,1);
    for(int segment=0;segment<count;++segment) for(int i=0;i<hurt_count(b,1);++i)
        if(intersects(attack_box(a,segment,1),hurt_box(b,i,1))) return true;
    return false;
}
bool Simulation::blocks(const Fighter& attacker,const Fighter& defender,bool was_stunned,bool was_landing) const {
    if(defender.stance||defender.reaction!=Free||effective_move(attacker).v[Category]==Throw) return false;
    if(guard_point(defender,effective_move(attacker))) return true;
    if(defender.move>=0||defender.prejump_time||defender.landing_time||was_landing||((defender.stun||was_stunned)&&!defender.guarding)) return false;
    int away=attacker.x<defender.x?Right:Left;
    int toward=away==Left?Right:Left;
    bool carry=rules.block_carryover&&was_stunned&&defender.guarding&&!defender.guard_break;
    if(!carry&&(!(defender.raw&away)||(defender.raw&toward))) return false;
    if(defender.y>0) return true; // Air guard has no high/low distinction.
    int level=effective_move(attacker).v[HitLevel];
    bool crouch=(defender.raw&Down)!=0;
    return level==0||(level==1?crouch:!crouch);
}

int Simulation::gravity_percent(const Fighter& f) const {
    if(f.reaction!=AirReel||f.combo_received<=rules.gravity_after) return 100;
    return min(rules.gravity_cap,100+(f.combo_received-rules.gravity_after)*rules.gravity_step+f.repeat_gravity);
}
bool Simulation::throw_invulnerable(const Fighter& f) const {
    return f.y>0||semi_airborne(f)||f.prejump_time>0||f.reaction!=Free||(!f.guard_break&&f.throw_grace>0)||(f.guarding&&!f.guard_break)||(f.stun>0&&!f.guarding);
}
void Simulation::land(Fighter& f) {
    if(f.reaction==AirReel&&f.bounce_ground>0) {
        f.y=1; f.vy=f.bounce_ground; f.bounce_ground=0; f.stun=max(f.stun,12); return;
    }
    if(f.move>=0&&effective_move(f).v[ActionType]==3&&f.reaction==Free) {
        f.y=f.vy=f.vx=0; f.age=effective_move(f).v[Startup]-1+effective_move(f).v[Active];
        f.landing_time=f.air_action=f.air_dash_used=f.air_jump_used=0; return;
    }
    if(f.reaction==Free)
        f.landing_time=f.air_action?(f.move>=0?effective_move(f).v[LandingRecovery]:rules.air_landing_frames):rules.empty_landing_frames;
    f.air_action=f.air_dash_used=f.air_jump_used=f.dash=f.dash_pause=f.running=0;
    f.y=f.vy=0;
    if(f.move<0||f.variant!=2) { f.move=-1; f.contact=f.hit_done=0; }
    else f.landing_time=0;
    if(f.reaction==AirReel) {
        f.vx=f.knockback_left=0;
        f.reaction=Downed; f.recovery_time=max(1,f.down_frames);
        f.stun=0; f.guarding=f.guard_break=f.block_reaction=0;
    }
}
void Simulation::reel_targets(const bool advances[2]) {
    for(int p=0;p<2;++p) {
        auto& f=world.players[p];
        if(f.reaction!=Reeled||!advances[p]) continue;
        auto& owner=world.players[1-p];
        if(f.pull_time<=0||f.pull_owner!=1-p||owner.reaction!=Free||(owner.stun>0&&!owner.guarding)) {
            f.pull_time=0; f.pull_owner=f.grab_owner=-1;
            f.reaction=f.y>0?AirReel:Free;
            continue;
        }
        int space=PUSH_PROFILES[f.character].half_width+PUSH_PROFILES[owner.character].half_width+f.pull_gap;
        int target_x=clamp_x(f,owner.x+owner.facing*space);
        f.x+=(target_x-f.x)/f.pull_time;
        f.y+=(owner.y-f.y)/f.pull_time;
        f.vy=0;
        if(--f.pull_time==0) {
            f.pull_owner=f.grab_owner=-1;
            f.reaction=f.y>0?AirReel:Free;
            f.vy=f.y>0?owner.vy:0;
            f.stun=max(f.stun,12);
        }
    }
}
void Simulation::finish_wall_break() {
    int actor=world.wall_break_actor, side=world.wall_break_side;
    for(int p=0;p<2;++p) {
        Fighter saved=world.players[p];
        Fighter& f=world.players[p];
        f=Fighter{};
        f.character=saved.character; f.simple=saved.simple;
        f.health=saved.health; f.momentum=saved.momentum;
        f.positive_time=p==actor?rules.positive_frames:saved.positive_time;
        f.x=(p==actor)==(side>0)?42000:58000;
        f.facing=f.x<50000?1:-1;
        f.move=f.last_move=-1;
        f.pull_owner=f.grab_owner=-1;
        f.combo_proration=f.combo_scale=f.damage_scale=100; f.input_age=-1;
        f.previous=f.raw=saved.raw; // A held transition input cannot become a fresh press.
        f.combo_display=saved.combo_display; f.combo_time=saved.combo_time;
        for(auto& h:f.history) { h.frame=-1000; h.direction=5; }
    }
    world.hitstop=0;
    world.stage=(world.stage+(side>0?1:STAGE_COUNT-1))%STAGE_COUNT;
    world.wall_health[0]=world.wall_health[1]=rules.wall_threshold;
}

void Simulation::step(int raw0,int raw1) {
    // Cinematic presentation follows real simulation ticks, including the impact freeze.
    if(world.impact_time>0) --world.impact_time;
    int raw[2]={raw0&INPUT_MASK,raw1&INPUT_MASK};
    for(int p=0;p<2;++p) {
        Fighter& f=world.players[p];
        if(f.move<0) f.facing=f.x<=world.players[1-p].x?1:-1;
        f.raw=raw[p];
        Sample& h=f.history[world.frame%HISTORY];
        h={world.frame,direction(raw[p],f.facing),raw[p]&~f.previous,raw[p],0};
        // A backdash pressed during guard break cannot escape through the input buffer.
        if(f.guard_break&&f.stun>0&&h.direction%3==1) h.consumed|=Dash|Left|Right;
        f.previous=raw[p];
    }
    if(world.winner>=0) { ++world.frame; return; }
    if(world.wall_break_time>0) {
        for(auto& q:world.projectiles) q.life=0;
        for(auto& f:world.players) f.history[world.frame%HISTORY].consumed=INPUT_MASK;
        // Reset combat during travel; the presentation retains captured departure positions until landing.
        if(--world.wall_break_time==rules.wall_break_frames/3) finish_wall_break();
        if(world.wall_break_time==0) {
            const auto& a=world.players[0]; const auto& b=world.players[1];
            if(world.remaining<=0||a.health==0||b.health==0)
                world.winner=a.health==b.health?2:a.health>b.health?0:1;
        }
        ++world.frame;
        return;
    }
    for(auto& f:world.players) update_faultless(f);
    if(world.hitstop>0) { --world.hitstop; ++world.frame; return; }
    tick_statuses();
    bool advances[2]={true,true};
    for(int p=0;p<2;++p) {
        auto& f=world.players[p];
        f.slow_held=0;
        if(f.slow_time>0) {
            advances[p]=f.slow_phase!=0;
            f.slow_held=!advances[p];
            f.slow_phase^=1;
            if(--f.slow_time==0) f.slow_phase=0;
        }
    }
    const int prior_stun[2]={world.players[0].stun,world.players[1].stun};
    const int prior_guard[2]={world.players[0].guarding,world.players[1].guarding};
    const int prior_reaction[2]={world.players[0].reaction,world.players[1].reaction};
    const int prior_landing[2]={world.players[0].landing_time,world.players[1].landing_time};
    const int prior_grace[2]={world.players[0].throw_grace,world.players[1].throw_grace};
    const bool prior_combo[2]={
        (prior_stun[0]>0&&!prior_guard[0])||world.players[0].reaction==AirReel||world.players[0].reaction==WallSplat||world.players[0].reaction==Reeled||world.players[0].reaction==Crumpled,
        (prior_stun[1]>0&&!prior_guard[1])||world.players[1].reaction==AirReel||world.players[1].reaction==WallSplat||world.players[1].reaction==Reeled||world.players[1].reaction==Crumpled};
    const int prior_x[2]={world.players[0].x,world.players[1].x};
    const int previous_order=prior_x[0]<=prior_x[1]?1:-1;
    const bool prior_overlap=vertical_overlap(push_box(world.players[0]),push_box(world.players[1]));
    int moved[2]={0,0};
    for(int p=0;p<2;++p) {
        auto& f=world.players[p];
        // Feedback clocks are fixed-tick state: pause, hitstop and rollback all agree.
        if(f.hit_notice_time>0) --f.hit_notice_time;
        if(f.reversal_time>0) --f.reversal_time;
        if(f.combo_display>0) f.combo_age=min(1000,f.combo_age+1);
        if(prior_combo[1-p]) {
            if(f.combo>=2) f.combo_time=COMBO_HOLD;
        }
        else {
            f.combo=0;
            if(f.combo_time>0) --f.combo_time;
        }
        // Inputs still sample at 60 Hz; only this fighter's action/reaction clock slows.
        if(!advances[p]) continue;
        if(!prior_combo[p]&&f.reaction==Free&&!f.grab_time) {
            f.combo_received=f.repeat_gravity=0;
            f.combo_proration=f.combo_scale=100;
            for(auto& uses:f.move_uses) uses=0;
        }
        if(f.positive_time>0) {
            // Passive bonus is a fixed amount, not multiplied by its own gain multiplier.
            if(!f.faultless) f.momentum=min(MOMENTUM_MAX,f.momentum+rules.positive_regen);
        }
        if(f.carry_time>0) --f.carry_time;
        f.teleported=0;
        control(f);
        if(f.move<0&&!f.stun&&f.reaction==Free) f.idle_time=(f.idle_time+1)%1000000;
        spawn_projectile(f);
        move_horizontal(f,prior_stun[p]>0&&!prior_guard[p]);
        if(f.move<0&&!f.teleported&&!prior_stun[p]&&f.reaction==Free&&!faultless_requested(f)) moved[p]=max(0,(f.x-prior_x[p])*f.facing);
        bool dive=f.move>=0&&effective_move(f).v[ActionType]==3&&f.y>0&&f.reaction==Free;
        if(dive) f.vy=active(f)?effective_move(f).v[DiveSpeedY]:0;
        bool air_charge=f.move>=0&&effective_move(f).v[ActionType]==6&&!f.projectile_spawned&&f.reaction==Free;
        if(air_charge) f.vy=0;
        if(f.y>0&&f.reaction!=WallSplat&&f.reaction!=Reeled&&f.reaction!=Captured&&f.reaction!=Crumpled&&!f.grab_time) {
            f.y+=f.vy;
            if(!dive&&!air_charge&&!(f.dash>0&&(f.dash_kind==HoverDash||f.dash_air))) f.vy-=mobility[f.character].v[Gravity]*gravity_percent(f)/100;
            if(f.y<=0) land(f);
        }
        else if(f.y<=0&&f.reaction==AirReel) land(f);
        f.x=clamp_x(f,f.x);
    }
    tick_grabs(advances);
    Fighter& a=world.players[0]; Fighter& b=world.players[1];
    for(int p=0;p<2;++p) if(advances[p]&&world.players[p].move>=0) trigger_tether(world.players[p]);
    reel_targets(advances);
    if(a.reaction!=Captured&&b.reaction!=Captured) resolve_push(previous_order,prior_overlap&&!a.teleported&&!b.teleported);
    // Only actual voluntary approach earns movement meter: no wall/pushbox or knockback farming.
    for(int p=0;p<2;++p) {
        auto& f=world.players[p];
        int distance=min(moved[p],max(0,(f.x-prior_x[p])*f.facing));
        if(distance>0) {
            int amount=distance*rules.move_gain+f.movement_remainder;
            gain_momentum(f,amount/100);
            f.movement_remainder=amount%100;
        }
        // A blocked run cannot bank speed against a wall or another body.
        if(advances[p]&&!prior_stun[p]&&!f.stun&&f.reaction==Free&&f.move<0&&f.y==0&&f.vx&&(f.x-prior_x[p])*f.vx<=0) f.vx=f.carry_vx=f.carry_time=0;
    }
    int hits[2]={-1,-1}, contacts[2]={NoContact,NoContact};
    bool blocked[2]={false,false};
    for(int p=0;p<2;++p) {
        Fighter& f=world.players[p]; Fighter& other=world.players[1-p];
        if(f.grab_time||f.reaction==Captured||other.grab_time||other.reaction==Captured||other.reaction==Downed||other.reaction==Waking
            ||prior_reaction[1-p]==Downed||prior_reaction[1-p]==Waking) continue;
        bool throwing=f.move>=0&&effective_move(f).v[Category]==Throw;
        bool connects=false;
        bool spent=f.move>=0&&(move_hit[f.character][f.move].multi
            ? (f.hit_groups&hit_bit(f,1))!=0 : f.hit_done!=0);
        if(advances[p]&&active(f)&&!spent&&f.variant!=1) {
            if(throwing) {
                int separation=PUSH_PROFILES[f.character].half_width+PUSH_PROFILES[other.character].half_width;
                const auto& tm=effective_move(f);
                if(tm.v[Air]&&f.y>0) connects=other.y>0&&other.reaction==Free&&!other.stun&&!other.throw_grace
                    &&abs(other.y-f.y)<7000&&abs(other.x-f.x)<=separation+tm.v[ThrowRange];
                else connects=(f.y==0||(f.variant==2&&f.y<=8000))&&!throw_invulnerable(other)&&!(prior_stun[1-p]>0&&!prior_guard[1-p])
                    &&(other.x-f.x)*f.facing>=0&&abs(other.x-f.x)<=separation+tm.v[ThrowRange];
            } else if(!effective_move(f).v[ProjectileKind]||effective_move(f).v[ProjectileMelee]) connects=overlaps(f,other);
        }
        if(connects&&semi_airborne(other)&&effective_move(f).v[HitLevel]==1) connects=false;
        if(connects) {
            hits[p]=f.move; blocked[p]=blocks(f,other,prior_stun[1-p]>0,prior_landing[1-p]>0);
            contacts[p]=blocked[p]?Blocked:NormalHit;
            if(!blocked[p]&&other.move>=0&&prior_stun[1-p]==0) {
                const Move interrupted=effective_move(other);
                int tick=other.age+(advances[1-p]?1:0);
                int phase=tick<interrupted.v[Startup]?1:tick<interrupted.v[Startup]+interrupted.v[Active]?2:4;
                contacts[p]=throwing?PunishHit:(interrupted.v[CounterVulnerable]&phase)?CounterHit:phase==4?PunishHit:NormalHit;
            }
            else if(!blocked[p]&&(other.landing_time||prior_landing[1-p])) contacts[p]=PunishHit;
        }
    }
    // Simultaneous throws clash. A simultaneous strike beats a throw; no player-index bias.
    if(hits[0]>=0&&hits[1]>=0) {
        bool t0=effective_move(a).v[Category]==Throw;
        bool t1=effective_move(b).v[Category]==Throw;
        if(t0) { hits[0]=-1; a.hit_done=1; }
        if(t1) { hits[1]=-1; b.hit_done=1; }
    }
    Move contact_moves[2]{};
    Fighter contact_fighters[2]={a,b};
    for(int p=0;p<2;++p) if(hits[p]>=0) contact_moves[p]=effective_move(world.players[p]);
    // Detect both hits AND their classifications before changing either fighter.
    // Clear interrupted combo displays before applying either side of a trade.
    for(int p=0;p<2;++p) if(hits[p]>=0&&!blocked[p]) {
        auto& defender=world.players[1-p];
        defender.combo=defender.combo_display=defender.combo_time=defender.combo_age=0;
    }
    for(int p=0;p<2;++p) if(hits[p]>=0) {
        Fighter& f=world.players[p];
        Move m=contact_moves[p];
        // Copy before applying a trade: interruptions may replace the opponent's move.
        Fighter contact_fighter=contact_fighters[p];
        const auto* key=hit_key(contact_fighter,1);
        if(key) {
            if(key->damage>=0) m.v[Damage]=key->damage;
            if(key->hitstun>=0) m.v[Hitstun]=key->hitstun;
            if(key->blockstun>=0) m.v[Blockstun]=key->blockstun;
            if(key->hitstop>=0) m.v[Hitstop]=key->hitstop;
        }
        f.hit_groups|=hit_bit(contact_fighter,1);
        f.hit_done=f.contact=1;
        apply_contact(p,hits[p],m,contacts[p],prior_combo[1-p],prior_reaction[1-p],f.facing,false);
    }
    update_projectiles();
    for(int p=0;p<2;++p) if(advances[p]&&prior_grace[p]>0&&world.players[p].throw_grace>0) --world.players[p].throw_grace;
    for(int p=0;p<2;++p) if(advances[p]&&world.players[p].move>=0) {
        auto& f=world.players[p];
        const Move& m=effective_move(f);
        if(f.grab_time>0) continue;
        if(m.v[ActionType]==1&&(f.raw&f.guard_button)&&f.age>=m.v[Startup]-1&&f.age<m.v[Startup]-1+m.v[Active]) continue;
        if(m.v[ActionType]==3&&f.y>0&&active(f)) { f.age=m.v[Startup]; continue; }
        if(++f.age>=m.v[Startup]-1+m.v[Active]+m.v[Recovery]) {
            f.move=-1; f.contact=f.hit_done=0;
        }
    }
    // A back throw is the explicit side-switch exception to movement's anti-tunneling rule.
    if(a.reaction!=Captured&&b.reaction!=Captured) resolve_push(previous_order,prior_overlap&&!a.teleported&&!b.teleported&&!(hits[0]==BACK_THROW||hits[1]==BACK_THROW||hits[0]==AIR_BACK_THROW||hits[1]==AIR_BACK_THROW));
    for(int p=0;p<2;++p) if(advances[p]&&world.players[p].positive_time>0) --world.players[p].positive_time;
    --world.remaining;
    if(world.wall_break_time==0&&(world.remaining<=0||a.health==0||b.health==0))
        world.winner=a.health==b.health?2:a.health>b.health?0:1;
    ++world.frame;
}

int Simulation::mobility_or(const Fighter& f,int field,int fallback) const {
    int value=mobility[f.character].v[field]; return value<0?fallback:value;
}
void Simulation::start_dash(Fighter& f,bool backwards) {
    const auto& m=mobility[f.character];
    f.dash_air=f.y>0;
    f.dash_backwards=backwards;
    f.dash_pause=f.dash_air?m.v[backwards?AirBackdashPauseFrames:AirDashPauseFrames]:0;
    f.dash_kind=m.v[f.dash_air?(backwards?AirBackdashStyle:AirDashStyle):(backwards?BackStyle:ForwardStyle)];
    f.dash_direction=f.facing*(backwards?-1:1); f.dash_age=0;
    f.running=!f.dash_air&&f.dash_kind==ForwardRun;
    f.dash=f.running?0:m.v[f.dash_air?(backwards?AirBackdashFrames:AirDashFrames):(backwards?BackFrames:StepFrames)];
    if(f.dash_kind==Teleport) f.dash=max(f.dash,f.dash_air?2:m.v[TeleportStartup]+1);
    if(f.dash_air) {
        ++f.air_dash_used; f.air_action=1;
        f.vx=f.vy=f.carry_vx=f.carry_time=f.knockback_left=0;
        return;
    }
    if(f.dash_kind==HoverDash&&!f.dash_air) { f.y=1; f.vy=0; }
    if(f.dash_kind==Teleport) f.vx=f.carry_vx=f.carry_time=0;
    else if(!f.running) f.vx=f.dash_direction*m.v[f.dash_air?(backwards?AirBackdashSpeed:AirDashSpeed):(backwards?BackSpeed:StepSpeed)];
}
void Simulation::tick_dash(Fighter& f) {
    const auto& m=mobility[f.character];
    if(f.dash_pause>0) {
        --f.dash_pause;
        f.vx=f.vy=f.carry_vx=f.carry_time=0;
        return; // The burst's duration and age do not advance during the pause.
    }
    ++f.dash_age;
    if(f.dash_kind==Teleport) {
        f.vx=0; f.vy=0;
        if(f.dash_age==(f.dash_air?1:m.v[TeleportStartup])) {
            bool backwards=f.dash_air?f.dash_backwards:f.dash_direction!=f.facing;
            f.x=clamp_x(f,f.x+f.dash_direction*m.v[backwards?BackTeleportDistance:TeleportDistance]);
            f.teleported=1;
        }
    } else if(f.dash_kind==HoverDash) {
        f.vy=0;
        if(!f.dash_air) f.y=min(m.v[HoverHeight],f.y+m.v[HoverRiseSpeed]);
    } else if(f.dash_air) f.vy=0;
    --f.dash;
}
void Simulation::spawn_projectile(Fighter& f) {
    if(f.move<0||f.projectile_spawned||f.stun||f.reaction!=Free) return;
    const auto& m=effective_move(f);
    int at=max(startup_minimum(m),m.v[ProjectileSpawnFrame]?m.v[ProjectileSpawnFrame]:m.v[Startup]);
    if(!m.v[ProjectileKind]||m.v[Category]==Throw||f.age+1!=at) return;
    f.projectile_spawned=1;
    if(m.v[ActionType]==6) { f.vx=f.facing*m.v[DiveSpeedX]; f.vy=m.v[DiveSpeedY]; }
    int owner=&f==&world.players[0]?0:1,owned=0;
    for(const auto& q:world.projectiles) if(q.life&&q.owner==owner) ++owned;
    if(owned>=MAX_PROJECTILES/2) return; // Fixed, symmetric budget; no allocation in rollback.
    for(auto& q:world.projectiles) if(!q.life) {
        q={m.v[ProjectileLife],owner,f.character,f.move,f.attack_serial,
           f.x+f.facing*m.v[ProjectileOffsetX],f.y+m.v[ProjectileOffsetY],
           m.v[ProjectileKind]==1?f.facing*m.v[ProjectileSpeedX]:0,
           m.v[ProjectileKind]==1?m.v[ProjectileSpeedY]:0,f.facing,
           m.v[ProjectileHits],0,m.v[ProjectileDurability]};
        break;
    }
}
// Swept AABB in fixed-point time. Fast/thin shots cannot tunnel through a body
// or one another; relative motion also keeps diagonal clashes honest.
static bool swept_point(int x0,int y0,int x1,int y1,const Box& b) {
    long long enter=0,leave=1000000;
    const int starts[]={x0,y0},deltas[]={x1-x0,y1-y0},lo[]={b.left,b.bottom},hi[]={b.right,b.top};
    for(int axis=0;axis<2;++axis) {
        if(!deltas[axis]) { if(starts[axis]<lo[axis]||starts[axis]>hi[axis]) return false; continue; }
        long long a=static_cast<long long>(lo[axis]-starts[axis])*1000000;
        long long z=static_cast<long long>(hi[axis]-starts[axis])*1000000,d=deltas[axis];
        if(d<0) { long long t=a; a=-z; z=-t; d=-d; }
        long long first=a/d+(a>0&&a%d?1:0),last=z/d-(z<0&&z%d?1:0);
        if(first>enter) enter=first;
        if(last<leave) leave=last;
        if(enter>leave) return false;
    }
    return enter<=leave;
}
void Simulation::update_projectiles() {
    int old_x[MAX_PROJECTILES],old_y[MAX_PROJECTILES];
    for(int i=0;i<MAX_PROJECTILES;++i) { old_x[i]=world.projectiles[i].x; old_y[i]=world.projectiles[i].y; }
    // Projectiles run on the world clock, freezing with hitstop. Stationary traps
    // ignore velocity and gravity even when those fields retain previous edits.
    for(auto& q:world.projectiles) if(q.life) {
        const auto& m=moves[q.character][q.move]; const auto& owner=world.players[q.owner];
        if((!m.v[ProjectilePersist]&&((owner.stun&&!owner.guarding)||owner.reaction!=Free))||world.wall_break_time) { q.life=0; continue; }
        if(q.cooldown) --q.cooldown;
        if(m.v[ProjectileKind]==1) { q.x+=q.vx; q.y+=q.vy; q.vy=clamp(q.vy-m.v[ProjectileGravity],-10000,10000); }
        if(q.x< -30000||q.x>130000||q.y< -30000||q.y>100000) q.life=0;
    }
    // Opposing projectiles exchange durability simultaneously on each collision.
    for(int i=0;i<MAX_PROJECTILES;++i) for(int j=i+1;j<MAX_PROJECTILES;++j) {
        auto& a=world.projectiles[i]; auto& b=world.projectiles[j];
        if(!a.life||!b.life||a.owner==b.owner) continue;
        const auto& ma=moves[a.character][a.move]; const auto& mb=moves[b.character][b.move];
        int width=(ma.v[ProjectileWidth]+mb.v[ProjectileWidth])/2-1,height=(ma.v[ProjectileHeight]+mb.v[ProjectileHeight])/2-1;
        if(swept_point(old_x[i]-old_x[j],old_y[i]-old_y[j],a.x-b.x,a.y-b.y,{-width,-height,width,height})) {
            int da=a.durability,db=b.durability;
            a.durability=max(0,da-db); b.durability=max(0,db-da);
            if(!a.durability) a.life=0;
            if(!b.durability) b.life=0;
        }
    }
    int contacts[MAX_PROJECTILES]={}; bool combos[MAX_PROJECTILES]={}; int reactions[MAX_PROJECTILES]={};
    for(int i=0;i<MAX_PROJECTILES;++i) {
        auto& q=world.projectiles[i]; if(!q.life||q.cooldown) continue;
        auto& defender=world.players[1-q.owner]; const auto& m=moves[q.character][q.move];
        if(defender.reaction==Downed||defender.reaction==Waking||defender.reaction==Captured||defender.grab_time
            ||(semi_airborne(defender)&&m.v[HitLevel]==1)) continue;
        bool hit=false;
        for(int b=0;b<hurt_count(defender,defender.slow_held?0:1);++b) {
            Box target=hurt_box(defender,b,defender.slow_held?0:1);
            target.left-=(m.v[ProjectileWidth]+1)/2-1; target.right+=m.v[ProjectileWidth]/2-1;
            target.bottom-=(m.v[ProjectileHeight]+1)/2-1; target.top+=m.v[ProjectileHeight]/2-1;
            if(swept_point(old_x[i],old_y[i],q.x,q.y,target)) hit=true;
        }
        if(!hit) continue;
        Fighter source=world.players[q.owner]; source.move=q.move; source.x=old_x[i]; source.y=q.y; source.facing=q.facing;
        bool blocked=blocks(source,defender,defender.stun>0,defender.landing_time>0);
        contacts[i]=blocked?Blocked:NormalHit;
        if(!blocked&&defender.move>=0&&!defender.stun) {
            const auto& target=moves[defender.character][defender.move];
            int tick=defender.age+(defender.slow_held?0:1);
            int phase=tick<target.v[Startup]?1:tick<target.v[Startup]+target.v[Active]?2:4;
            contacts[i]=(target.v[CounterVulnerable]&phase)?CounterHit:phase==4?PunishHit:NormalHit;
        } else if(!blocked&&defender.landing_time) contacts[i]=PunishHit;
        combos[i]=(defender.stun&&!defender.guarding)||defender.reaction==AirReel||defender.reaction==WallSplat||defender.reaction==Reeled;
        reactions[i]=defender.reaction;
    }
    bool hit_this_tick[2]={false,false};
    for(int i=0;i<MAX_PROJECTILES;++i) {
        auto& q=world.projectiles[i]; if(!q.life) continue;
        if(contacts[i]) {
            auto& owner=world.players[q.owner]; auto& defender=world.players[1-q.owner];
            if(contacts[i]!=Blocked) defender.combo=defender.combo_display=defender.combo_time=defender.combo_age=0;
            if(owner.move==q.move&&owner.attack_serial==q.serial) owner.contact=1;
            Move m=moves[q.character][q.move]; m.v[Category]=Special; m.v[PullFrames]=0;
            apply_contact(q.owner,q.move,m,contacts[i],combos[i]||hit_this_tick[1-q.owner],reactions[i],q.facing,true);
            if(contacts[i]!=Blocked) hit_this_tick[1-q.owner]=true;
            q.cooldown=m.v[ProjectileRehit];
            if(--q.hits<=0) q.life=0;
        }
        if(q.life) --q.life;
    }
}

void Simulation::tick_grabs(const bool advances[2]) {
    for(int p=0;p<2;++p) {
        auto& f=world.players[p]; auto& other=world.players[1-p];
        if(other.reaction!=Captured||other.grab_owner!=p) { f.grab_time=0; continue; }
        if(f.move<0||f.stun||f.reaction!=Free) { other.reaction=Free; other.grab_owner=-1; f.grab_time=0; continue; }
        if(!advances[p]) continue;
        const auto& m=moves[f.character][f.move];
        other.x=clamp_x(other,f.x+f.facing*6000); other.y=f.y; other.vy=0;
        if(--f.grab_time<=0) {
            int move=f.move; Move finish=m; finish.v[GrabFrames]=0;
            other.reaction=Free; other.grab_owner=-1;
            apply_contact(p,move,finish,NormalHit,false,Free,f.facing,false);
            f.age=m.v[Startup]-1+m.v[Active]-1;
        }
    }
}
void Simulation::apply_contact(int p,int move,Move m,int contact,bool prior_combo,int prior_reaction,int facing,bool projectile) {
    Fighter& f=world.players[p]; Fighter& other=world.players[1-p];
    world.foreground_player=p;
    bool blocked=contact==Blocked;
    bool point=blocked&&guard_point(other,m);
    bool armor=!blocked&&other.move>=0&&other.reaction==Free&&other.armor_left>0&&m.v[Category]!=Throw&&m.v[HitLevel]!=1
        &&other.age+1<=moves[other.character][other.move].v[ArmorFrames];
    if(point||armor) {
        if(armor) --other.armor_left;
        int damage=point?m.v[ChipDamage]:m.v[Damage]; other.health=max(0,other.health-damage);
        f.event=point?Blocked:NormalHit; f.last_damage=damage; f.last_base_damage=m.v[Damage]; f.damage_scale=100;
        f.contact_count=(f.contact_count+1)%100000000;
        world.hitstop=max(world.hitstop,m.v[Hitstop]); return;
    }
    if(!blocked&&!projectile&&m.v[ActionType]==4&&m.v[GrabFrames]>0) {
        f.grab_time=m.v[GrabFrames]; f.vx=f.running=f.dash=f.dash_pause=0; f.event=NormalHit;
        other.grab_owner=p; other.reaction=Captured; other.move=-1; other.stun=0; other.dash=other.dash_pause=0;
        other.vx=other.vy=other.knockback_left=other.faultless=other.stance=0; return;
    }
    const bool cashout=!projectile&&f.variant==2;
    const int cash=(!blocked&&cashout&&other.bleed_source)?other.grey_life:0;
    if(!blocked) clear_owned_status(1-p);
    for(auto& target:world.players) if(target.tether_used) target.tether_source=target.tether_used=0;
    f.contact_count=(f.contact_count+1)%100000000;
        f.event=contact;
        f.combo=blocked?0:(prior_combo?min(1000,f.combo+1):1);
        f.combo_display=f.combo>=2?f.combo:0;
        f.combo_time=f.combo>=2?COMBO_HOLD:0;
        f.combo_age=0;
        if(contact==CounterHit||contact==PunishHit) {
            f.hit_notice=contact;
            f.hit_notice_time=NOTICE_TICKS;
            f.counter_tier=contact==CounterHit?m.v[CounterTier]:0;
        }
        bool fd=blocked&&other.faultless;
        bool was_airborne=other.y>0;
        bool was_splatted=other.reaction==WallSplat||prior_reaction==WallSplat;
        bool throwing=m.v[Category]==Throw;
        if(!blocked&&!prior_combo) {
            other.combo_proration=m.v[StarterProration]; other.combo_scale=100;
        }
        int scale=!prior_combo?100:max(m.v[MinimumDamage],other.combo_proration*other.combo_scale/100);
        int damage=blocked?(fd?0:m.v[ChipDamage]):m.v[Damage]>0?max(1,m.v[Damage]*scale/100):0;
        if(!blocked) damage+=cash;
        f.last_damage=damage; f.damage_scale=blocked?100:scale; f.last_base_damage=m.v[Damage];
        if(!blocked) other.combo_scale=max(0,other.combo_scale-m.v[ComboScaling]);
        other.health=max(0,other.health-damage);
        if(other.bleed_source) {
            const auto& source=moves[f.character][other.bleed_source-1];
            if(blocked) other.grey_life+=m.v[Damage]*source.v[BleedBlockPercent]/100;
            else other.bleed_time=source.v[BleedDuration];
            other.grey_life=min(min(source.v[BleedCap],max(0,other.health-1)),other.grey_life);
        }
        if(!blocked&&cashout) other.bleed_source=other.bleed_time=other.bleed_clock=other.grey_life=0;
        // A projectile or simultaneous strike from an interrupted owner cannot
        // reattach a status cleared by that same hit/trade.
        if(!blocked&&!cashout&&!(f.stun>0&&!f.guarding)&&f.reaction==Free) {
            if(m.v[Mechanic]==1) { other.tether_source=move+1; other.tether_used=0; }
            if(m.v[Mechanic]==2) {
                other.bleed_source=move+1; other.bleed_time=m.v[BleedDuration]; other.bleed_clock=0;
                other.grey_life=min(min(m.v[BleedCap],max(0,other.health-1)),other.grey_life+m.v[BleedInitial]*scale/100);
            }
        }
        if(!blocked) { other.faultless=other.stance=other.armor_left=0; }
        gain_momentum(f,m.v[Damage]*(blocked?rules.block_attack_gain:rules.attack_gain));
        if(!fd) gain_momentum(other,m.v[Damage]*(blocked?rules.guard_gain:rules.damage_gain));
        if(fd) other.momentum=max(0,other.momentum-mobility_or(other,FdBlockCost,rules.fd_block_cost)-m.v[Damage]*rules.fd_damage_cost-max(0,m.v[AttackLevel])*rules.fd_level_cost);
        other.stun=m.v[blocked?Blockstun:Hitstun]+(contact==CounterHit?m.v[CounterHitstun]:0);
        other.guarding=blocked;
        other.block_age=0;
        other.guard_break=blocked&&m.v[GuardBreak]&&other.stun>0;
        other.throw_grace=other.landing_time=other.prejump_time=0;
        // Count the remaining active/recovery ticks AFTER this contact tick.
        int remaining=max(0,m.v[Startup]-1+m.v[Active]+m.v[Recovery]-(f.move==move?f.age+1:m.v[Startup]+m.v[Active]+m.v[Recovery]));
        other.block_advantage=blocked?m.v[Blockstun]-remaining:0;
        other.block_reaction=!blocked?NoBlock:other.guard_break?BrokenGuard:
            other.block_advantage>0?PressureBlock:StableBlock;
        other.move=-1; other.dash=other.dash_pause=other.running=other.vx=other.pull_time=other.knockback_left=0;
        other.carry_vx=other.carry_time=0;
        other.pull_owner=-1;
        int push=m.v[blocked?BlockPushback:was_airborne?AirPushback:Pushback]*(fd?mobility_or(other,FdPushPercent,rules.fd_push_percent):100)/100;
        int old_x=other.x;
        if(blocked||throwing) other.x=clamp_x(other,other.x+facing*push);
        else {
            other.knockback_left=push;
            other.vx=facing*((push+HIT_TRAVEL_TICKS-1)/HIT_TRAVEL_TICKS);
        }
        // FD still creates space at the corner by transferring blocked displacement to the attacker.
        if(!projectile&&blocked&&(fd||rules.corner_push_transfer)) f.x=clamp_x(f,f.x-facing*(push-abs(other.x-old_x)));
        if(!blocked) {
            if(other.reaction==Reeled||other.reaction==Captured||other.reaction==Crumpled) other.reaction=was_airborne?AirReel:Free;
            other.bounce_ground=was_airborne?m.v[GroundBounce]:0; other.bounce_wall=was_airborne?m.v[WallBounce]:0;
            other.grab_owner=-1; other.crumple_time=0;
            other.combo_received=f.combo;
            int uses=other.move_uses[move]=min(1000,other.move_uses[move]+1);
            if(rules.repeat_after>0&&uses>=rules.repeat_after&&f.combo>rules.gravity_after)
                other.repeat_gravity=min(300,other.repeat_gravity+rules.repeat_gravity_step);
            other.knockdown=was_airborne&&contact==CounterHit&&m.v[AirCounterKnockdown]?m.v[AirCounterKnockdown]:m.v[Knockdown];
            other.down_frames=m.v[KnockdownFrames];
            other.wakeup_frames=m.v[WakeupFrames];
            if(throwing&&m.v[Direction]==4) {
                // Exchange sides at contact, retaining both body widths at stage edges.
                int separation=PUSH_PROFILES[f.character].half_width+PUSH_PROFILES[other.character].half_width;
                f.x=clamp_x(f,old_x);
                other.x=clamp_x(other,f.x-facing*(separation+push));
                f.x=clamp_x(f,other.x+facing*separation);
                f.facing=-facing; other.facing=-f.facing;
                f.teleported=other.teleported=1; // Preserve a delayed throw-finisher side swap through push resolution.
            }
            int lift=m.v[was_airborne?AirLaunch:Launch];
            if(was_airborne||lift>0||other.knockdown!=NoKnockdown) {
                other.reaction=AirReel;
                other.y=max(1,other.y); other.vy=lift;
                if(other.knockdown==NoKnockdown) other.knockdown=SoftKnockdown;
            }
            if(!was_airborne&&m.v[CrumpleFrames]>0) {
                other.reaction=Crumpled; other.crumple_time=m.v[CrumpleFrames]; other.y=500; other.vy=0; other.stun=m.v[CrumpleFrames];
            }
            if(m.v[StanceChange]==1&&!f.stun&&f.reaction==Free) f.stance=1;
            if(m.v[PullFrames]>0) {
                other.reaction=Reeled; other.pull_time=m.v[PullFrames];
                other.pull_owner=p; other.pull_gap=m.v[PullGap]; other.vy=0;
                other.knockdown=SoftKnockdown;
                other.vx=other.knockback_left=0;
            }
            if(was_splatted&&!throwing) {
                other.health=max(0,other.health-rules.wall_break_damage);
                world.wall_break_time=rules.wall_break_frames;
                world.wall_break_actor=p; world.wall_break_side=other.wall_side;
                for(int q=0;q<2;++q) {
                    world.wall_break_x[q]=world.players[q].x;
                    world.wall_break_y[q]=world.players[q].y;
                }
                other.wall_time=0;
                other.vx=other.knockback_left=0;
            }
        }
        int stop=m.v[Hitstop]+(contact==CounterHit?m.v[CounterHitstop]:0);
        if(contact==CounterHit) {
            if(m.v[CounterFreezeFrames]>=0) stop=m.v[CounterFreezeFrames];
            if(m.v[CounterSlowFrames]>0) {
                other.slow_time=max(other.slow_time,m.v[CounterSlowFrames]);
                other.slow_phase=0;
            }
            int duration=stop+m.v[CounterSlowFrames]+18;
            if(m.v[CounterTier]>=2&&(world.impact_time==0||m.v[CounterTier]>world.impact_tier)) {
                world.impact_time=world.impact_duration=duration;
                world.impact_actor=p; world.impact_tier=m.v[CounterTier];
                world.impact_x=projectile?other.x:(f.x+other.x)/2; world.impact_y=clamp(other.y+8000,0,200000);
            }
        }
        world.hitstop=max(world.hitstop,stop);
}

unsigned Simulation::checksum() const {
    const unsigned char* bytes=reinterpret_cast<const unsigned char*>(&world);
    unsigned hash=2166136261u;
    for(unsigned i=0;i<sizeof(State);++i) hash=(hash^bytes[i])*16777619u;
    return hash;
}
int Simulation::get(int player,int field) const {
    using namespace fight;
    if(player<=-2) {
        int index=-player-2; if(index>=MAX_PROJECTILES) return 0;
        const auto& q=world.projectiles[index]; if(!q.life) return 0;
        const auto& m=moves[q.character][q.move];
        const int values[]={q.life,q.owner,q.x,q.y,m.v[ProjectileWidth],m.v[ProjectileHeight],m.v[ProjectileKind],q.facing,q.move,q.vx,q.vy};
        return field>=0&&field<11?values[field]:0;
    }
    if(player<0) {
        switch(field) { case 0:return world.frame; case 1:return world.remaining;
        case 2:return world.hitstop; case 3:return world.winner;
        case 4:return world.wall_break_time; case 5:return world.wall_break_actor;
        case 6:return world.wall_break_side; case 7:return world.stage;
        case 8:return rules.wall_break_frames;
        case 9:return world.impact_time; case 10:return world.impact_duration;
        case 11:return world.impact_actor; case 12:return world.impact_tier;
        case 13:return world.impact_x; case 14:return world.impact_y;
        case 15:return world.wall_break_x[0]; case 16:return world.wall_break_x[1];
        case 17:return world.wall_break_y[0]; case 18:return world.wall_break_y[1];
        case 19:return world.wall_health[0]; case 20:return world.wall_health[1];
        case 21:return world.foreground_player;
        default:return 0; }
    }
    if(player>1) return 0;
    const Fighter& f=world.players[player];
    switch(field) {
        case 0:return f.x; case 1:return f.y; case 2:return f.facing;
        case 3:return f.health; case 4:return f.move; case 5:return f.age;
        case 6:return f.stun; case 7:return f.guarding; case 8:return f.contact;
        case 9:return f.combo; case 10:return f.event; case 11:return f.last_move;
        case 12:return f.raw; case 13:return f.character; case 14:return f.simple;
        case 15:return f.momentum; case 16:return f.faultless;
        case 17:return f.block_reaction; case 18:return f.block_age;
        case 19:return f.block_advantage; case 20:return f.guard_break;
        case 21:return throw_invulnerable(f);
        case 22:return f.combo_display; case 23:return f.combo_time; case 24:return f.combo_age;
        case 25:return f.hit_notice; case 26:return f.hit_notice_time;
        case 27:return f.reversal_time; case 28:return f.reversal_input_age;
        case 29:return pose(f).phase; case 30:return pose(f).index;
        case 31:return f.reaction; case 32:return f.knockdown; case 33:return f.recovery_time;
        case 34:return f.combo_received; case 35:return gravity_percent(f);
        case 36:return 0; // Retired per-fighter damage; wall health is world state.
        case 37:return f.wall_time; case 38:return f.positive_time;
        case 39:return f.vx; case 40:return f.running; case 41:return f.dash;
        case 42:return f.pull_time; case 43:return f.pull_owner;
        case 44:return weapon_span(f).left; case 45:return weapon_span(f).bottom;
        case 46:return weapon_span(f).right; case 47:return weapon_span(f).top;
        case 48:return weapon_span(f).left!=weapon_span(f).right;
        case 49:return f.carry_vx; case 50:return f.carry_time;
        case 51:return f.landing_time; case 52:return f.throw_grace;
        case 53: {
            int mask=0;
            for(int group=0;group<4;++group) if(cancel_window(f,group)) mask|=1<<group;
            return mask;
        }
        case 54:return f.input_age; case 55:return f.last_damage; case 56:return f.damage_scale;
        case 57:return f.combo_proration; case 58:return f.combo_scale;
        case 59:return f.counter_tier; case 60:return f.repeat_gravity; case 61:return f.last_base_damage;
        case 62:return f.prejump_time;
        case 63:return f.slow_time; case 64:return f.slow_held;
        case 65:return f.knockback_left;
        case 66:return static_cast<int>(f.hit_groups); case 67:return f.vy;
        case 68:return f.dash_kind; case 69:return f.dash_age; case 70:return f.air_dash_used;
        case 71:return f.air_jump_used; case 72:return f.teleported; case 73:return f.contact_count;
        case 74:return f.variant; case 75:return f.tether_source; case 76:return f.tether_used;
        case 77:return f.bleed_source; case 78:return f.bleed_time; case 79:return f.bleed_clock; case 80:return f.grey_life;
        case 81:return f.stance; case 82:return f.guard_button; case 83:return f.armor_left;
        case 84:return f.bounce_ground; case 85:return f.bounce_wall; case 86:return f.crumple_time;
        case 87:return f.grab_time; case 88:return f.grab_owner; case 89:return f.idle_time;
        case 90:return f.dash_pause;
        default:return 0;
    }
}
int Simulation::move_get(int c,int m,int f) const {
    if(c<0||c>=CHARACTER_COUNT||m<0||m>=MOVE_COUNT||f<0||f>=FIELD_COUNT) return -999;
    return moves[c][m].v[f];
}
int Simulation::move_set(int c,int m,int f,int v) {
    using namespace fight;
    if(c<0||c>=CHARACTER_COUNT||m<0||m>=MOVE_COUNT||f<0||f>=FIELD_COUNT) return 0;
    int low=0,high=0;
    switch(f) {
        case Mechanic: low=0; high=2; break;
        case TetherSpeed: low=100; high=4000; break;
        case TetherFrames: low=1; high=60; break;
        case BleedInitial: low=0; high=1000; break;
        case BleedTickDamage: low=0; high=1000; break;
        case BleedTickFrames: low=1; high=600; break;
        case BleedDuration: low=1; high=3600; break;
        case BleedBlockPercent: low=0; high=100; break;
        case BleedCap: low=0; high=1000; break;
        case VariantStartup: low=2; high=120; break;
        case VariantActive: low=1; high=120; break;
        case VariantRecovery: low=0; high=180; break;
        case VariantDamage: low=0; high=1000; break;
        case VariantRange: low=0; high=20000; break;
        case VariantSpeed: low=0; high=2000; break;
        case VariantLift: low=0; high=3000; break;
        case VariantHitstun: low=0; high=180; break;
        case VariantKnockdown: low=0; high=2; break;
        case Button:case SimpleButton: high=4; break;
        case Category: high=4; break;
        case Direction: low=1; high=9; break;
        case SimpleDirection: high=9; break;
        case Motion: if(v!=0&&v!=236&&v!=214&&v!=623) return 0; high=623; break;
        case Air:case SpecialCancel:case JumpCancel:case WhiffCancel:case SelfCancel:case GuardBreak:case ReversalEligible:
        case Enabled:case FollowHit: high=1; break;
        case ArtPose: high=SIGNATURE_POSES[c]; break;
        case FollowFrom:case FollowFrom2: low=-1; high=MOVE_COUNT-1; break;
        case TravelSpeed: low=-2000; high=2000; break;
        case InertiaPercent: high=200; break;
        case PullFrames: high=60; break;
        case PullGap: high=10000; break;
        case HitAngle: low=-1; high=1; break;
        case NormalCancelStart:case SpecialCancelStart:case JumpCancelStart:case FollowCancelStart: low=1; high=420; break;
        case NormalCancelEnd:case SpecialCancelEnd:case JumpCancelEnd:case FollowCancelEnd: high=420; break;
        case CancelOn:case CounterVulnerable: high=7; break;
        case StarterProration:case ComboScaling:case MinimumDamage: high=100; break;
        case LandingRecovery: high=120; break;
        case AttackLevel: low=-1; high=4; break;
        case CounterTier: low=-1; high=3; break;
        case CounterFreezeFrames: low=-1; high=60; break;
        case CounterSlowFrames: high=120; break;
        case ProjectileKind:case SmearMode: high=2; break;
        case SmearPart: high=3; break;
        case ProjectileSpawnFrame:case SmearFrame1:case SmearFrame2:case SmearFrame3:case SmearFrame4: high=420; break;
        case ProjectileSpeedX:case ProjectileSpeedY: low=-4000; high=4000; break;
        case ProjectileGravity: low=-500; high=500; break;
        case ProjectileLife: low=1; high=600; break;
        case ProjectileOffsetX:case ProjectileOffsetY: low=-50000; high=50000; break;
        case ProjectileWidth:case ProjectileHeight: low=100; high=30000; break;
        case ProjectileHits:case ProjectileDurability: low=1; high=32; break;
        case ProjectileRehit: low=1; high=120; break;
        case ProjectilePersist:case ProjectileMelee: high=1; break;
        case SmearStretch: low=100; high=400; break;
        case Startup: low=2; high=120; break;
        case Active: low=1; high=120; break;
        case Recovery:case Hitstun:case Blockstun: high=180; break;
        case Damage: high=1000; break;
        case Hitstop: high=30; break;
        case CounterHitstun: high=60; break;
        case CounterHitstop: high=30; break;
        case Reach:case Height: low=100; high=50000; break;
        case Pushback:case AirPushback:case BlockPushback:case ThrowRange: high=20000; break;
        case Launch: high=3000; break;
        case AirLaunch: low=-3000; high=3000; break;
        case Knockdown: high=2; break;
        case KnockdownFrames: low=1; high=180; break;
        case WakeupFrames: high=60; break;
        case HurtMaskWindup:case HurtMaskActive:case HurtMaskRecovery: high=15; break;
        case WallDamage: high=5000; break;
        case HitboxBack:case Bottom: low=-50000; high=50000; break;
        case Advance: low=-10000; high=10000; break;
        case NormalRoutes:case CommandRoutes: low=-1; high=31; break;
        case HitLevel: high=2; break;
        case ChipDamage: high=1000; break;
        case StanceRequired: low=0; high=2; break;
        case StanceChange: low=0; high=2; break;
        case ActionType: low=0; high=6; break;
        case HoldFollow: low=-1; high=MOVE_COUNT-1; break;
        case HoldFrame: low=0; high=420; break;
        case HoldButton: low=0; high=4; break;
        case GuardFollow: low=-1; high=MOVE_COUNT-1; break;
        case ProximityMove: low=-1; high=MOVE_COUNT-1; break;
        case ProximityRange: low=0; high=20000; break;
        case StartupTravel: low=-2000; high=2000; break;
        case DiveSpeedX: low=-2000; high=2000; break;
        case DiveSpeedY: low=-3000; high=0; break;
        case GroundBounce: low=0; high=3000; break;
        case WallBounce: low=0; high=3000; break;
        case CrumpleFrames: low=0; high=180; break;
        case AirCounterKnockdown: low=0; high=2; break;
        case HurtWindowStart: low=0; high=420; break;
        case HurtWindowEnd: low=0; high=420; break;
        case HurtWindowMask: low=0; high=15; break;
        case SemiAirStart: low=0; high=420; break;
        case SemiAirEnd: low=0; high=420; break;
        case ArmorFrames: low=0; high=120; break;
        case ArmorHits: low=0; high=8; break;
        case GrabFrames: low=0; high=120; break;
        case FinishArtPose: low=0; high=SIGNATURE_POSES[c]; break;
        case FinishArtFrame: low=0; high=420; break;
        default:return 0;
    }
    if(v<low||v>high) return 0;
    Move next=moves[c][m]; next.v[f]=v;
    if(next.v[Startup]<startup_minimum(next) || next.v[VariantStartup]<variant_startup_minimum(next)) return 0;
    moves[c][m]=next;
    return 1;
}
int Simulation::hurt_get(int c,int m,int p,int field) const {
    if(c<0||c>=CHARACTER_COUNT||m<0||m>=MOVE_COUNT||p<0||p>=HURT_PHASES||field<0||field>=HURT_FIELDS) return -999;
    const auto& h=move_hurt[c][m][p];
    if(!field) return h.count;
    const auto& b=h.boxes[(field-1)/4];
    int edge=(field-1)%4;
    return edge==0?b.left:edge==1?b.bottom:edge==2?b.right:b.top;
}
int Simulation::hurt_set(int c,int m,int p,int count,const Box* boxes) {
    if(c<0||c>=CHARACTER_COUNT||m<0||m>=MOVE_COUNT||p<0||p>=HURT_PHASES
        ||(count!=0&&count!=3&&count!=4)) return 0;
    MoveHurt next{};
    next.count=count;
    for(int i=0;i<count;++i) {
        const auto& b=boxes[i];
        if(b.left< -50000||b.left>50000||b.bottom< -50000||b.bottom>50000
            ||b.right< -50000||b.right>50000||b.top< -50000||b.top>50000
            ||b.right-b.left<100||b.top-b.bottom<100) return 0;
        next.boxes[i]=b;
    }
    move_hurt[c][m][p]=next;
    return 1;
}
int Simulation::hit_get(int c,int m,int field) const {
    if(c<0||c>=CHARACTER_COUNT||m<0||m>=MOVE_COUNT||field<0||field>=HIT_TRACK_FIELDS) return -999;
    const auto& track=move_hit[c][m];
    if(field<2) return field?track.count:track.multi;
    int index=(field-2)/HIT_KEY_FIELDS,at=(field-2)%HIT_KEY_FIELDS;
    if(index>=track.count) return 0;
    const auto& k=track.keys[index];
    const int meta[]={k.frame,k.group,k.count,k.damage,k.hitstun,k.blockstun,k.hitstop};
    if(at<7) return meta[at];
    const auto& b=k.boxes[(at-7)/4];
    int edge=(at-7)%4;
    return edge==0?b.left:edge==1?b.bottom:edge==2?b.right:b.top;
}
int Simulation::hit_clear(int c,int m,int multi) {
    if(c<0||c>=CHARACTER_COUNT||m<0||m>=MOVE_COUNT||(multi!=0&&multi!=1)) return 0;
    move_hit[c][m]=MoveHit{}; move_hit[c][m].multi=multi; return 1;
}
int Simulation::hit_add(int c,int m,const HitKey& key) {
    if(c<0||c>=CHARACTER_COUNT||m<0||m>=MOVE_COUNT) return 0;
    auto& track=move_hit[c][m];
    if(track.count>=MAX_HIT_KEYS||key.frame<1||key.frame>120||key.group<1||key.group>32
        ||key.count< -1||key.count>MAX_HITBOXES||key.damage< -1||key.damage>1000
        ||key.hitstun< -1||key.hitstun>180||key.blockstun< -1||key.blockstun>180
        ||key.hitstop< -1||key.hitstop>30||(track.count&&key.frame<=track.keys[track.count-1].frame)) return 0;
    HitKey next=key;
    for(int i=0;i<MAX_HITBOXES;++i) {
        auto& b=next.boxes[i];
        if(i>=key.count) { b=Box{}; continue; }
        if(b.left< -50000||b.left>50000||b.right< -50000||b.right>50000
            ||b.bottom< -50000||b.bottom>50000||b.top< -50000||b.top>50000
            ||b.right-b.left<100||b.top-b.bottom<100) return 0;
    }
    track.keys[track.count++]=next; return 1;
}
int Simulation::preview_place(int p,int x,int y,int momentum) {
    if(p<0||p>1||x<0||x>100000||y<0||y>50000||momentum<0||momentum>MOMENTUM_MAX) return 0;
    auto& f=world.players[p]; f.x=clamp_x(f,x); f.y=y; f.vy=0; f.momentum=momentum;
    world.players[0].facing=world.players[0].x<=world.players[1].x?1:-1;
    world.players[1].facing=-world.players[0].facing;
    return 1;
}
int Simulation::preview_begin(int p,int m) {
    if(p<0||p>1||m<0||m>=MOVE_COUNT||!moves[world.players[p].character][m].v[Enabled]) return 0;
    auto& f=world.players[p];
    if(moves[f.character][m].v[StanceRequired]) f.stance=moves[f.character][m].v[StanceRequired]==2;
    begin(f,m); return 1;
}
int Simulation::rule_get(int f) const {
    const int values[RULE_COUNT]={rules.buffer,rules.motion_window,rules.motion_gap,
        rules.move_gain,rules.attack_gain,rules.block_attack_gain,rules.damage_gain,rules.guard_gain,
        rules.special_gain,rules.fd_drain,rules.fd_block_cost,rules.fd_damage_cost,rules.fd_push_percent,
        rules.gravity_after,rules.gravity_step,rules.gravity_cap,rules.wall_threshold,rules.wall_range,
        rules.wall_decay_delay,rules.wall_decay,rules.wall_splat_frames,rules.wall_break_frames,
        rules.wall_break_damage,rules.positive_frames,rules.positive_gain_percent,rules.positive_regen,
        rules.fd_air_drain,rules.fd_level_cost,rules.corner_push_transfer,rules.wall_mid_cap,rules.grounded_wall_prime,
        rules.block_carryover,rules.throw_grace_frames,rules.air_landing_frames,rules.repeat_after,rules.repeat_gravity_step,
        rules.prejump_frames,rules.empty_landing_frames};
    return f>=0&&f<RULE_COUNT?values[f]:-1;
}
int Simulation::rule_set(int f,int v) {
    const int low[RULE_COUNT]={1,3,1,0,0,0,0,0,0,1,0,0,100, 0,0,100,1,0,0,0,1,30,0,0,100,0, 1,0,0,0,0,0,0,0,0,0, 0,0};
    const int high[RULE_COUNT]={12,30,12,100,100,100,100,100,10000,1000,10000,100,1000,
        100,100,400,10000,50000,600,1000,180,300,1000,1800,300,100, 1000,1000,1,100,1,1,30,120,100,100, 30,120};
    if(f<0||f>=RULE_COUNT||v<low[f]||v>high[f]) return 0;
    int* values[RULE_COUNT]={&rules.buffer,&rules.motion_window,&rules.motion_gap,
        &rules.move_gain,&rules.attack_gain,&rules.block_attack_gain,&rules.damage_gain,&rules.guard_gain,
        &rules.special_gain,&rules.fd_drain,&rules.fd_block_cost,&rules.fd_damage_cost,&rules.fd_push_percent,
        &rules.gravity_after,&rules.gravity_step,&rules.gravity_cap,&rules.wall_threshold,&rules.wall_range,
        &rules.wall_decay_delay,&rules.wall_decay,&rules.wall_splat_frames,&rules.wall_break_frames,
        &rules.wall_break_damage,&rules.positive_frames,&rules.positive_gain_percent,&rules.positive_regen,
        &rules.fd_air_drain,&rules.fd_level_cost,&rules.corner_push_transfer,&rules.wall_mid_cap,&rules.grounded_wall_prime,
        &rules.block_carryover,&rules.throw_grace_frames,&rules.air_landing_frames,&rules.repeat_after,&rules.repeat_gravity_step,
        &rules.prejump_frames,&rules.empty_landing_frames};
    *values[f]=v;
    return 1;
}
int Simulation::can_cancel(int c,int from,int to,int contact) const {
    using namespace fight;
    if(c<0||c>=CHARACTER_COUNT||from<0||from>=MOVE_COUNT||to<0||to>=MOVE_COUNT) return 0;
    const auto& target=moves[c][to];
    const auto& source=moves[c][from];
    if(source.v[ActionType]==1||source.v[ActionType]==2) return 0;
    if(source.v[StanceRequired]&&target.v[StanceRequired]&&source.v[StanceRequired]!=target.v[StanceRequired]) return 0;
    if(!source.v[Enabled]||!target.v[Enabled]) return 0;
    if(source.v[StanceRequired]==2&&target.v[StanceRequired]==2&&source.v[Category]==Normal) {
        if(from==to&&!source.v[SelfCancel]) return 0;
        return (contact||source.v[WhiffCancel])&&(target.v[Category]==Normal||target.v[ActionType]==2||target.v[ActionType]==4);
    }
    if(target.v[FollowFrom]>=0||target.v[FollowFrom2]>=0)
        return (from==target.v[FollowFrom]||from==target.v[FollowFrom2])&&(!target.v[FollowHit]||contact);
    return cancel_allowed(moves[c][from],moves[c][to],from==to,contact!=0);
}
bool Simulation::cancel_window(const Fighter& f,int group) const {
    if(f.move<0||group<0||group>3) return false;
    const auto& m=effective_move(f);
    int condition=f.contact?(f.event==Blocked?2:1):4;
    if(!(m.v[CancelOn]&condition)) return false;
    if(!f.contact&&!m.v[WhiffCancel]&&group!=3) return false;
    if(group==1&&!m.v[SpecialCancel]) return false;
    if(group==2&&!m.v[JumpCancel]) return false;
    if(group==3) {
        bool follow=false;
        for(const auto& target:moves[f.character]) if(target.v[Enabled]
            &&(target.v[FollowFrom]==f.move||target.v[FollowFrom2]==f.move)
            &&(!target.v[FollowHit]||(f.contact&&f.event!=Blocked))) follow=true;
        if(!follow||(!f.contact&&f.age<m.v[Startup]-1+m.v[Active])) return false;
    }
    int start=m.v[NormalCancelStart+group*2],end=m.v[NormalCancelEnd+group*2];
    // Bounds use the completed source frame; the next action replaces the next tick.
    return f.age>=start&&(end==0||f.age<=end);
}
int Simulation::mobility_get(int c,int field) const {
    return c>=0&&c<CHARACTER_COUNT&&field>=0&&field<MOBILITY_FIELDS?mobility[c].v[field]:-1;
}
int Simulation::mobility_set(int c,int field,int value) {
    const int low[MOBILITY_FIELDS]={0,1,1,1,1,1,1,1,0,0,1,1,100,0,0,1,0,-1,0,0,0,0,1,1,1,1,0,0,1,0,0,1,0,-1,-1,-1,-1,0,0,100,1,1};
    const int high[MOBILITY_FIELDS]={3,1000,2000,1000,2000,120,2000,120,500,3,1000,2000,3000,2000,2000,500,5,30,1,1,3,3,4000,4000,120,120,5,20000,2000,80000,80000,60,1,1000,1000,1000,10000,1,3,400,30,30};
    if(c<0||c>=CHARACTER_COUNT||field<0||field>=MOBILITY_FIELDS||value<low[field]||value>high[field]) return 0;
    mobility[c].v[field]=value;
    return 1;
}

void defaults() { default_simulation.defaults(); }
void reset(int a,int b,int c,int d) { default_simulation.reset(a,b,c,d); }
void step(int a,int b) { default_simulation.step(a,b); }
bool motion_matches(const Fighter& f,int at,int motion) { return default_simulation.motion_matches(f,at,motion); }
unsigned checksum() { return default_simulation.checksum(); }
}

extern "C" {
int fg_version() { return fight::VERSION; }
void fg_defaults() { fight::defaults(); }
void fg_reset(int a,int b,int c,int d) { fight::reset(a,b,c,d); }
void fg_step(int a,int b) { fight::step(a,b); }
void* fg_state_ptr() { return &fight::world; }
int fg_state_size() { return sizeof(fight::State); }
unsigned fg_checksum() { return fight::checksum(); }
unsigned fg_collision_hash() { return fight::Simulation::collision_hash(); }
int fg_box_count(int p,int kind) { return fight::default_simulation.box_count(p,kind); }
int fg_box_get(int p,int kind,int index,int edge) {
    auto b=fight::default_simulation.box(p,kind,index);
    return edge==0?b.left:edge==1?b.bottom:edge==2?b.right:edge==3?b.top:0;
}
int fg_get(int p,int f) { return fight::default_simulation.get(p,f); }
int fg_move_get(int c,int m,int f) { return fight::default_simulation.move_get(c,m,f); }
int fg_move_set(int c,int m,int f,int v) { return fight::default_simulation.move_set(c,m,f,v); }
int fg_hurt_get(int c,int m,int p,int f) { return fight::default_simulation.hurt_get(c,m,p,f); }
int fg_hit_get(int c,int m,int f) { return fight::default_simulation.hit_get(c,m,f); }
int fg_hit_clear(int c,int m,int multi) { return fight::default_simulation.hit_clear(c,m,multi); }
int fg_hit_add(int c,int m,int frame,int group,int count,int damage,int hitstun,int blockstun,int hitstop,
    int l0,int b0,int r0,int t0,int l1,int b1,int r1,int t1,int l2,int b2,int r2,int t2,int l3,int b3,int r3,int t3) {
    fight::HitKey key{frame,group,count,damage,hitstun,blockstun,hitstop,{{l0,b0,r0,t0},{l1,b1,r1,t1},{l2,b2,r2,t2},{l3,b3,r3,t3}}};
    return fight::default_simulation.hit_add(c,m,key);
}
int fg_preview_place(int p,int x,int y,int momentum) { return fight::default_simulation.preview_place(p,x,y,momentum); }
int fg_preview_begin(int p,int m) { return fight::default_simulation.preview_begin(p,m); }
int fg_hurt_set(int c,int m,int p,int count,
    int l0,int b0,int r0,int t0,int l1,int b1,int r1,int t1,
    int l2,int b2,int r2,int t2,int l3,int b3,int r3,int t3) {
    const fight::Box boxes[4]={{l0,b0,r0,t0},{l1,b1,r1,t1},{l2,b2,r2,t2},{l3,b3,r3,t3}};
    return fight::default_simulation.hurt_set(c,m,p,count,boxes);
}
int fg_pose_box_count(int c,int p,int pose) { return fight::Simulation::pose_box_count(c,p,pose); }
int fg_pose_box_get(int c,int p,int pose,int n,int edge) {
    auto b=fight::Simulation::pose_box(c,p,pose,n);
    return edge==0?b.left:edge==1?b.bottom:edge==2?b.right:edge==3?b.top:0;
}
int fg_rule_get(int f) { return fight::default_simulation.rule_get(f); }
int fg_rule_set(int f,int v) { return fight::default_simulation.rule_set(f,v); }
int fg_mobility_get(int c,int f) { return fight::default_simulation.mobility_get(c,f); }
int fg_mobility_set(int c,int f,int v) { return fight::default_simulation.mobility_set(c,f,v); }
int fg_can_cancel(int c,int from,int to,int contact) { return fight::default_simulation.can_cancel(c,from,to,contact); }
}
