#!/usr/bin/env python3
"""Immutable atlas registration and stat-timed exposure plans for Shark."""
import copy,hashlib,json,math,shutil
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]; PROD=ROOT/'art/characters/shark-kit-v2'; ART=ROOT/'godot/assets/fighters'
load=lambda p:json.loads(p.read_text())
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
def bank():
    result={}
    for rec in load(PROD/'sources.json'):
        dst=ART/'shark-kit-v2'/rec['file'];src=Path(rec['source'])
        if not src.exists():src=dst
        assert hashlib.sha256(src.read_bytes()).hexdigest()==rec['sha256']
        if src!=dst:shutil.copy2(src,dst)
        im=Image.open(dst);assert im.mode=='RGBA';w,h=im.size;frames=[]
        for index in range(rec['columns']*rec['rows']):
            row,col=divmod(index,rec['columns']);x,y=round(col*w/rec['columns']),round(row*h/rec['rows'])
            right,bottom=round((col+1)*w/rec['columns']),round((row+1)*h/rec['rows'])
            alpha=im.getchannel('A').crop((x,y,right,bottom));bounds=alpha.point(lambda a:255 if a>32 else 0).getbbox();assert bounds
            pixels=alpha.load();sole=max(yy+1 for yy in range(alpha.height) if sum(pixels[xx,yy]>128 for xx in range(alpha.width))>=8)
            frames.append(dict(file='shark-kit-v2/'+rec['file'],sha256=rec['sha256'],source_size=[w,h],region=[x,y,right-x,bottom-y],bounds=list(bounds),pivot=[rec['root'],sole],body_height=rec['body_height'],source_pose=index,
                weapon_ownership={'right':'hooked polearm','left':'triangular knife (sheathed during throws)'}))
        result[rec['id']]=frames
    return result
def source_fit(frame,head,air=False,crouch=False,extension=None):
    """Source-space anatomical registration, never weapon/sash/hair bounds."""
    l,t,r,b=head;cx=(l+r)//2;sole=frame['pivot'][1];width=frame['region'][2]
    hip=round(sole*.57) if not crouch else round(sole*.7)
    # These broad preliminary roles remain editable as ordinary phase hurtboxes.
    boxes=dict(legs=[max(15,cx-205),hip,min(width-18,cx+95),sole],
        torsoArms=[max(20,cx-115),b-12,min(width-20,cx+65),hip+20],head=head)
    if air:boxes['legs']=[max(15,cx-160),hip,min(width-20,cx+75),min(sole,hip+200)]
    if extension:boxes['extension']=extension
    fit=dict(hurt=boxes)
    if extension:fit['extensionFor']='Extended forearm/hand only. Hook, knife, rope, cloth and effects excluded.'
    return fit
