#include "fight.h"

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
        Move m{};
        const bool crouch=i>=4&&i<8, command=i>=8&&i<13;
        const bool special=i>=14&&i<17, air=i>=17;
        int b=i<8?i%4:command?i-8:i==13?4:i==14?0:i==15?2:i==16?3:i-17;
        m.v[Button]=b;
        m.v[Category]=command?Command:special?Special:(b==4?Drive:Normal);
        m.v[Direction]=command?6:crouch?2:5;
        m.v[Motion]=i==14||i==15?236:i==16?623:0;
        m.v[Air]=air;
        m.v[Startup]=command?12:special?14:5+b*3;
        m.v[Active]=b<2?3:5;
        m.v[Recovery]=10+b*3;
        m.v[Damage]=30+b*16+(command?15:0)+(special?30:0);
        m.v[Hitstun]=20+b*3;
        m.v[Blockstun]=12+b*2;
        m.v[Hitstop]=6+b;
        m.v[Pushback]=800+b*300;
        m.v[Reach]=8500+b*1700+(command?1500:0);
        m.v[Bottom]=air?-3000:2000;
        m.v[Height]=air?8500:8000;
        m.v[SpecialCancel]=!special&&(command||b!=4);
        m.v[JumpCancel]=!special&&b!=4&&(b==1||b==2);
        m.v[Advance]=special&&c==1?1600:0;
        m.v[SimpleDirection]=special?(i==14?6:i==15?2:8):0;
        m.v[SimpleButton]=b;
        m.v[NormalRoutes]=-1; // -1 = unified rule, otherwise a P/K/S/Hs/D bitmask.
        m.v[CommandRoutes]=-1;
        if(c==0) { m.v[Damage]+=5; m.v[Reach]+=600; }
        // Starter tuning only: Anvil, Hammer, Smoke, Tapper, Shark, Fillet.
        if(c==3) m.v[Reach]+=1000;
        if(c==4) m.v[Reach]+=800;
        if(c==5) m.v[Reach]-=400;
        if(i==13) { // Provisional character-specific Drive starters.
            const int startup[CHARACTER_COUNT]={18,15,18,17,13,14};
            const int reach[CHARACTER_COUNT]={12500,16000,14500,17500,14500,15000};
            const int advance[CHARACTER_COUNT]={0,2600,0,800,3000,2200};
            m.v[Startup]=startup[c];
            m.v[Reach]=reach[c];
            m.v[Advance]=advance[c];
            m.v[SpecialCancel]=c==1||c==4||c==5;
        }
        m.v[ChipDamage]=(m.v[Category]==Special||m.v[Category]==Drive)?max(1,m.v[Damage]/10):0;
        m.v[CounterHitstun]=4;
        m.v[CounterHitstop]=3;
        m.v[ReversalEligible]=m.v[Category]==Special||m.v[Category]==Drive;
        moves[c][i]=m;
    }
}

void Simulation::reset(int c0,int c1,int s0,int s1) {
    world=State{};
    world.remaining=99*60;
    world.winner=-1;
    for(int p=0;p<2;++p) {
        Fighter& f=world.players[p];
        f.character=clamp(p?c1:c0,0,CHARACTER_COUNT-1);
        f.simple=(p?s1:s0)!=0;
        f.x=p?58000:42000;
        f.facing=p?-1:1;
        f.health=1000;
        f.move=f.last_move=-1;
        for(auto& h:f.history) { h.frame=-1000; h.direction=5; }
    }
}

