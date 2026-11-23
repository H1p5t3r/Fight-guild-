#!/usr/bin/env python3
"""Register immutable generated atlases; expose keys on the actual attack clock."""
import copy,hashlib,json
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'godot/assets/fighters';PROD=ROOT/'art/characters/hammer-kit-v1'
load=lambda p:json.loads(p.read_text())
def save(p,v):p.write_text(json.dumps(v,indent=2)+'\n')
# Anatomical landmarks in the generator's nominal 512x512 cells. Weapons,
# scarf, tabard, arcs and dust are deliberately excluded from body regions.
HEADS={
 'checks':[[289,121,336,182],[264,129,309,184],[258,126,304,180],[300,187,350,247],[270,197,317,255],[281,187,329,244]],
 'kicks':[[280,70,332,133],[264,69,314,133],[287,65,340,130],[345,176,397,236],[348,202,401,268],[357,176,405,239]],
 'slashes':[[309,110,356,169],[271,110,319,171],[287,113,335,173],[324,168,372,228],[264,170,311,225],[290,145,338,206]],
 'heavy_sweep':[[337,130,385,186],[244,145,292,202],[292,135,342,188],[342,190,388,250],[282,230,330,292],[285,207,333,266]],
 'lift_brace':[[311,200,354,264],[175,165,222,222],[211,180,258,239],[324,188,374,248],[304,190,352,250],[318,202,366,264]],
 'slams':[[246,130,292,189],[288,200,336,260],[255,177,306,241],[255,128,302,188],[247,128,297,190],[255,130,302,190]],
 'specials':[[310,123,357,179],[258,130,306,190],[253,120,304,180],[329,184,377,245],[161,100,211,156],[205,110,252,170]],
 'air_checks':[[296,70,350,130],[266,67,314,131],[285,68,336,131],[307,77,360,137],[276,70,326,132],[296,80,350,140]],
 'air_swings':[[325,102,374,164],[244,104,293,163],[250,78,300,141],[254,100,302,163],[229,111,280,175],[227,95,279,155]],
 'throws':[[275,113,325,171],[349,121,399,185],[245,117,294,178],[270,66,319,125],[313,96,363,159],[245,73,294,134]],
 'drive_ready':[[319,130,371,191],[358,125,409,184],[302,120,351,182],[269,56,323,113],[257,56,306,113],[319,126,370,190]],
}
# Rear support-foot centers plus a fixed body-root offset prevent sliding.
ANCHORS={
 'checks':[150,115,123,155,120,140],'kicks':[168,168,168,168,168,168],
 'slashes':[115,70,90,115,60,90],'heavy_sweep':[135,55,80,150,55,70],
 'lift_brace':[150,90,70,160,90,60],'slams':[110,75,70,115,65,65],
 'specials':[130,65,85,125,100,95],'drive_ready':[125,82,105,125,120,125],
 'throws':[102,65,90,250,250,250],
}
HEIGHTS={'checks':385,'kicks':415,'slashes':365,'heavy_sweep':365,'lift_brace':385,'slams':395,'specials':385,'air_checks':430,'air_swings':430,'throws':395,'drive_ready':425}
PLAN={0:('checks',0),4:('checks',3),1:('kicks',0),5:('kicks',3),32:('slashes',0),2:('slashes',3),3:('heavy_sweep',0),6:('heavy_sweep',3),7:('lift_brace',0),8:('lift_brace',3),11:('slams',0),15:('slams',3),14:('specials',0),16:('specials',3),17:('air_checks',0),18:('air_checks',3),19:('air_swings',0),20:('air_swings',3),23:('throws',0),24:('throws',0),41:('throws',3),42:('throws',3),13:('drive_ready',0)}

