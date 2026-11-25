#!/usr/bin/env python3
"""Register original generated pixels on saved action/capture clocks. No pixel edits."""
import copy, hashlib, json
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'godot/assets/fighters'
load=lambda p:json.loads(p.read_text())
def save(p,v):p.write_text(json.dumps(v,indent=2)+'\n')
# Head center/top, belt, sole, root (relative to nominal 512px cell).
# Scales are anatomical, fixed per source; weapons never determine body size.
LANDMARKS={
 'anvil':[(276,78,279,470,220),(287,117,284,467,210),(248,60,254,470,205),(290,110,294,468,220),(310,130,295,468,220),(283,117,301,468,220)],
 'hammer':[(332,148,300,475,215),(270,114,277,475,205),(337,127,293,475,215),(291,78,237,474,220),(320,158,304,474,215),(260,74,239,474,215)],
 'smoke':[(329,41,227,489,292),(280,39,212,489,255),(288,34,205,489,265),(259,31,207,492,247),(261,37,215,492,240),(277,37,216,492,257)],
 'tapper':[(354,151,282,486,235),(268,68,252,486,235),(381,173,286,486,235),(350,187,310,486,235),(280,103,273,486,235),(305,70,263,486,235)],
 'shark':[(275,70,243,469,220),(286,113,258,469,205),(270,108,267,469,220),(286,166,290,469,215),(283,125,279,469,215),(323,57,257,469,215)],
 'fillet':[(353,161,294,446,212),(268,88,260,446,160),(247,37,224,459,210),(265,131,261,459,185),(261,88,232,471,190),(257,57,236,471,210)],
}
HEIGHTS={'anvil':425,'hammer':425,'smoke':480,'tapper':470,'shark':480,'fillet':480}
FX={0:('shield_fx',1),1:('hammer_fx',0),2:('sword_fx',2),4:('line_fx',0),5:('knife_fx',0)}