bool cancel_allowed(const Move& from,const Move& to,bool same,bool contact) {
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
    return (f.raw&Faultless)||(buttons&&(buttons&(buttons-1)));
}
void Simulation::gain_momentum(Fighter& f,int amount) {
    if(f.faultless||amount<=0) return;
    f.momentum=min(MOMENTUM_MAX,f.momentum+amount);
}
void Simulation::update_faultless(Fighter& f) {
    bool request=faultless_requested(f);
    f.faultless=request&&f.momentum>0&&f.move<0&&(f.stun==0||f.guarding);
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
    int best=-1,best_priority=-1;
    bool simplified=f.simple&&(h.held&Simple);
    for(int i=0;i<MOVE_COUNT;++i) {
        const Move& m=moves[f.character][i];
        if(m.v[Air]!=(f.y>0)) continue;
        int priority=0;
        if(simplified) {
            if(!m.v[SimpleDirection]||!(presses&button_bit(m.v[SimpleButton]))
               ||h.direction!=m.v[SimpleDirection]) continue;
            priority=50+m.v[Button];
        } else {
            if(!(presses&button_bit(m.v[Button]))) continue;
            if(m.v[Motion]) {
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
    f.x+=moves[f.character][move].v[Advance]*f.facing;
    int kind=moves[f.character][move].v[Category];
    if(kind==Special||kind==Drive) gain_momentum(f,rules.special_gain);
}
bool Simulation::active(const Fighter& f) const {
    if(f.move<0) return false;
    const Move& m=moves[f.character][f.move];
    return f.age+1>=m.v[Startup]&&f.age+1<m.v[Startup]+m.v[Active];
}
void Simulation::control(Fighter& f) {
    if(f.stun>0) {
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
        f.dash=0;
        // Air guard retains the prototype's directional air movement; grounded FD stops walking.
        if(f.y>0) f.x+=(((f.raw&Right)!=0)-((f.raw&Left)!=0))*300;
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
                f.vy=1450; f.y=1; f.move=-1; f.dash=0;
                h->consumed|=Up;
                break;
            }
        }
        const int target=requested(f,*h);
        if(target>=0&&(f.move<0||cancel_allowed(moves[f.character][f.move],
             moves[f.character][target],f.move==target,f.contact!=0))) {
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
        if(f.move<0&&f.y==0&&(h->pressed&Dash)&&!(h->consumed&Dash)) {
            f.dash=10;
            h->consumed|=Dash;
            break;
        }
    }
    if(f.move<0) {
        int horizontal=((f.raw&Right)!=0)-((f.raw&Left)!=0);
        if(f.dash>0) {
            f.x+=(horizontal?horizontal:f.facing)*850;
            --f.dash;
        } else if(!(f.raw&Down)||f.y>0) {
            const int speed[CHARACTER_COUNT]={300,360,340,320,390,380};
            f.x+=horizontal*speed[f.character];
        }
    }
}
bool Simulation::overlaps(const Fighter& a,const Fighter& b) const {
    const Move& m=moves[a.character][a.move];
    int front=a.x+a.facing*m.v[Reach], back=a.x+a.facing*1200;
    int lo=min(front,back), hi=max(front,back);
    int hurt_height=b.y==0&&(b.raw&Down)?9000:15000;
    int bottom=a.y+m.v[Bottom];
    return hi>b.x-2200&&lo<b.x+2200&&bottom<b.y+hurt_height
        &&bottom+m.v[Height]>b.y;
}
bool Simulation::blocks(const Fighter& attacker,const Fighter& defender,bool was_stunned) const {
    if(defender.move>=0||((defender.stun||was_stunned)&&!defender.guarding)) return false;
    int away=attacker.x<defender.x?Right:Left;
    int toward=away==Left?Right:Left;
    if(!(defender.raw&away)||(defender.raw&toward)) return false;
    if(defender.y>0) return true; // Air guard has no high/low distinction.
    int level=moves[attacker.character][attacker.move].v[HitLevel];
    bool crouch=(defender.raw&Down)!=0;
    return level==0||(level==1?crouch:!crouch);
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
    for(auto& f:world.players) update_faultless(f);
    if(world.hitstop>0) { --world.hitstop; ++world.frame; return; }
    const int prior_stun[2]={world.players[0].stun,world.players[1].stun};
    const int prior_guard[2]={world.players[0].guarding,world.players[1].guarding};
    const int prior_x[2]={world.players[0].x,world.players[1].x};
    int moved[2]={0,0};
    for(int p=0;p<2;++p) {
        auto& f=world.players[p];
        // Feedback clocks are fixed-tick state: pause, hitstop and rollback all agree.
        if(f.hit_notice_time>0) --f.hit_notice_time;
        if(f.reversal_time>0) --f.reversal_time;
        if(f.combo_display>0) f.combo_age=min(1000,f.combo_age+1);
        if(prior_stun[1-p]>0&&!prior_guard[1-p]) {
            if(f.combo>=2) f.combo_time=COMBO_HOLD;
        }
        else {
            f.combo=0;
            if(f.combo_time>0) --f.combo_time;
        }
        control(f);
        if(f.move<0&&!prior_stun[p]&&!faultless_requested(f)) moved[p]=max(0,(f.x-prior_x[p])*f.facing);
        if(f.y>0) {
            f.y+=f.vy; f.vy-=85;
            if(f.y<=0) { f.y=f.vy=0; f.move=-1; f.contact=f.hit_done=0; }
        }
        f.x=clamp(f.x,2800,97200);
    }
    Fighter& a=world.players[0]; Fighter& b=world.players[1];
    if(abs(a.y-b.y)<13000&&abs(a.x-b.x)<5600) {
        int sign=a.x<=b.x?1:-1;
        int half=(5600-abs(a.x-b.x)+1)/2;
        a.x=clamp(a.x-sign*half,2800,97200);
        b.x=clamp(b.x+sign*half,2800,97200);
        // Transfer any remaining overlap away from a stage edge.
        int overlap=5600-abs(a.x-b.x);
        if(overlap>0) {
            if(a.x==2800||a.x==97200) b.x=clamp(b.x+sign*overlap,2800,97200);
            else a.x=clamp(a.x-sign*overlap,2800,97200);
        }
    }
    // Only actual voluntary approach earns movement meter: no wall/pushbox or knockback farming.
    for(int p=0;p<2;++p) {
        auto& f=world.players[p];
        int distance=min(moved[p],max(0,(f.x-prior_x[p])*f.facing));
        if(distance>0) {
            int amount=distance*rules.move_gain+f.movement_remainder;
            gain_momentum(f,amount/100);
            f.movement_remainder=amount%100;
        }
    }
    int hits[2]={-1,-1}, contacts[2]={NoContact,NoContact};
    bool blocked[2]={false,false};
    for(int p=0;p<2;++p) {
        Fighter& f=world.players[p]; Fighter& other=world.players[1-p];
        if(active(f)&&!f.hit_done&&overlaps(f,other)) {
            hits[p]=f.move; blocked[p]=blocks(f,other,prior_stun[1-p]>0);
            contacts[p]=blocked[p]?Blocked:NormalHit;
            if(!blocked[p]&&other.move>=0&&prior_stun[1-p]==0) {
                const Move& interrupted=moves[other.character][other.move];
                contacts[p]=other.age+1<interrupted.v[Startup]+interrupted.v[Active]?CounterHit:PunishHit;
            }
        }
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
        f.combo=blocked[p]?0:((prior_stun[1-p]&&!prior_guard[1-p])?f.combo+1:1);
        f.combo_display=f.combo>=2?f.combo:0;
        f.combo_time=f.combo>=2?COMBO_HOLD:0;
        f.combo_age=0;
        if(contacts[p]==CounterHit||contacts[p]==PunishHit) {
            f.hit_notice=contacts[p];
            f.hit_notice_time=NOTICE_TICKS;
        }
        bool fd=blocked[p]&&other.faultless;
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
        other.move=-1; other.dash=0;
        int push=m.v[Pushback]*(fd?rules.fd_push_percent:100)/100;
        int old_x=other.x;
        other.x=clamp(other.x+f.facing*push,2800,97200);
        // FD still creates space at the corner by transferring blocked displacement to the attacker.
        if(fd) f.x=clamp(f.x-f.facing*(push-abs(other.x-old_x)),2800,97200);
        world.hitstop=max(world.hitstop,m.v[Hitstop]+(contacts[p]==CounterHit?m.v[CounterHitstop]:0));
    }
    for(auto& f:world.players) if(f.move>=0) {
        const Move& m=moves[f.character][f.move];
        if(++f.age>=m.v[Startup]-1+m.v[Active]+m.v[Recovery]) {
            f.move=-1; f.contact=f.hit_done=0;
        }
    }
    if(--world.remaining<=0||a.health==0||b.health==0)
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
        case 2:return world.hitstop; case 3:return world.winner; default:return 0; }
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
        // Eligibility contract for the future throw system. Ordinary blockstun
        // protects against grabs; guard break deliberately does not.
        case 21:return (f.guarding&&!f.guard_break)||(f.stun>0&&!f.guarding);
        case 22:return f.combo_display; case 23:return f.combo_time; case 24:return f.combo_age;
        case 25:return f.hit_notice; case 26:return f.hit_notice_time;
        case 27:return f.reversal_time; case 28:return f.reversal_input_age;
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
        case Category: high=3; break;
        case Direction: low=1; high=9; break;
        case SimpleDirection: high=9; break;
        case Motion: if(v!=0&&v!=236&&v!=214&&v!=623) return 0; high=623; break;
        case Air:case SpecialCancel:case JumpCancel:case WhiffCancel:case SelfCancel:case GuardBreak:case ReversalEligible: high=1; break;
        case Startup:case Active: low=1; high=120; break;
        case Recovery:case Hitstun:case Blockstun: high=180; break;
        case Damage: high=1000; break;
        case Hitstop: high=30; break;
        case CounterHitstun: high=60; break;
        case CounterHitstop: high=30; break;
        case Reach:case Height: low=100; high=50000; break;
        case Pushback: high=20000; break;
        case Bottom: low=-50000; high=50000; break;
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
        rules.special_gain,rules.fd_drain,rules.fd_block_cost,rules.fd_damage_cost,rules.fd_push_percent};
    return f>=0&&f<RULE_COUNT?values[f]:-1;
}
int Simulation::rule_set(int f,int v) {
    const int low[RULE_COUNT]={1,3,1,0,0,0,0,0,0,1,0,0,100};
    const int high[RULE_COUNT]={12,30,12,100,100,100,100,100,10000,1000,10000,100,1000};
    if(f<0||f>=RULE_COUNT||v<low[f]||v>high[f]) return 0;
    int* values[RULE_COUNT]={&rules.buffer,&rules.motion_window,&rules.motion_gap,
        &rules.move_gain,&rules.attack_gain,&rules.block_attack_gain,&rules.damage_gain,&rules.guard_gain,
        &rules.special_gain,&rules.fd_drain,&rules.fd_block_cost,&rules.fd_damage_cost,&rules.fd_push_percent};
    *values[f]=v;
    return 1;
}
int Simulation::can_cancel(int c,int from,int to,int contact) const {
    using namespace fight;
    if(c<0||c>=CHARACTER_COUNT||from<0||from>=MOVE_COUNT||to<0||to>=MOVE_COUNT) return 0;
    return cancel_allowed(moves[c][from],moves[c][to],from==to,contact!=0);
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
int fg_get(int p,int f) { return fight::default_simulation.get(p,f); }
int fg_move_get(int c,int m,int f) { return fight::default_simulation.move_get(c,m,f); }
int fg_move_set(int c,int m,int f,int v) { return fight::default_simulation.move_set(c,m,f,v); }
int fg_rule_get(int f) { return fight::default_simulation.rule_get(f); }
int fg_rule_set(int f,int v) { return fight::default_simulation.rule_set(f,v); }
int fg_can_cancel(int c,int from,int to,int contact) { return fight::default_simulation.can_cancel(c,from,to,contact); }
}
