#include "fight.h"

namespace fight {
static_assert(sizeof(int)==4, "The snapshot ABI requires 32-bit int");
Simulation default_simulation{};
State& world=default_simulation.world;
Move (&moves)[2][MOVE_COUNT]=default_simulation.moves;
Rules& rules=default_simulation.rules;
static int min(int a,int b) { return a<b?a:b; }
static int max(int a,int b) { return a>b?a:b; }
static int clamp(int v,int lo,int hi) { return max(lo,min(v,hi)); }
static int abs(int v) { return v<0?-v:v; }
static int button_bit(int b) { return P<<b; }

void Simulation::defaults() {
    rules=Rules{};
    for(int c=0;c<2;++c) for(int i=0;i<MOVE_COUNT;++i) {
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
        if(i==13) { // Provisional character-specific Drive starters.
            m.v[Startup]=c==0?18:15;
            m.v[Reach]=c==0?12500:16000;
            m.v[Advance]=c==0?0:2600;
            m.v[SpecialCancel]=c==1;
        }
        moves[c][i]=m;
    }
}

void Simulation::reset(int c0,int c1,int s0,int s1) {
    world=State{};
    world.remaining=99*60;
    world.winner=-1;
    for(int p=0;p<2;++p) {
        Fighter& f=world.players[p];
        f.character=clamp(p?c1:c0,0,1);
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
}
bool Simulation::active(const Fighter& f) const {
    if(f.move<0) return false;
    const Move& m=moves[f.character][f.move];
    return f.age+1>=m.v[Startup]&&f.age+1<m.v[Startup]+m.v[Active];
}
void Simulation::control(Fighter& f) {
    if(f.stun>0) { --f.stun; return; }
    f.guarding=0;
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
        } else if(!(f.raw&Down)||f.y>0) f.x+=horizontal*(f.character?360:300);
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
    if(defender.y||defender.move>=0||((defender.stun||was_stunned)&&!defender.guarding)) return false;
    int away=attacker.x<defender.x?Right:Left;
    int toward=away==Left?Right:Left;
    if(!(defender.raw&away)||(defender.raw&toward)) return false;
    int level=moves[attacker.character][attacker.move].v[HitLevel];
    bool crouch=(defender.raw&Down)!=0;
    return level==0||(level==1?crouch:!crouch);
}

void Simulation::step(int raw0,int raw1) {
    int raw[2]={raw0&2047,raw1&2047};
    for(int p=0;p<2;++p) {
        Fighter& f=world.players[p];
        if(f.move<0) f.facing=f.x<=world.players[1-p].x?1:-1;
        f.raw=raw[p];
        Sample& h=f.history[world.frame%HISTORY];
        h={world.frame,direction(raw[p],f.facing),raw[p]&~f.previous,raw[p],0};
        f.previous=raw[p];
    }
    if(world.winner>=0) { ++world.frame; return; }
    if(world.hitstop>0) { --world.hitstop; ++world.frame; return; }
    const int prior_stun[2]={world.players[0].stun,world.players[1].stun};
    const int prior_guard[2]={world.players[0].guarding,world.players[1].guarding};
    for(auto& f:world.players) {
        control(f);
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
    int hits[2]={-1,-1}; bool blocked[2]={false,false};
    for(int p=0;p<2;++p) {
        Fighter& f=world.players[p]; Fighter& other=world.players[1-p];
        if(active(f)&&!f.hit_done&&overlaps(f,other)) {
            hits[p]=f.move; blocked[p]=blocks(f,other,prior_stun[1-p]>0);
        }
    }
    // Detect both hits before applying either, so trades do not favor player 1.
    for(int p=0;p<2;++p) if(hits[p]>=0) {
        Fighter& f=world.players[p]; Fighter& other=world.players[1-p];
        const Move& m=moves[f.character][hits[p]];
        f.hit_done=f.contact=1;
        f.event=blocked[p]?2:1;
        f.combo=blocked[p]?0:((prior_stun[1-p]&&!prior_guard[1-p])?f.combo+1:1);
        other.health=max(0,other.health-(blocked[p]?0:m.v[Damage]));
        other.stun=m.v[blocked[p]?Blockstun:Hitstun];
        other.guarding=blocked[p];
        other.move=-1; other.dash=0;
        other.x=clamp(other.x+f.facing*m.v[Pushback],2800,97200);
        world.hitstop=max(world.hitstop,m.v[Hitstop]);
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
        default:return 0;
    }
}
int Simulation::move_get(int c,int m,int f) const {
    if(c<0||c>1||m<0||m>=MOVE_COUNT||f<0||f>=FIELD_COUNT) return -999;
    return moves[c][m].v[f];
}
int Simulation::move_set(int c,int m,int f,int v) {
    using namespace fight;
    if(c<0||c>1||m<0||m>=MOVE_COUNT||f<0||f>=FIELD_COUNT) return 0;
    int low=0,high=0;
    switch(f) {
        case Button:case SimpleButton: high=4; break;
        case Category: high=3; break;
        case Direction: low=1; high=9; break;
        case SimpleDirection: high=9; break;
        case Motion: if(v!=0&&v!=236&&v!=214&&v!=623) return 0; high=623; break;
        case Air:case SpecialCancel:case JumpCancel:case WhiffCancel:case SelfCancel: high=1; break;
        case Startup:case Active: low=1; high=120; break;
        case Recovery:case Hitstun:case Blockstun: high=180; break;
        case Damage: high=1000; break;
        case Hitstop: high=30; break;
        case Reach:case Height: low=100; high=50000; break;
        case Pushback: high=20000; break;
        case Bottom: low=-50000; high=50000; break;
        case Advance: low=-10000; high=10000; break;
        case NormalRoutes:case CommandRoutes: low=-1; high=31; break;
        case HitLevel: high=2; break;
        case Reserved: high=0; break;
        default:return 0;
    }
    if(v<low||v>high) return 0;
    moves[c][m].v[f]=v;
    return 1;
}
int Simulation::rule_get(int f) const {
    return f==0?rules.buffer:f==1?rules.motion_window:f==2?rules.motion_gap:-1;
}
int Simulation::rule_set(int f,int v) {
    if(f==0&&v>=1&&v<=12) rules.buffer=v;
    else if(f==1&&v>=3&&v<=30) rules.motion_window=v;
    else if(f==2&&v>=1&&v<=12) rules.motion_gap=v;
    else return 0;
    return 1;
}
int Simulation::can_cancel(int c,int from,int to,int contact) const {
    using namespace fight;
    if(c<0||c>1||from<0||from>=MOVE_COUNT||to<0||to>=MOVE_COUNT) return 0;
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
