// Hammer's movement-only Drive. No wall clock or presentation state participates.
bool Simulation::drive_window(const Fighter& f) const {
    if(f.move<0||f.y>0)return false;
    const auto& m=moves[f.character][f.move];
    return m.v[Mechanic]==5&&f.age>=m.v[Startup]-1&&f.age<m.v[Startup]-1+m.v[Active];
}

int Simulation::drive_distance(const Fighter& f,int slot) const {
    const auto& drive=moves[f.character][slot];
    const auto& target=world.players[1-(&f-world.players)];
    int distance=drive.v[DriveDistance];
    if(!distance) {
        int reach=0,push=0;
        for(int i=0;i<MOVE_COUNT;++i) {
            const auto& m=moves[f.character][i];
            if(!m.v[Enabled]||m.v[Air]||(m.v[Category]!=Normal&&m.v[Category]!=Command))continue;
            int front=0;const auto& track=move_hit[f.character][i];
            if(!track.count||track.keys[0].frame>1)front=m.v[Reach];
            for(int k=0;k<track.count&&track.keys[k].frame<=m.v[Active];++k) {
                const auto& key=track.keys[k];
                if(key.count<0)front=max(front,m.v[Reach]);
                for(int b=0;b<key.count;++b)front=max(front,key.boxes[b].right);
            }
            if(front>reach||(front==reach&&m.v[BlockPushback]>push)){reach=front;push=m.v[BlockPushback];}
        }
        // Fixed standing body geometry, not the opponent's transient animation.
        int body=0;
        const int phase=POSE_COUNTS[target.character][11]?11:0;
        for(int i=0;i<pose_box_count(target.character,phase,0);++i)body=max(body,pose_box(target.character,phase,0,i).right);
        distance=max(0,reach+body+push-PUSH_PROFILES[f.character].half_width-PUSH_PROFILES[target.character].half_width);
    }
    return clamp(distance,0,min(80000,4000*drive.v[Active]));
}

void Simulation::tick_drive_resources() {
    bool neutral=!world.pair.kind;
    for(const auto& q:world.projectiles)if(q.life>0)neutral=false;
    for(const auto& f:world.players)
        if(f.move>=0||f.stun||f.reaction!=Free||f.grab_time||f.pair_recovery||f.landing_time||f.prejump_time||f.dash||f.line_pull_time||f.slow_time)neutral=false;
    for(auto& f:world.players) {
        if(f.move<0||f.stun||f.reaction!=Free)f.drive_bonus=0;
        if(!f.drive_used)continue;
        if(!neutral){f.drive_neutral=0;continue;}
        const int slot=f.drive_source-1;
        const int duration=slot>=0?moves[f.character][slot].v[DriveNeutralFrames]:12;
        if(++f.drive_neutral>=duration){f.drive_used=f.drive_neutral=f.drive_source=0;}
    }
}