def main():
    manifest=load(ART/'manifest.json');collision=load(ROOT/'godot/data/fighter_collision.json')
    fighter=manifest['fighters'][1];body=collision['fighters'][1]
    current=load(ROOT/'godot/data/workshop/current.json');moves=load(ROOT/'godot/data/workshop'/current['file'])['characters'][1]['moves']
    bank={};sources=load(PROD/'sources.json')
    for src in sources:
        name=src['id'];path=ART/'hammer-kit-v1'/src['file'];im=Image.open(path)
        assert hashlib.sha256(path.read_bytes()).hexdigest()==src['sha256'] and im.size==(1536,1024) and im.mode=='RGBA'
        alpha=im.getchannel('A');items=[]
        if name=='effects':continue
        for i in range(6):
            row,col=divmod(i,3);y=row*512
            # Find a transparent gutter near each nominal boundary. Only metadata
            # is adjusted; no generated pixels are painted, warped or resampled.
            pix=alpha.load()
            cuts=[0]+[min(range(x-35,x+36),key=lambda xx:(sum(pix[xx,yy]>100 for yy in range(y,y+512)),abs(xx-x))) for x in (512,1024)]+[1536]
            x,right=cuts[col:col+2];dx=col*512-x;w=right-x
            bounds=alpha.crop((x,y,right,y+512)).point(lambda a:255 if a>32 else 0).getbbox();assert bounds
            head=HEADS[name][i];l,t,r,b=head;cx=(l+r)//2
            air=name.startswith('air_') or name=='throws' and i>=3
            crouch=(name in ('checks','kicks','heavy_sweep','lift_brace') and i>=3) or name=='drive_ready' and i==5
            sole=bounds[3]
            if name=='heavy_sweep' and i==4:sole=445 # Exclude the arc beneath the shoe.
            hip={'checks':[290,290,295,350,350,350],'kicks':[250,250,250,350,352,350],'slashes':[290,290,295,340,315,315],'heavy_sweep':[300,300,300,360,365,350],'lift_brace':[335,300,305,340,340,340],'slams':[285,350,330,285,335,340],'specials':[290,295,290,350,270,300],'air_checks':[240,240,240,270,285,270],'air_swings':[270,270,260,260,280,275],'throws':[280,280,280,220,250,235],'drive_ready':[300,300,290,260,260,340]}[name][i]
            if air:sole=min(510,b+330)
            pivot_x=(cx-45 if air else ANCHORS[name][i]+110)+dx
            pivot_y=hip+200 if air else sole
            legs=[max(15,cx-210),hip,min(497,cx+105),sole]
            torso=[max(20,cx-150),b-10,min(492,cx+40),hip+24]
            boxes={'legs':legs,'torsoArms':torso,'head':head}
            # Active fists/kicks and long hammer grips use the fourth body-only box.
            extra=None
            if i%3==1:
                if name in ('checks','air_checks') and i<3:extra=[r-5,b-10,475,b+65]
                elif name=='kicks' or name=='air_checks' and i>=3:extra=[cx+20,hip-25,492,min(sole,hip+100)]
                elif name=='lift_brace' and i>=3:extra=[r-10,t-15,465,b+10]
                elif name in ('slashes','heavy_sweep','specials','air_swings','slams'):
                    extra=[r-20,b+15,min(440,r+110),min(hip+30,b+110)]
            if extra and extra[0]<extra[2] and extra[1]<extra[3]:boxes['extension']=extra
            fit={'hurt':{k:[v[0]+dx,v[1],v[2]+dx,v[3]] for k,v in boxes.items()}}
            if 'extension' in boxes:fit['extensionFor']='Extended forearm/hand or kicking leg only. Hammer, scarf, cloth and VFX excluded.'
            frame=dict(file='hammer-kit-v1/'+src['file'],sha256=src['sha256'],generation_file=Path(src['source']).name,source_size=[1536,1024],region=[x,y,w,512],bounds=list(bounds),pivot=[pivot_x,pivot_y],body_height=HEIGHTS[name],source_pose=i)
            items.append((frame,fit))
        bank[name]=items
    def sheet(items):
        frames=[copy.deepcopy(p[0]) for p in items]
        return dict(file=frames[0]['file'],sha256=frames[0]['sha256'],size=[1536,1024],body_height=frames[0]['body_height'],columns=3,rows=2,frames=frames)
    # New ready/crouch loops preserve planted feet. Idle is intentionally subtle.
    idle=[bank['drive_ready'][i] for i in (3,4,3,4)]
    fighter['idle']=sheet(idle);fighter['idle']['frame_ticks']=[18,18,18,18]
    body['poses']['idle']=[copy.deepcopy(p[1]) for p in idle]
    crouch=[bank['drive_ready'][5]]*4;fighter['crouch_idle']=sheet(crouch);body['poses']['crouch_idle']=[copy.deepcopy(p[1]) for p in crouch]
    fxsrc=next(s for s in sources if s['id']=='effects');fxpath=ART/'hammer-kit-v1'/fxsrc['file'];alpha=Image.open(fxpath).getchannel('A');fxframes=[]
    for i in range(4):
        x,y=(i%2)*768,(i//2)*512;l,t,r,b=alpha.crop((x,y,x+768,y+512)).point(lambda a:255 if a>64 else 0).getbbox()
        fxframes.append(dict(region=[x+l,y+t,r-l,b-t],pivot=[0,b-t],bounds=[0,0,r-l,b-t]))
    fighter['hammer_fx']=dict(file='hammer-kit-v1/'+fxsrc['file'],sha256=fxsrc['sha256'],size=[1536,1024],frames=fxframes)
    frames=[];fits=[];clips={};plans={};paired={}
    def add(pair,slot,tick,role):
        f,h=copy.deepcopy(pair);f.update(name=moves[slot]['id']+' / '+role,action_id=moves[slot]['id'],action_frame=tick,motion_cue=role)
        index=len(frames);frames.append(f);fits.append(h);return index
    for slot,(name,row) in PLAN.items():
        m=moves[slot];s,a,r=[m[k] for k in ('startup','active','recovery')]
        load_pose,impact,withdraw=copy.deepcopy(bank[name][row:row+3])
        ready=bank['air_checks'][0] if m['air'] else bank['drive_ready'][5 if m['direction']==2 else 3]
        release=copy.deepcopy(impact)
        if slot in (2,3,6,7,11,14,15,16,19,20,32):
            fx=1 if slot in (7,16) else 2 if slot in (11,15,20) else 0
            bottom=m['bottom']/100;top=bottom+m['height']/100
            # World-space arc ends at the authored hitbox, never extending hurt.
            impact[0]['effect']=dict(sheet='hammer_fx',pose=fx,box=[35,bottom,m['reach']/100,top],opacity=.92,behind=False)
        if slot==13:impact[0]['effect']=dict(sheet='hammer_fx',pose=3,box=[-100,0,10,22],opacity=.65,behind=True)
        clip=dict(artPose=m['artPose'],moveId=m['id'],windup=[],active=[],recovery=[],exposureTiming=dict(style='held load / first-active snap / held contact / weighted withdrawal',authoredTiming=[s,a,r],largestMotionBoundary=[s-1,s],source='hammer-kit-v1'))
        cues=[]
        if s>3:cues.append((1,ready,'Entry'))
        cues.extend([(max(2 if s>3 else 1,(s-1)//3),load_pose,'Loaded · hold through final startup'),(s,impact,'First-active snap'),(s+a,release,'Brake · no lingering strike effect'),(s+a+max(1,r//3),withdraw,'Withdraw'),(s+a+max(2,4*r//5),ready,'Settle · still recovering')])
        # A 2f throw has one windup drawing. Shared pair clock supplies the latch.
        for tick,pair,role in cues:
            phase='windup' if tick<s else 'active' if tick<s+a else 'recovery'
            start,duration=(1,s-1) if phase=='windup' else (s,a) if phase=='active' else (s+a,r)
            clip[phase].append(dict(start=(tick-start)*100//max(1,duration),phase='attack_animation',pose=add(pair,slot,tick,role)))
        clips[str(slot)]=clip
        plans[m['id']]=dict(slot=slot,timing=[s,a,r],keys=[dict(frame=t,cue=role,source=p[0]['file'],sourcePose=p[0].get('source_pose')) for t,p,role in cues])
        if m['category']==4:
            paired[str(slot)]=dict(moveId=m['id'],keys=[dict(tick=0,phase='attack_animation',pose=add(load_pose,slot,0,'Collar latch')),dict(tick=3,phase='attack_animation',pose=add(impact,slot,3,'Shoulder / hip turn'))])
    fighter['attack_animation']=sheet([(frames[0],fits[0])]);fighter['attack_animation']['frames']=frames
    fighter['attack_animations']=clips;fighter['paired_animations']=paired
    body['poses']['attack_animation']=fits
    save(ART/'manifest.json',manifest);save(ROOT/'godot/data/fighter_collision.json',collision)
    save(PROD/'timing-plan.json',plans);save(PROD/'registration.json',dict(actions=len(clips),poses=len(frames),idlePoses=8,pairedActions=len(paired),largestMotion='Last startup → first active',bodyPolicy='Fixed scale per atlas, support-foot / pelvis registration; max four body-only boxes.',pixelEdits=False))
    print('Hammer: %d actions, %d action poses, 8 idle poses, %d paired tracks.'%(len(clips),len(frames),len(paired)))

if __name__=='__main__':main()
