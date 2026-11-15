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
    for(int c=0;c<CHARACTER_COUNT;++c) for(int i=0;i<MOVE_COUNT;++i)
        moves[c][i]=STARTER_MOVES[c][i];
    for(int c=0;c<CHARACTER_COUNT;++c) mobility[c]=STARTER_MOBILITY[c];
}

void Simulation::reset(int c0,int c1,int s0,int s1) {
    world=State{};
    world.remaining=99*60;
    world.winner=-1;
    world.wall_break_actor=-1;
    for(int p=0;p<2;++p) {
        Fighter& f=world.players[p];
        f.character=clamp(p?c1:c0,0,CHARACTER_COUNT-1);
        f.simple=(p?s1:s0)!=0;
        f.x=p?58000:42000;
        f.facing=p?-1:1;
        f.health=1000;
        f.move=f.last_move=-1;
        f.pull_owner=-1;
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
static bool faultless_requested(const Fighter& f) {
    int horizontal=((f.raw&Right)!=0)-((f.raw&Left)!=0);
    if(horizontal*f.facing!=-1) return false;
    int buttons=f.raw&(P|K|S|Hs);
    // Grounded 4P+K belongs to back throw. FD remains on the macro or other pairs.
    if(f.y==0&&direction(f.raw,f.facing)==4&&buttons==(P|K)&&!(f.raw&Faultless)) return false;
    return (f.raw&Faultless)||(buttons&&(buttons&(buttons-1)));
}
void Simulation::gain_momentum(Fighter& f,int amount) {
    if(f.faultless||amount<=0) return;
    if(f.positive_time>0) amount=amount*rules.positive_gain_percent/100;
    f.momentum=min(MOMENTUM_MAX,f.momentum+amount);
}
void Simulation::update_faultless(Fighter& f) {
    bool request=faultless_requested(f);
    f.faultless=request&&f.momentum>0&&f.move<0&&f.reaction==Free&&(f.stun==0||f.guarding);
    // Reserve the chord even with an empty meter: it falls back to ordinary guard.
    // It cannot become a buffered attack, dash or jump when the shield is released.
    if(request) f.history[world.frame%HISTORY].consumed|=P|K|S|Hs|D|Dash|Up;
    if(f.faultless) f.momentum=max(0,f.momentum-rules.fd_drain);
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
    const bool throw_chord=f.y==0&&(h.held&(P|K|S|Hs|D))==(P|K)
        &&(presses&(P|K))&&!(h.consumed&(P|K))&&!(h.held&(Simple|Faultless))
        &&(h.direction==4||h.direction==6);
    if(throw_chord) {
        int slot=h.direction==4?BACK_THROW:FORWARD_THROW;
        return moves[f.character][slot].v[Enabled]?slot:-1;
    }
    int best=-1,best_priority=-1;
    bool simplified=f.simple&&(h.held&Simple);
    for(int i=0;i<MOVE_COUNT;++i) {
        const Move& m=moves[f.character][i];
        if(!m.v[Enabled]||m.v[Category]==Throw) continue;
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
            if(i==SWEEP&&dir_matches(2,h.direction)) priority=45;
            else if(i==SWEEP) continue;
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
    return best;
}
void Simulation::begin(Fighter& f,int move) {
    f.move=f.last_move=move;
    f.age=f.contact=f.hit_done=f.dash=0;
    f.running=0;
    // Briefly retain run/step momentum while directions form a motion command.
    // Consume it once; later gatlings carry the attack's remaining velocity.
    if(f.carry_time>0&&abs(f.carry_vx)>abs(f.vx)) f.vx=f.carry_vx;
    f.carry_vx=f.carry_time=0;
    f.vx=clamp(f.vx*moves[f.character][move].v[InertiaPercent]/100,-4000,4000);
    f.x+=moves[f.character][move].v[Advance]*f.facing;
    int kind=moves[f.character][move].v[Category];
    if(kind==Special||kind==Drive) gain_momentum(f,rules.special_gain);
}
bool Simulation::active(const Fighter& f) const {
    if(f.move<0) return false;
    const Move& m=moves[f.character][f.move];
    return f.age+1>=m.v[Startup]&&f.age+1<m.v[Startup]+m.v[Active];
}
bool Simulation::double_forward(const Fighter& f,const Sample& h) const {
    const int forward=f.facing==1?Right:Left;
    if(h.direction!=6||!(h.pressed&forward)||(h.consumed&forward)) return false;
    for(int n=h.frame-1;n>=max(0,h.frame-10);--n) {
        const Sample* old=sample(f,n);
        if(old&&old->direction==6&&(old->pressed&forward)&&!(old->consumed&forward)) return true;
    }
    return false;
}
void Simulation::control(Fighter& f) {
    if(f.reaction!=Free) {
        f.vx=f.running=f.dash=0;
        f.carry_vx=f.carry_time=0;
        f.reversal_ready=1;
        f.stun=max(0,f.stun-1);
        if(f.reaction==WallSplat) {
            if(--f.wall_time<=0) {
                f.reaction=AirReel; f.knockdown=SoftKnockdown;
                f.down_frames=6; f.wakeup_frames=8; f.vy=0;
                // A missed wall-break opportunity does not permit an immediate re-splat.
                f.wall_damage=0;
            }
        } else if(f.reaction==Downed||f.reaction==Waking) {
            if(--f.recovery_time<=0) {
                if(f.reaction==Downed&&f.wakeup_frames>0) {
                    f.reaction=Waking; f.recovery_time=f.wakeup_frames;
                } else {
                    f.reaction=Free; f.knockdown=f.stun=f.combo_received=0;
                    f.recovery_time=0;
                }
            }
        }
        return;
    }
    if(f.stun>0) {
        f.vx=f.running=f.dash=0;
        f.carry_vx=f.carry_time=0;
        f.reversal_ready=1;
        if(f.guarding) ++f.block_age;
        --f.stun;
        return;
    }
    // This opportunity exists for exactly the first actionable tick after stun.
    // The ordinary input buffer supplies execution leniency; it grants no invulnerability.
    bool reversal=f.reversal_ready!=0;
    f.reversal_ready=0;
    f.guarding=f.block_reaction=f.block_age=f.block_advantage=f.guard_break=0;
    if(faultless_requested(f)&&f.move<0) {
        f.dash=f.running=0;
        f.carry_vx=f.carry_time=0;
        if(f.y==0) f.vx=0;
        return;
    }
    for(int n=world.frame;n>=max(0,world.frame-rules.buffer+1);--n) {
        Sample* h=sample(f,n);
        if(!h) continue;
        if((h->pressed&Up)&&!(h->consumed&Up)&&f.y==0&&!(f.simple&&(h->held&Simple))) {
            bool can=f.move<0;
            if(!can) {
                const Move& m=moves[f.character][f.move];
                can=m.v[JumpCancel]&&(f.contact||m.v[WhiffCancel]);
            }
            if(can) {
                f.vy=1450; f.y=1; f.move=-1; f.dash=f.running=0;
                h->consumed|=Up;
                break;
            }
        }
        const int target=requested(f,*h);
        bool chain=target>=0&&(moves[f.character][target].v[FollowFrom]>=0||moves[f.character][target].v[FollowFrom2]>=0);
        bool chain_window=!chain||(f.move>=0&&(f.contact||f.age>=moves[f.character][f.move].v[Startup]-1+moves[f.character][f.move].v[Active]));
        if(target>=0&&chain_window&&(f.move<0||can_cancel(f.character,f.move,target,f.contact!=0))) {
            if(reversal&&f.move<0&&moves[f.character][target].v[ReversalEligible]) {
                f.reversal_time=NOTICE_TICKS;
                f.reversal_input_age=world.frame-h->frame;
            }
            begin(f,target);
            h->consumed|=h->pressed; // A chord cannot become multiple buffered attacks.
            // Older attacks must not fire after the newly chosen command.
            for(auto& old:f.history) if(old.frame<n) old.consumed|=old.pressed;
            return;
        }
        bool macro=(h->pressed&Dash)&&!(h->consumed&Dash);
        if(f.move<0&&f.y==0&&(macro||double_forward(f,*h))) {
            const auto& profile=mobility[f.character];
            bool backwards=macro&&h->direction%3==1;
            f.running=!backwards&&profile.v[ForwardStyle]==ForwardRun;
            f.dash=f.running?0:profile.v[backwards?BackFrames:StepFrames];
            f.dash_direction=f.facing*(backwards?-1:1);
            if(f.dash) f.vx=f.dash_direction*profile.v[backwards?BackSpeed:StepSpeed];
            h->consumed|=Dash|Left|Right;
            for(auto& old:f.history) if(old.frame<h->frame) old.consumed|=Left|Right;
            break;
        }
    }
    if(f.move<0) {
        int horizontal=((f.raw&Right)!=0)-((f.raw&Left)!=0);
        const auto& profile=mobility[f.character];
        if(f.dash>0) {
            --f.dash;
        } else if(f.y>0) {
            // A run/step jump retains horizontal speed; steering can redirect to walking speed.
            if(horizontal&&(f.vx*horizontal<=0)) f.vx=horizontal*profile.v[WalkSpeed];
        } else if(f.running&&(f.raw&Down)==0&&(horizontal==f.facing||((f.raw&Dash)&&horizontal!=-f.facing))) {
            int speed=max(0,f.vx*f.facing);
            f.vx=f.facing*min(profile.v[RunSpeed],speed+profile.v[RunAcceleration]);
        } else {
            f.running=0;
            f.vx=(f.raw&Down)?0:horizontal*profile.v[WalkSpeed];
        }
    }
}
void Simulation::move_horizontal(Fighter& f) {
    if(f.reaction!=Free||f.stun>0) return;
    if(f.move<0&&(f.running||f.dash)) {
        f.carry_vx=f.vx;
        f.carry_time=rules.buffer;
    }
    f.x+=f.vx;
    if(f.move>=0) {
        if(active(f)) f.x+=f.facing*moves[f.character][f.move].v[TravelSpeed];
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
static int pose_offset(int phase,int index) { return (phase==0?0:phase==1?12:phase==2?18:phase==3?24:28)+index; }
Pose Simulation::pose(const Fighter& f,int tick_offset) const {
    if(f.reaction==Downed) return {0,10};
    if(f.reaction==Waking) return {0,11};
    if(f.reaction==AirReel||f.reaction==WallSplat||f.reaction==Reeled) return {0,9};
    if(f.guarding&&f.block_reaction>0) return {2,(f.block_reaction-1)*2+(f.block_age>=4)};
    if(f.stun) return {0,9};
    if(f.faultless) return {2,1};
    if(f.move>=0) {
        const auto& m=moves[f.character][f.move];
        int age=f.age+tick_offset;
        if(m.v[ArtPose]>0&&age<m.v[Startup]+m.v[Active]+(m.v[HitAngle]?8:0))
            return {age<m.v[Startup]?3:4,m.v[ArtPose]-1};
        if(age<m.v[Startup]) return {1,1+m.v[Button]};
        if(age<m.v[Startup]+m.v[Active]) return {0,1+m.v[Button]};
        return {0,f.y>0?8:(f.raw&Down)?11:0};
    }
    if(f.y>0) return {0,8};
    if(f.raw&Down) return {0,11};
    int horizontal=f.raw&(Left|Right);
    if(horizontal==Left||horizontal==Right||(f.raw&Dash)) return {0,6+((world.frame+tick_offset)/(f.running?4:8))%2};
    return {0,0};
}
int Simulation::pose_box_count(int c,int phase,int index) {
    if(c<0||c>=CHARACTER_COUNT||phase<0||phase>4||index<0||index>=(phase==0?12:phase<=2?6:SIGNATURE_POSES[c])) return 0;
    return HURT_POSES[c][pose_offset(phase,index)].count;
}
Box Simulation::pose_box(int c,int phase,int index,int n) {
    if(n<0||n>=pose_box_count(c,phase,index)) return {};
    return HURT_POSES[c][pose_offset(phase,index)].boxes[n];
}
unsigned Simulation::collision_hash() { return COLLISION_HASH; }
Box Simulation::hurt_box(const Fighter& f,int index,int tick_offset) const {
    Pose art=pose(f,tick_offset);
    return transform(pose_box(f.character,art.phase,art.index,index),f);
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
    const auto& m=moves[f.character][f.move];
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
Box Simulation::attack_box(const Fighter& f,int segment,int tick_offset) const {
    const auto& m=moves[f.character][f.move];
    if(m.v[Category]==Throw) return transform({0,0,
        PUSH_PROFILES[f.character].half_width+m.v[ThrowRange],PUSH_PROFILES[f.character].standing},f);
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
    if(player<0||player>1) return 0;
    const auto& f=world.players[player];
    Pose art=pose(f);
    if(kind==HurtBox) return pose_box_count(f.character,art.phase,art.index);
    if(kind==PushBox) return 1;
    if(kind==HitBox&&f.move>=0) {
        const auto& m=moves[f.character][f.move];
        return f.age>=m.v[Startup]&&f.age<m.v[Startup]+m.v[Active]?(m.v[HitAngle]?8:1):0;
    }
    return 0;
}
Box Simulation::box(int player,int kind,int index) const {
    if(index<0||index>=box_count(player,kind)) return {};
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
    Pose art=pose(b,1);
    int count=moves[a.character][a.move].v[HitAngle]?8:1;
    for(int segment=0;segment<count;++segment) for(int i=0;i<pose_box_count(b.character,art.phase,art.index);++i)
        if(intersects(attack_box(a,segment,1),hurt_box(b,i,1))) return true;
    return false;
}
bool Simulation::blocks(const Fighter& attacker,const Fighter& defender,bool was_stunned) const {
    if(defender.reaction!=Free||moves[attacker.character][attacker.move].v[Category]==Throw) return false;
    if(defender.move>=0||((defender.stun||was_stunned)&&!defender.guarding)) return false;
    int away=attacker.x<defender.x?Right:Left;
    int toward=away==Left?Right:Left;
    if(!(defender.raw&away)||(defender.raw&toward)) return false;
    if(defender.y>0) return true; // Air guard has no high/low distinction.
    int level=moves[attacker.character][attacker.move].v[HitLevel];
    bool crouch=(defender.raw&Down)!=0;
    return level==0||(level==1?crouch:!crouch);
}

int Simulation::gravity_percent(const Fighter& f) const {
    if(f.reaction!=AirReel) return 100;
    return min(rules.gravity_cap,100+max(0,f.combo_received-rules.gravity_after)*rules.gravity_step);
}
bool Simulation::throw_invulnerable(const Fighter& f) const {
    return f.y>0||f.reaction!=Free||(f.guarding&&!f.guard_break)||(f.stun>0&&!f.guarding);
}
void Simulation::land(Fighter& f) {
    f.y=f.vy=0; f.move=-1; f.contact=f.hit_done=0;
    if(f.reaction==AirReel) {
        f.reaction=Downed; f.recovery_time=max(1,f.down_frames);
        f.stun=0; f.guarding=f.guard_break=f.block_reaction=0;
    }
}
void Simulation::reel_targets() {
    for(int p=0;p<2;++p) {
        auto& f=world.players[p];
        if(f.reaction!=Reeled) continue;
        auto& owner=world.players[1-p];
        if(f.pull_time<=0||f.pull_owner!=1-p||owner.reaction!=Free||(owner.stun>0&&!owner.guarding)) {
            f.pull_time=0; f.pull_owner=-1;
            f.reaction=f.y>0?AirReel:Free;
            continue;
        }
        int space=PUSH_PROFILES[f.character].half_width+PUSH_PROFILES[owner.character].half_width+f.pull_gap;
        int target_x=clamp_x(f,owner.x+owner.facing*space);
        f.x+=(target_x-f.x)/f.pull_time;
        f.y+=(owner.y-f.y)/f.pull_time;
        f.vy=0;
        if(--f.pull_time==0) {
            f.pull_owner=-1;
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
        f.pull_owner=-1;
        f.previous=f.raw=saved.raw; // A held transition input cannot become a fresh press.
        f.combo_display=saved.combo_display; f.combo_time=saved.combo_time;
        for(auto& h:f.history) { h.frame=-1000; h.direction=5; }
    }
    world.hitstop=0;
    ++world.stage;
}

void Simulation::step(int raw0,int raw1) {
    int raw[2]={raw0&INPUT_MASK,raw1&INPUT_MASK};
    for(int p=0;p<2;++p) {
        Fighter& f=world.players[p];
        if(f.move<0) f.facing=f.x<=world.players[1-p].x?1:-1;
        f.raw=raw[p];
        Sample& h=f.history[world.frame%HISTORY];
        h={world.frame,direction(raw[p],f.facing),raw[p]&~f.previous,raw[p],0};
        // A backdash pressed during guard break cannot escape through the input buffer.
        if(f.guard_break&&f.stun>0&&h.direction%3==1) h.consumed|=Dash;
        f.previous=raw[p];
    }
    if(world.winner>=0) { ++world.frame; return; }
    if(world.wall_break_time>0) {
        for(auto& f:world.players) f.history[world.frame%HISTORY].consumed=INPUT_MASK;
        // Change ground under the curtain, then reveal the neutral reset before play resumes.
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
    const int prior_stun[2]={world.players[0].stun,world.players[1].stun};
    const int prior_guard[2]={world.players[0].guarding,world.players[1].guarding};
    const int prior_reaction[2]={world.players[0].reaction,world.players[1].reaction};
    const bool prior_combo[2]={
        (prior_stun[0]>0&&!prior_guard[0])||world.players[0].reaction==AirReel||world.players[0].reaction==WallSplat||world.players[0].reaction==Reeled,
        (prior_stun[1]>0&&!prior_guard[1])||world.players[1].reaction==AirReel||world.players[1].reaction==WallSplat||world.players[1].reaction==Reeled};
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
        if(!prior_combo[p]&&f.reaction==Free) f.combo_received=0;
        if(f.positive_time>0) {
            // Passive bonus is a fixed amount, not multiplied by its own gain multiplier.
            if(!f.faultless) f.momentum=min(MOMENTUM_MAX,f.momentum+rules.positive_regen);
        }
        if(f.wall_delay>0) --f.wall_delay;
        else if(f.reaction!=WallSplat) f.wall_damage=max(0,f.wall_damage-rules.wall_decay);
        if(f.carry_time>0) --f.carry_time;
        control(f);
        move_horizontal(f);
        if(f.move<0&&!prior_stun[p]&&f.reaction==Free&&!faultless_requested(f)) moved[p]=max(0,(f.x-prior_x[p])*f.facing);
        if(f.y>0&&f.reaction!=WallSplat&&f.reaction!=Reeled) {
            f.y+=f.vy; f.vy-=85*gravity_percent(f)/100;
            if(f.y<=0) land(f);
        }
        else if(f.y<=0&&f.reaction==AirReel) land(f);
        f.x=clamp_x(f,f.x);
    }
    Fighter& a=world.players[0]; Fighter& b=world.players[1];
    reel_targets();
    resolve_push(previous_order,prior_overlap);
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
        if(f.move<0&&f.y==0&&f.vx&&(f.x-prior_x[p])*f.vx<=0) f.vx=f.carry_vx=f.carry_time=0;
    }
    int hits[2]={-1,-1}, contacts[2]={NoContact,NoContact};
    bool blocked[2]={false,false};
    for(int p=0;p<2;++p) {
        Fighter& f=world.players[p]; Fighter& other=world.players[1-p];
        if(other.reaction==Downed||other.reaction==Waking
            ||prior_reaction[1-p]==Downed||prior_reaction[1-p]==Waking) continue;
        bool throwing=f.move>=0&&moves[f.character][f.move].v[Category]==Throw;
        bool connects=false;
        if(active(f)&&!f.hit_done) {
            if(throwing) {
                int separation=PUSH_PROFILES[f.character].half_width+PUSH_PROFILES[other.character].half_width;
                connects=f.y==0&&!throw_invulnerable(other)&&!(prior_stun[1-p]>0&&!prior_guard[1-p])
                    &&(other.x-f.x)*f.facing>=0
                    &&abs(other.x-f.x)<=separation+moves[f.character][f.move].v[ThrowRange];
            } else connects=overlaps(f,other);
        }
        if(connects) {
            hits[p]=f.move; blocked[p]=blocks(f,other,prior_stun[1-p]>0);
            contacts[p]=blocked[p]?Blocked:NormalHit;
            if(!blocked[p]&&other.move>=0&&prior_stun[1-p]==0) {
                const Move& interrupted=moves[other.character][other.move];
                contacts[p]=other.age+1<interrupted.v[Startup]+interrupted.v[Active]?CounterHit:PunishHit;
            }
        }
    }
    // Simultaneous throws clash. A simultaneous strike beats a throw; no player-index bias.
    if(hits[0]>=0&&hits[1]>=0) {
        bool t0=moves[a.character][hits[0]].v[Category]==Throw;
        bool t1=moves[b.character][hits[1]].v[Category]==Throw;
        if(t0) { hits[0]=-1; a.hit_done=1; }
        if(t1) { hits[1]=-1; b.hit_done=1; }
    }
    // Detect both hits AND their classifications before changing either fighter.
    // Clear interrupted combo displays before applying either side of a trade.
    for(int p=0;p<2;++p) if(hits[p]>=0&&!blocked[p]) {
        auto& defender=world.players[1-p];
        defender.combo=defender.combo_display=defender.combo_time=defender.combo_age=0;
    }
    for(int p=0;p<2;++p) if(hits[p]>=0) {
        Fighter& f=world.players[p]; Fighter& other=world.players[1-p];
        const Move& m=moves[f.character][hits[p]];
        f.hit_done=f.contact=1;
        f.event=contacts[p];
        f.combo=blocked[p]?0:(prior_combo[1-p]?min(1000,f.combo+1):1);
        f.combo_display=f.combo>=2?f.combo:0;
        f.combo_time=f.combo>=2?COMBO_HOLD:0;
        f.combo_age=0;
        if(contacts[p]==CounterHit||contacts[p]==PunishHit) {
            f.hit_notice=contacts[p];
            f.hit_notice_time=NOTICE_TICKS;
        }
        bool fd=blocked[p]&&other.faultless;
        bool was_airborne=other.y>0;
        bool was_splatted=prior_reaction[1-p]==WallSplat;
        bool throwing=m.v[Category]==Throw;
        int damage=blocked[p]?(fd?0:m.v[ChipDamage]):m.v[Damage];
        other.health=max(0,other.health-damage);
        if(!blocked[p]) other.faultless=0;
        gain_momentum(f,m.v[Damage]*(blocked[p]?rules.block_attack_gain:rules.attack_gain));
        if(!fd) gain_momentum(other,m.v[Damage]*(blocked[p]?rules.guard_gain:rules.damage_gain));
        if(fd) other.momentum=max(0,other.momentum-rules.fd_block_cost-m.v[Damage]*rules.fd_damage_cost);
        other.stun=m.v[blocked[p]?Blockstun:Hitstun]+(contacts[p]==CounterHit?m.v[CounterHitstun]:0);
        other.guarding=blocked[p];
        other.block_age=0;
        other.guard_break=blocked[p]&&m.v[GuardBreak]&&other.stun>0;
        // Count the remaining active/recovery ticks AFTER this contact tick.
        int remaining=m.v[Startup]-1+m.v[Active]+m.v[Recovery]-(f.age+1);
        other.block_advantage=blocked[p]?m.v[Blockstun]-remaining:0;
        other.block_reaction=!blocked[p]?NoBlock:other.guard_break?BrokenGuard:
            other.block_advantage>0?PressureBlock:StableBlock;
        other.move=-1; other.dash=other.running=other.vx=other.pull_time=0;
        other.carry_vx=other.carry_time=0;
        other.pull_owner=-1;
        int push=m.v[blocked[p]?BlockPushback:was_airborne?AirPushback:Pushback]*(fd?rules.fd_push_percent:100)/100;
        int old_x=other.x;
        other.x=clamp_x(other,other.x+f.facing*push);
        // FD still creates space at the corner by transferring blocked displacement to the attacker.
        if(fd) f.x=clamp_x(f,f.x-f.facing*(push-abs(other.x-old_x)));
        if(!blocked[p]) {
            if(other.reaction==Reeled) other.reaction=was_airborne?AirReel:Free;
            other.combo_received=f.combo;
            other.knockdown=m.v[Knockdown];
            other.down_frames=m.v[KnockdownFrames];
            other.wakeup_frames=m.v[WakeupFrames];
            if(throwing&&m.v[Direction]==4) {
                // Exchange sides at contact, retaining both body widths at stage edges.
                int separation=PUSH_PROFILES[f.character].half_width+PUSH_PROFILES[other.character].half_width;
                f.x=clamp_x(f,old_x);
                other.x=clamp_x(other,f.x-f.facing*(separation+push));
                f.x=clamp_x(f,other.x+f.facing*separation);
                f.facing=-f.facing; other.facing=-f.facing;
            }
            int lift=m.v[was_airborne?AirLaunch:Launch];
            if(was_airborne||lift>0||other.knockdown!=NoKnockdown) {
                other.reaction=AirReel;
                other.y=max(1,other.y); other.vy=lift;
                if(other.knockdown==NoKnockdown) other.knockdown=SoftKnockdown;
            }
            if(m.v[PullFrames]>0) {
                other.reaction=Reeled; other.pull_time=m.v[PullFrames];
                other.pull_owner=p; other.pull_gap=m.v[PullGap]; other.vy=0;
                other.knockdown=SoftKnockdown;
            }
            // Wall damage travels with the defender; midscreen hits contribute one quarter.
            int wall_distance=min(other.x-PUSH_PROFILES[other.character].half_width,
                100000-PUSH_PROFILES[other.character].half_width-other.x);
            if(!throwing) {
                other.wall_damage=min(rules.wall_threshold,other.wall_damage+
                    (wall_distance<=rules.wall_range?m.v[WallDamage]:m.v[WallDamage]/4));
                other.wall_delay=rules.wall_decay_delay;
            }
            if(was_splatted&&!throwing) {
                other.health=max(0,other.health-rules.wall_break_damage);
                world.wall_break_time=rules.wall_break_frames;
                world.wall_break_actor=p; world.wall_break_side=other.wall_side;
                other.wall_time=0;
            } else if(!throwing&&wall_distance<=2000&&other.wall_damage>=rules.wall_threshold) {
                other.reaction=WallSplat; other.wall_time=rules.wall_splat_frames;
                other.wall_side=other.x<50000?-1:1;
                other.x=clamp_x(other,other.wall_side<0?0:100000);
                other.y=max(2000,min(12000,other.y)); other.vy=0;
            }
        }
        world.hitstop=max(world.hitstop,m.v[Hitstop]+(contacts[p]==CounterHit?m.v[CounterHitstop]:0));
    }
    for(auto& f:world.players) if(f.move>=0) {
        const Move& m=moves[f.character][f.move];
        if(++f.age>=m.v[Startup]-1+m.v[Active]+m.v[Recovery]) {
            f.move=-1; f.contact=f.hit_done=0;
        }
    }
    // A back throw is the explicit side-switch exception to movement's anti-tunneling rule.
    resolve_push(previous_order,prior_overlap&&!(hits[0]==BACK_THROW||hits[1]==BACK_THROW));
    for(auto& f:world.players) if(f.positive_time>0) --f.positive_time;
    --world.remaining;
    if(world.wall_break_time==0&&(world.remaining<=0||a.health==0||b.health==0))
        world.winner=a.health==b.health?2:a.health>b.health?0:1;
    ++world.frame;
}

unsigned Simulation::checksum() const {
    const unsigned char* bytes=reinterpret_cast<const unsigned char*>(&world);
    unsigned hash=2166136261u;
    for(unsigned i=0;i<sizeof(State);++i) hash=(hash^bytes[i])*16777619u;
    return hash;
}
int Simulation::get(int player,int field) const {
    using namespace fight;
    if(player<0) {
        switch(field) { case 0:return world.frame; case 1:return world.remaining;
        case 2:return world.hitstop; case 3:return world.winner;
        case 4:return world.wall_break_time; case 5:return world.wall_break_actor;
        case 6:return world.wall_break_side; case 7:return world.stage;
        case 8:return rules.wall_break_frames; default:return 0; }
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
        case 36:return f.wall_damage; case 37:return f.wall_time; case 38:return f.positive_time;
        case 39:return f.vx; case 40:return f.running; case 41:return f.dash;
        case 42:return f.pull_time; case 43:return f.pull_owner;
        case 44:return weapon_span(f).left; case 45:return weapon_span(f).bottom;
        case 46:return weapon_span(f).right; case 47:return weapon_span(f).top;
        case 48:return weapon_span(f).left!=weapon_span(f).right;
        case 49:return f.carry_vx; case 50:return f.carry_time;
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
        case Startup: low=MIN_STARTUP; high=120; break;
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
        case WallDamage: high=5000; break;
        case HitboxBack:case Bottom: low=-50000; high=50000; break;
        case Advance: low=-10000; high=10000; break;
        case NormalRoutes:case CommandRoutes: low=-1; high=31; break;
        case HitLevel: high=2; break;
        case ChipDamage: high=1000; break;
        default:return 0;
    }
    if(v<low||v>high) return 0;
    moves[c][m].v[f]=v;
    return 1;
}
int Simulation::rule_get(int f) const {
    const int values[RULE_COUNT]={rules.buffer,rules.motion_window,rules.motion_gap,
        rules.move_gain,rules.attack_gain,rules.block_attack_gain,rules.damage_gain,rules.guard_gain,
        rules.special_gain,rules.fd_drain,rules.fd_block_cost,rules.fd_damage_cost,rules.fd_push_percent,
        rules.gravity_after,rules.gravity_step,rules.gravity_cap,rules.wall_threshold,rules.wall_range,
        rules.wall_decay_delay,rules.wall_decay,rules.wall_splat_frames,rules.wall_break_frames,
        rules.wall_break_damage,rules.positive_frames,rules.positive_gain_percent,rules.positive_regen};
    return f>=0&&f<RULE_COUNT?values[f]:-1;
}
int Simulation::rule_set(int f,int v) {
    const int low[RULE_COUNT]={1,3,1,0,0,0,0,0,0,1,0,0,100, 0,0,100,1,0,0,0,1,30,0,0,100,0};
    const int high[RULE_COUNT]={12,30,12,100,100,100,100,100,10000,1000,10000,100,1000,
        100,100,400,10000,50000,600,1000,180,300,1000,1800,300,100};
    if(f<0||f>=RULE_COUNT||v<low[f]||v>high[f]) return 0;
    int* values[RULE_COUNT]={&rules.buffer,&rules.motion_window,&rules.motion_gap,
        &rules.move_gain,&rules.attack_gain,&rules.block_attack_gain,&rules.damage_gain,&rules.guard_gain,
        &rules.special_gain,&rules.fd_drain,&rules.fd_block_cost,&rules.fd_damage_cost,&rules.fd_push_percent,
        &rules.gravity_after,&rules.gravity_step,&rules.gravity_cap,&rules.wall_threshold,&rules.wall_range,
        &rules.wall_decay_delay,&rules.wall_decay,&rules.wall_splat_frames,&rules.wall_break_frames,
        &rules.wall_break_damage,&rules.positive_frames,&rules.positive_gain_percent,&rules.positive_regen};
    *values[f]=v;
    return 1;
}
int Simulation::can_cancel(int c,int from,int to,int contact) const {
    using namespace fight;
    if(c<0||c>=CHARACTER_COUNT||from<0||from>=MOVE_COUNT||to<0||to>=MOVE_COUNT) return 0;
    const auto& target=moves[c][to];
    if(!moves[c][from].v[Enabled]||!target.v[Enabled]) return 0;
    if(target.v[FollowFrom]>=0||target.v[FollowFrom2]>=0)
        return (from==target.v[FollowFrom]||from==target.v[FollowFrom2])&&(!target.v[FollowHit]||contact);
    return cancel_allowed(moves[c][from],moves[c][to],from==to,contact!=0);
}
int Simulation::mobility_get(int c,int field) const {
    return c>=0&&c<CHARACTER_COUNT&&field>=0&&field<MOBILITY_FIELDS?mobility[c].v[field]:-1;
}
int Simulation::mobility_set(int c,int field,int value) {
    const int low[MOBILITY_FIELDS]={0,1,1,1,1,1,1,1,0};
    const int high[MOBILITY_FIELDS]={1,1000,2000,1000,2000,60,2000,60,500};
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
int fg_rule_get(int f) { return fight::default_simulation.rule_get(f); }
int fg_rule_set(int f,int v) { return fight::default_simulation.rule_set(f,v); }
int fg_mobility_get(int c,int f) { return fight::default_simulation.mobility_get(c,f); }
int fg_mobility_set(int c,int f,int v) { return fight::default_simulation.mobility_set(c,f,v); }
int fg_can_cancel(int c,int from,int to,int contact) { return fight::default_simulation.can_cancel(c,from,to,contact); }
}
