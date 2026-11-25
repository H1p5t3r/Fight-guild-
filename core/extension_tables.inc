// Included inside namespace fight. This ABI is deliberately independent of JSON.
int Simulation::extension_get(int c,int m,int field) const {
    if(c<0||c>=CHARACTER_COUNT||m< -1||m>=MOVE_COUNT||field<0
       ||field>=(m<0?CHARACTER_EXTENSION_FIELDS:EXTENSION_FIELDS)) return 0;
    return m<0?character_extensions[c].v[field]:extensions[c][m].v[field];
}
static bool valid_extension_box(const int* b) {
    return b[0]<b[2]&&b[1]<b[3];
}
int Simulation::extension_set(int c,int m,const int* v) {
    if(c<0||c>=CHARACTER_COUNT||m< -1||m>=MOVE_COUNT||!v) return 0;
    int size=m<0?CHARACTER_EXTENSION_FIELDS:EXTENSION_FIELDS;
    for(int i=0;i<size;++i) {
        if(m>=0&&i>=XRoutes&&i<XRoutes+8) continue; // signed bit masks
        if(v[i]< -1000000||v[i]>1000000) return 0;
    }
    if(v[0]<0||v[0]>(m<0?2:1)) return 0;
    if(!v[0]) { for(int i=1;i<size;++i) if(v[i]) return 0; }
    else if(m<0) {
        if(v[CBleedDuration]<1||v[CBleedDuration]>3600||v[CBleedInterval]<1||v[CBleedInterval]>600
           ||v[CBleedCap]>999||v[CBleedCap]<0||v[CHalfWidth]<1||v[CHalfWidth]>10000
           ||v[CStanding]<1||v[CCrouching]<1||v[CAirTop]<=v[CAirBottom]
           ||v[CWalkStride]<1||v[CRunStride]<1||v[CBackdashLock]<0||v[CBackdashLock]>120) return 0;
        for(int i=1;i<18;++i) if(v[i]<0||v[i]>50000) return 0;
        for(int n=0;n<45;++n) {
            const int* p=v+CProfiles+n*17;
            if(p[0]<0||p[0]>15) return 0;
            for(int b=0;b<4;++b) if((p[0]&(1<<b))&&!valid_extension_box(p+1+b*4)) return 0;
        }
        for(int n=0;n<4;++n) {
            const int* p=v+CPairTracks+n*41;
            if(p[0]<2||p[0]>8||p[1]!=0) return 0;
            for(int i=0;i<p[0];++i) if(p[1+i*5]<0||p[1+i*5]>180||(i&&p[1+i*5]<=p[1+(i-1)*5])) return 0;
        }
    } else {
        if(v[XContactKind]<0||v[XContactKind]>3||!valid_extension_box(v+XGroundLeft)||!valid_extension_box(v+XAirLeft)) return 0;
        for(int i=XLowStart;i<=XFriction;++i) if(v[i]<0||v[i]>50000) return 0;
        if(v[XCaptureFreeze]>60||v[XReleaseFreeze]>60||v[XPairTicks]>180||v[XOwnerRecovery]>120||v[XVictimRecovery]>120
           ||v[XThrowGrace]>30||v[XTechTicks]>30||v[XPairTrack]>3||(v[XContactKind]&&v[XPairTicks]<1)||v[XReleaseGap]>80000||v[XGroundedLift]>1||v[XStopAtBody]>1) return 0;
        for(int i=0;i<4;++i) if(static_cast<unsigned>(v[XRoutes+i*2+1])>>15) return 0;
        const int offsets[4]={XHurt,XPush,XRoot,XVertical};
        for(int offset : offsets) {
            int count=v[offset],width=offset==XHurt?18:offset==XVertical?2:5;
            if(count<0||count>(offset==XHurt?32:8)) return 0;
            for(int i=0;i<count;++i) {
                const int* p=v+offset+1+i*width;
                if(p[0]<1||p[0]>420||(i&&p[0]<=p[-width])) return 0;
                if(offset==XHurt) {
                    if(p[1]<0||p[1]>15) return 0;
                    for(int b=0;b<4;++b) if((p[1]&(1<<b))&&!valid_extension_box(p+2+b*4)) return 0;
                }
                if(offset==XPush&&!valid_extension_box(p+1)) return 0;
                if(offset==XRoot&&(p[1]<p[0]||p[1]>420||p[4]<0||p[4]>2)) return 0;
            }
            if(count&&offset!=XRoot&&v[offset+1]!=1) return 0;
        }
    }
    int* out=m<0?character_extensions[c].v:extensions[c][m].v;
    for(int i=0;i<size;++i) out[i]=v[i];
    return 1;
}