def main():
    base=load(PROD/'baseline-art.json');body_base=load(PROD/'baseline-collision.json');moves=load(PROD/'moves.json')['moves'];generated=bank()
    manifest=load(ART/'manifest.json');collision=load(ROOT/'godot/data/fighter_collision.json');fighter=manifest['fighters'][4];body=collision['fighters'][4]
    frames=[];fits=[];clips={};plans={};paired={};connected={}
    def old(phase,index):
        sheet=base[phase];f=copy.deepcopy(sheet['frames'][index]);f.setdefault('file',sheet['file']);f.setdefault('sha256',sheet['sha256']);f.setdefault('body_height',sheet['body_height']);f.setdefault('source_size',sheet.get('size',[1536,1024]));return f,copy.deepcopy(body_base['poses'][phase][index])
    def new(name,index,slot,role):
        f=copy.deepcopy(generated[name][index]);air=bool(moves[slot]['air']);crouch=moves[slot]['direction']==2
        if air:f['pivot'][1]=490 if name.startswith('recovery') else 480
        # Recovery sheets share the source normals' camera and anatomy scale.
        if name.startswith('recovery'):
            heads={0:[390,36,438,104],1:[410,30,468,105],2:[405,50,465,122],3:[465,130,530,207],4:[400,38,467,111],5:[398,40,461,113],6:[420,100,482,177]}
            head=heads[int(name[-1])][:]
            if name=='recovery-2' and index>=2:head=[445,110,510,183]
            if name=='recovery-3' and index>=2:head=[428,125,493,201]
            if name=='recovery-5' and index==2:head=[405,113,465,188]
            if name=='recovery-6' and index>=2:head=[310,37,374,111]
            fit=source_fit(f,head,air,crouch)
        else:
            heads={
              'command-slash':[[249,40,299,119],[308,82,366,153],[335,88,390,156],[283,82,342,158],[270,48,326,125],[251,41,306,117]],
              'cast-ground':[[255,70,307,139],[301,94,359,164],[293,64,350,134],[235,71,290,145],[258,65,313,136],[254,62,307,132]],
              'cast-air':[[269,62,322,134],[312,64,367,138],[309,83,366,160],[269,76,327,151],[270,57,327,131],[268,61,323,135]],
              'stab-ground':[[243,40,296,112],[255,61,310,132],[267,52,322,124],[240,70,296,143],[251,47,308,119],[250,40,307,113]],
              'stab-air':[[266,61,322,134],[270,93,328,165],[272,79,330,152],[263,64,321,137],[271,53,327,125],[259,48,316,123]],
              'drive-tag':[[245,39,300,116],[262,88,319,162],[243,81,301,156],[223,69,282,144],[234,65,292,139],[242,43,299,118]],
              'drive-air':[[275,34,330,113],[262,79,320,151],[270,112,329,186],[267,71,324,146],[267,43,324,120],[274,42,330,119]],
              'drive-reel':[[246,26,300,104],[296,77,353,151],[210,48,267,121],[245,45,302,120],[222,48,278,120],[245,36,300,111]],
              'drive-chase':[[254,31,310,109],[329,69,387,143],[375,98,434,173],[318,90,376,163],[313,78,370,152],[255,37,312,113]],
              'throw-forward':[[255,26,312,104],[275,45,334,121],[302,70,363,147],[286,100,346,177],[276,45,335,122],[258,34,315,111]],
              'throw-back':[[249,43,305,121],[271,68,328,144],[258,51,315,127],[280,63,338,139],[266,55,323,130],[267,63,324,139]],
            }
            head=heads[name][index];extension=None
            if role in ['Contact','Brake'] and name not in ['drive-reel','drive-chase']:
                extension=[head[2]-20,head[3]+5,min(f['region'][2]-25,head[2]+105),head[3]+65]
            fit=source_fit(f,head,air,crouch,extension)
        return f,fit
    def add(slot,tick,pair,role,clip,phase):
        f,h=copy.deepcopy(pair);h.pop('strike',None);f.update(name=moves[slot]['id']+' / '+role,action_id=moves[slot]['id'],action_frame=tick,motion_cue=role)
        s,a,r=[moves[slot][k] for k in ('startup','active','recovery')]
        start,duration=(1,s-1) if phase=='windup' else (s,a) if phase=='active' else (s+a,r)
        clip[phase].append(dict(start=(tick-start)*100//max(1,duration),phase='attack_animation',pose=len(frames)));frames.append(f);fits.append(h)
    ordinary={0:(0,0),1:(6,2),32:(1,0),2:(1,2),3:(2,0),4:(2,2),5:(3,0),6:(3,2),17:(4,0),18:(4,2),19:(5,0),20:(5,2),8:(6,0),9:(6,2)}
    fresh={10:'command-slash',12:'drive-chase',13:'drive-tag',21:'drive-air',22:'drive-reel',23:'throw-back',24:'throw-forward',28:'cast-ground',29:'cast-air',30:'stab-ground',31:'stab-air'}
    for slot,m in enumerate(moves):
        if not m['enabled']:continue
        s,a,r=[m[k] for k in ('startup','active','recovery')];clip=dict(artPose=m['artPose'],moveId=m['id'],windup=[],active=[],recovery=[],exposureTiming=dict(style='held load / first-active snap / staged withdrawal',authoredTiming=[s,a,r],largestMotionBoundary=[s-1,s]))
        ready=old('active',8) if m['air'] else old('active',11) if m['direction']==2 else old('ready',0)
        cues=[]
        if slot==7:
            cues=[(1,old('attack_animation',0),'Coil'),(max(2,s//2),old('attack_animation',1),'Loaded · hold to first active'),(s,old('attack_animation',2),'First-active scoop'),(s+1,old('attack_animation',3),'Second hit · rise'),(s+3,old('attack_animation',4),'Crest'),(s+a,old('attack_animation',5),'Brake'),(s+a+max(2,r//3),old('attack_animation',6),'Withdraw'),(s+a+2*r//3,old('attack_animation',7),'Settle')]
        elif slot in ordinary or slot==11:
            selector=m['artPose']-1;old_clip=base['attack_animations'][str(slot)]
            entry=next((old(k['phase'],k['pose']) for k in old_clip['windup'] if k['phase']=='attack_animation'),ready)
            cues=[(1,entry,'Entry'),(max(2,(s-1)//2),old('signature_windup',selector),'Loaded · hold to first active'),(s,old('signature_active',selector),'First-active snap')]
            if slot==20:cues.append((s+2,old('attack_animation',24),'Downward cut'))
            if slot==11:brake,withdraw=old('attack_animation',23),old('attack_animation',22)
            else:
                sheet,row=ordinary[slot];brake=new('recovery-'+str(sheet),row,slot,'Brake');withdraw=new('recovery-'+str(sheet),row+1,slot,'Withdraw')
            cues.extend([(s+a,old('attack_animation',24) if slot==20 else old('signature_active',selector),'Contact hold'),(s+a+max(1,r//5),brake,'Brake'),(s+a+max(2,r//2),withdraw,'Withdraw'),(s+a+max(3,4*r//5),entry,'Settle')])
        else:
            name=fresh[slot];throw=slot in (23,24)
            # Known malformed candidate poses remain in immutable sources, never in clips.
            if throw:
                cues=[(1,new(name,0,slot,'Loaded'),'Loaded'),(s,new(name,1,slot,'Contact'),'Reach / latch attempt'),(s+a,new(name,4,slot,'Withdraw'),'Withdraw on whiff'),(s+a+r//2,new(name,5,slot,'Settle'),'Recover weapon'),(s+a+4*r//5,ready,'Settle')]
            else:
                load_pose=new(name,1,slot,'Loaded');contact=new(name,2,slot,'Contact')
                brake=contact if name=='cast-ground' else new(name,3,slot,'Brake')
                settle=new(name,5,slot,'Settle') if name not in ['drive-chase','drive-air','drive-tag'] else ready
                cues=[(1,ready,'Entry'),(max(2,(s-1)//3),load_pose,'Loaded · hold to first active'),(s,contact,'First-active snap'),(s+a,contact,'Contact hold'),(s+a+max(1,r//5),brake,'Brake'),(s+a+max(2,r//2),new(name,4,slot,'Withdraw'),'Withdraw'),(s+a+max(3,4*r//5),settle,'Settle')]
                if name=='drive-reel':cues=cues[1:];cues[0]=(1,load_pose,'Loaded · hold to first active')
                if name in ['cast-ground','cast-air']:
                    # The separate hook returns over the first 8 recovery ticks.
                    cues[-1]=(s+a+max(8,4*r//5),settle,'Catch / shoulder rest')
        for tick,pair,role in cues:
            phase='windup' if tick<s else 'active' if tick<s+a else 'recovery';add(slot,tick,pair,role,clip,phase)
        clips[str(slot)]=clip
        plans[m['id']]=dict(slot=slot,timing=[s,a,r],keys=[dict(frame=t,source=p[0]['file'],sourcePose=p[0].get('source_pose'),region=p[0]['region'],cue=role) for t,p,role in cues])
        if slot in (23,24):
            name=fresh[slot];keys=[]
            for tick,source,role in [(0,1,'Latch'),(3,2,'Hip load')]:
                f,h=new(name,source,slot,role);f.update(name=m['id']+' / '+role,action_id=m['id'],paired=True,capture_tick=tick,motion_cue=role)
                keys.append(dict(tick=tick,phase='attack_animation',pose=len(frames)));frames.append(f);fits.append(h)
            paired[str(slot)]=dict(moveId=m['id'],keys=keys)
            success=copy.deepcopy(clip);success['active']=[];success['recovery']=[]
            add(slot,s,new(name,3,slot,'Contact'),'Throw release',success,'active')
            for tick,source,role in [(s+a,3,'Release hold'),(s+a+r//3,4,'Withdraw'),(s+a+2*r//3,5,'Recover weapon')]:
                add(slot,tick,new(name,source,slot,role),role,success,'recovery')
            connected[str(slot)]=success
    fx=generated['line-effects'];record=next(r for r in load(PROD/'sources.json') if r['id']=='line-effects')
    for f in fx:
        l,t,r,b=f['bounds'];x,y,w,h=f['region'];f['region']=[x+l,y+t,r-l,b-t];f['bounds']=[0,0,r-l,b-t];f['pivot']=[0,b-t]
    fighter['line_fx']=dict(file='shark-kit-v2/line-effects.png',sha256=record['sha256'],size=[1536,1024],frames=fx)
    # Add separately generated weapon arcs to the authored strike rectangle only.
    for f in frames:
        if f.get('paired'):continue
        slot=next(i for i,m in enumerate(moves) if m['id']==f['action_id']);m=moves[slot];tick=f['action_frame'];s=m['startup'];end=s+m['active']
        if tick<s or tick>=end+max(1,m['recovery']//5):continue
        if slot not in [2,3,6,7,10,11,13,19,20,21,32]:continue
        key=next((k for k in reversed(m['hitboxTimeline']['keys']) if k['frame']<=min(m['active'],tick-s+1)),None)
        boxes=key.get('boxes') if key else None
        if not boxes:boxes=[[m['hitboxBack'],m['bottom'],m['reach'],m['bottom']+m['height']]]
        box=[min(b[0] for b in boxes)/100,min(b[1] for b in boxes)/100,max(b[2] for b in boxes)/100,max(b[3] for b in boxes)/100]
        f['effect']=dict(sheet='line_fx',pose=1 if slot in (7,32) else 2 if slot in (11,20,21) else 0,box=box,opacity=.9 if tick<end else .22,behind=False)
    first=frames[0];fighter['attack_animation']=dict(file=first['file'],sha256=first['sha256'],size=first['source_size'],columns=2,rows=2,body_height=540,transparent_samples=[[0,0],[1535,0],[0,1023]],frames=frames)
    fighter['attack_animations']=clips;fighter['paired_animations']=paired;fighter['attack_connected']=connected;fighter['attack_exposure_standard']='docs/attack-animation-standard.md';body['poses']['attack_animation']=fits
    save(ART/'manifest.json',manifest);save(ROOT/'godot/data/fighter_collision.json',collision)
    save(PROD/'exposure-plans.json',dict(actions=plans,excluded={'recovery-0':[2,3],'cast-ground':[3],'drive-tag':[0,5],'drive-air':[0,5],'drive-chase':[0,5]},note='Excluded malformed candidate anatomy or weapon swaps; approved entry/reset poses reused.'))
    save(PROD/'registration.json',dict(actions=len(clips),poses=len(frames),pairedActions=len(paired),note='Source bytes unchanged. Fixed per-atlas body calibration. Max four anatomical roles; weapons/effects excluded.'))
    print(f'Shark: {len(clips)} attacks, {len(paired)} capture tracks, {len(frames)} timing cues.')
if __name__=='__main__':main()