def main():
 manifest=load(ART/'manifest.json');collision=load(ROOT/'godot/data/fighter_collision.json')
 masks=load(ART/'pause-weapon-regions.json')
 roster=load(ROOT/'godot/data/supers.json')['roster']
 current=load(ROOT/'godot/data/workshop/current.json');data=load(ROOT/'godot/data/workshop'/current['file'])
 sources=load(ROOT/'art/characters/supers-v1/sources.json');plans=[]
 for c,name in enumerate(['anvil','hammer','smoke','tapper','shark','fillet']):
  fighter=manifest['fighters'][c];body=collision['fighters'][c]
  fighter.setdefault('anatomical_scales',{})['supers-v1']=HEIGHTS[name]
  source=next(s for s in sources if s['id']==name);path=ROOT/source['file'];im=Image.open(path);alpha=im.getchannel('A')
  assert hashlib.sha256(path.read_bytes()).hexdigest()==source['sha256']
  cols=2 if name=='fillet' else 3;rows=3 if name=='fillet' else 2
  assert im.size==(cols*512,rows*512)
  frames=fighter.setdefault('attack_animation',dict(file='supers-v1/'+name+'.png',body_height=HEIGHTS[name],size=list(im.size),frames=[]))['frames']
  if fighter['attack_animation']['file']=='supers-v1/'+name+'.png':
   fighter['attack_animation'].update(sha256=source['sha256'],transparent_samples=[[0,0],[im.width-1,0],[0,im.height-1]])
  fits=body['poses'].setdefault('attack_animation',[])
  # Idempotent appended bank: no pre-existing animation indices move.
  first=next((i for i,f in enumerate(frames) if f.get('super_art')),len(frames));del frames[first:];del fits[first:]
  bank=[]
  for i in range(6):
   row,col=divmod(i,cols);y=row*512;pix=alpha.load()
   cuts=[0]+[min(range(x-80,x+81),key=lambda xx:(sum(pix[xx,yy]>100 for yy in range(y,y+512)),abs(xx-x))) for x in range(512,im.width,512)]+[im.width]
   x,right=cuts[col:col+2];dx=col*512-x
   bounds=alpha.crop((x,y,right,y+512)).point(lambda a:255 if a>48 else 0).getbbox();assert bounds
   cx,top,belt,sole,root=LANDMARKS[name][i];neck=top+(65 if c in [0,3] else 56)
   hurt=dict(legs=[max(12,cx-210)+dx,belt,min(right-x-8,cx+100+dx),sole],
    torsoArms=[max(12,cx-130)+dx,neck-8,cx+42+dx,belt+18],head=[cx-27+dx,top,cx+28+dx,neck])
   if i in [1,4] and c!=0:hurt['extension']=[cx+28+dx,neck-4,min(right-x-12,cx+174+dx),neck+60]
   frame=dict(file='supers-v1/'+name+'.png',sha256=source['sha256'],generation_file=Path(source['source']).name,source_size=list(im.size),region=[x,y,right-x,512],bounds=list(bounds),pivot=[root+dx,sole],body_height=HEIGHTS[name],source_pose=i,scale_group='supers-v1',super_art=True)
   if c==0 and i!=4:
    shields={0:((320,100,449,325),(370,188,409,255)),1:((406,90,507,309),(450,164,489,249)),2:((376,65,493,268),(417,130,462,205)),3:((320,144,432,366),(340,220,388,313)),5:((335,192,465,428),(388,276,425,341))}
    (l,t,r,b),(a,c1,d,e)=shields[i]
    rectangles=[(l,t,r,c1),(l,e,r,b),(l,c1,a,e),(d,c1,r,e)]
    masks[frame['file']+':'+','.join(map(str,frame['region']))]=[[[x1+dx,y1],[x2+dx,y1],[x2+dx,y2],[x1+dx,y2]] for x1,y1,x2,y2 in rectangles]
   fit=dict(hurt=hurt)
   if 'extension' in hurt:fit['extensionFor']='Extended hand and forearm only; all weapons, cloth and effects excluded.'
   bank.append((frame,fit))
  def add(pair,role):
   f,h=copy.deepcopy(pair);f['motion_cue']=role;f['name']=super['name']+' / '+role;index=len(frames);frames.append(f);fits.append(h);return index
  ready_phase='idle' if 'idle' in fighter else 'ready'
  for super in [r for r in roster if r['character']==c and r['role']!=0]:
   slot=super['slot'];m=data['characters'][c]['moves'][slot];row=0 if super['role']%2==0 or c==0 else 3
   load_pose,impact,finish=copy.deepcopy(bank[row:row+3])
   if c==0:load_pose,impact,finish=[copy.deepcopy(bank[i]) for i in [0,1,5]] # Pose 4 excluded: wrong shield arm.
   impact_clean=copy.deepcopy(impact)
   if super['cinematic'] and c in FX:
    sheet,fx=FX[c]
    impact[0]['effect']=dict(sheet=sheet,pose=fx,box=[m['hitboxBack']/100,m['bottom']/100,m['reach']/100,(m['bottom']+m['height'])/100],opacity=.94,behind=False)
   load_id=add(load_pose,'Held anticipation');impact_id=add(impact,'First-active snap');finish_id=add(finish,'Braked follow-through');clean_id=add(impact_clean,'Impact hold without lingering hitbox effect')
   clip=dict(moveId=m['id'],artPose=m['artPose'],windup=[dict(start=0,phase=ready_phase,pose=0),dict(start=28,phase='attack_animation',pose=load_id)],
    active=[dict(start=0,phase='attack_animation',pose=impact_id)],
    recovery=[dict(start=0,phase='attack_animation',pose=clean_id),dict(start=20,phase='attack_animation',pose=finish_id),dict(start=85,phase=ready_phase,pose=0)],
    exposureTiming=dict(style='held load / first-active snap / held contact / braked recovery',authoredTiming=[m['startup'],m['active'],m['recovery']],largestMotionBoundary=[m['startup']-1,m['startup']],source='supers-v1'))
   fighter.setdefault('attack_animations',{})[str(slot)]=clip
   if super['cinematic']:
    total=m['grabFrames'];keys=[]
    # Motion hits on the actual two saved cinematic impact ticks. Use hard
    # exposure changes instead of smoothed or warped generated inbetweens.
    final_impact=copy.deepcopy(bank[2 if c==0 else row+2])
    if c in FX:final_impact[0]['effect']=copy.deepcopy(impact[0]['effect'])
    second_id=add(final_impact,'Finishing impact')
    for tick,pose in [(0,impact_id),(7,clean_id),(total*18//100,load_id),(total*45//100,impact_id),(total*45//100+6,clean_id),(total*60//100,finish_id),(total*78//100,second_id),(total*78//100+6,finish_id)]:
     keys.append(dict(tick=tick,phase='attack_animation',pose=pose))
    fighter.setdefault('paired_animations',{})[str(slot)]=dict(moveId=m['id'],keys=keys)
    fighter.setdefault('attack_connected',{})[str(slot)]=dict(moveId=m['id'],windup=[],active=[],recovery=[dict(start=0,phase='attack_animation',pose=finish_id)])
   plans.append(dict(name=super['name'],character=c,slot=slot,timing=[m['startup'],m['active'],m['recovery']],cinematic=super['cinematic'],sourcePoses=[0,1,5] if c==0 else [row,row+1,row+2],bodyHeight=HEIGHTS[name]))
 # Utility FX are original generator bytes with metadata-only crops.
 src=next(s for s in sources if s['id']=='utility');im=Image.open(ROOT/src['file']);alpha=im.getchannel('A');fx=[]
 for i in range(6):
  r,c=divmod(i,3);x=c*im.width//3;y=r*im.height//2;right=(c+1)*im.width//3;bottom=(r+1)*im.height//2
  l,t,rr,b=alpha.crop((x,y,right,bottom)).point(lambda a:255 if a>64 else 0).getbbox();fx.append(dict(region=[x+l,y+t,rr-l,b-t]))
 for c,row in [(2,0),(1,3)]:
  manifest['fighters'][c].setdefault('projectile_variants',{})['31']=dict(file='supers-v1/utility.png',frames=[fx[row],fx[row+1],fx[row+2],fx[row+2]],frame_ticks=12,source=src['source'])
 save(ART/'manifest.json',manifest);save(ROOT/'godot/data/fighter_collision.json',collision)
 (ART/'pause-weapon-regions.json').write_text('{\n'+',\n'.join('  '+json.dumps(k)+': [\n    '+',\n    '.join(json.dumps(poly,separators=(',',':')) for poly in v)+'\n  ]' for k,v in masks.items())+'\n}\n')
 save(ROOT/'art/characters/supers-v1/timing-plan.json',dict(actions=plans,pixelEdits=False,excluded=[dict(file='anvil.png',pose=4,reason='Shield ownership inconsistent; not registered in any clip.')]))
 print('Registered eleven new super animations; Sky Foundry retains its approved capture. Original pixels unchanged.')
if __name__=='__main__':main()
