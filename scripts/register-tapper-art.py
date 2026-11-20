#!/usr/bin/env python3
"""Register original generated PNGs. Only metadata is authored; source pixels stay intact."""
from pathlib import Path
from PIL import Image
import copy,hashlib,json,shutil
R=Path(__file__).resolve().parents[1];A=R/'godot/assets/fighters';D=A/'tapper-v1';D.mkdir(exist_ok=True)
sources={
'idle':'9f0f9e06-3a52-46d9-a49f-540df49f784d','walk':'67852ea1-711f-4dff-a6d0-e40a9d7ba434','step':'1383c375-6467-4b87-b3cd-aca5bf69ce84',
'actions-1':'e6e12039-e8f9-427e-96f3-42a8d34fc586','actions-2':'6f8f9032-9199-4573-98b9-0b3f4ba86c0b','actions-3':'e0ef7cff-e7d8-4611-acfb-d615bf69a461','actions-4':'8fe17627-d1c3-4cc9-95f6-8f483570e349','actions-5':'59c7fc2c-7287-4e16-ba8e-c1f8d5770222','actions-6':'de0ffa9c-178e-43d6-a5b4-e40215eb430e','actions-7':'5265475a-a22e-41c6-8e77-43a3a3d7aca0','actions-8':'ed6630a6-c872-4439-a1fd-9b76a6dc0fa5'}
for name,id in sources.items():
 src=Path('/workspace/generated_images')/('exec-'+id+'.png')
 if src.exists():shutil.copyfile(src,D/(name+'.png'))
 assert (D/(name+'.png')).exists(),name
# Metadata cuts follow transparent gutters, not rigid rectangles that clip extended limbs.
def frames(name,cols,roots=None):
 im=Image.open(D/(name+'.png'));assert im.mode=='RGBA' and im.size==(1536,1024)
 alpha=im.getchannel('A');out=[]
 for row in range(2):
  pixels=alpha.crop((0,row*512,1536,(row+1)*512));values=list(pixels.getdata())
  projection=[sum(values[y*1536+x]>32 for y in range(512)) for x in range(1536)]
  cuts=[0]
  for i in range(1,cols):
   ideal=1536*i//cols
   cuts.append(min(range(ideal-85,ideal+86),key=lambda x:(projection[x],abs(x-ideal))))
  cuts.append(1536)
  for i in range(cols):
   left,right=cuts[i:i+2];bbox=pixels.crop((left,0,right,512)).point(lambda v:255 if v>32 else 0).getbbox();assert bbox
   root=(roots[row][i] if roots else (i+.5)*1536/cols)
   out.append({'name':name+' '+str(row*cols+i+1),'sha256':hashlib.sha256((D/(name+'.png')).read_bytes()).hexdigest(),'generation_file':'exec-'+sources[name]+'.png','file':'tapper-v1/'+name+'.png','region':[left,row*512,right-left,512],'pivot':[round(root-left),438 if name=='step' else (468 if row==0 else 455) if name=='actions-8' else 456 if name in ['actions-1','actions-4','actions-6'] else 445 if name=='actions-5' else (465 if row==0 else 447) if name=='actions-2' else 480],'bounds':list(bbox)})
 return out
roots={1:[[180,540,910,1320],[180,520,875,1270]],2:[[230,580,950,1320],[170,535,900,1300]],3:[[210,580,960,1320],[180,550,970,1310]],4:[[210,580,970,1330],[200,580,960,1340]],5:[[185,565,940,1325],[175,570,960,1320]],6:[[225,590,950,1310],[230,580,930,1300]],7:[[230,595,960,1320],[210,575,965,1330]],8:[[205,585,955,1320],[205,580,945,1320]]}
names=['5P jab','5K kick','c.S close staff','f.S long staff','5Hs staff chop','2P low jab','2K low kick','2S low staff','2Hs launcher','2D sweep','6P anti-air','6K advancing kick','6Hs advancing staff','j.P jab','j.K kick','j.S first hit','j.S second hit','j.Hs horizontal','j.D dive','Held guard','Guard attack','Collar capture','Headbutt','Air throw','Stance P','Stance K low','Stance S hook','Stance Hs overhead','2D stance exit','Running tackle','Single punch finish','Crouch']
wind=[];active=[]
for group in range(1,9):
 f=frames('actions-'+str(group),4,roots[group])
 for col in range(4):
  f[col]['name']=names[(group-1)*4+col]+' windup'; f[col+4]['name']=names[(group-1)*4+col]+' active'
 if group==3: f[0]['render_region']=[*f[0]['region'][:3],490]
 wind+=f[:4];active+=f[4:]
idle=frames('idle',3);walk=frames('walk',4);step=frames('step',4)
def sheet(fs,name):return {'file':fs[0]['file'],'columns':4,'rows':2,'body_height':400,'sha256':hashlib.sha256((A/fs[0]['file']).read_bytes()).hexdigest(),'generation_file':'exec-'+sources[name]+'.png','frames':fs}
p=A/'manifest.json';manifest=json.loads(p.read_text());fighter=manifest['fighters'][3]
fighter['signature_windup']=sheet(wind,'actions-1');fighter['signature_active']=sheet(active,'actions-1')
fighter['ready']=sheet([idle[0]],'idle');fighter['ready'].update(columns=3)
fighter['stance']=sheet(idle[2:6],'idle');fighter['stance'].update(columns=3)
fighter['walk']=sheet(walk,'walk');fighter['run']=sheet(step,'step');fighter['run']['body_height']=400;fighter['run']['animation']='Non-looping eight-pose step dash, sampled by dash age.'
# Replace support/button art with matching new drawings as well; older block-reaction sheet is retained.
support=[idle[0],active[0],active[1],active[3],active[4],active[21],walk[0],walk[4],wind[14],active[22],active[19],active[31]]
fighter['active']=sheet(copy.deepcopy(support),'idle');fighter['windup']=sheet([idle[0],wind[0],wind[1],wind[3],wind[4],wind[21]],'idle')
manifest['status']='Tapper v1: dedicated normal/stance move windups and active poses, collar/headbutt, tackle/punch, ready/rolling idles, walk and step dash. Generated iteration artwork; no transition smear frames.'
p.write_text(json.dumps(manifest,indent=2)+'\n')
# Body-only fits authored independently from alpha silhouettes. Three named regions,
# with a fourth limb rectangle for extended jabs/kicks. Units are source-cell pixels.
def fit(frame,action=None,phase='active'):
 px,py=frame['pivot'];name=frame['name'];a=action
 crouch=a in [5,6,7,8,9,29,30,31] or phase=='stance'
 airborne=a in [13,14,15,16,17,18,23]
 top=100 if crouch else 45
 foot=420 if airborne else py
 # Crouch drawings lower head and shoulder; no staff, hooks, cloth or hair in boxes.
 if crouch: top=160 if a not in [8] else 150
 if phase=='stance':top=125
 hx=px+30; head_y=top+20
 if a in [3,4,12,18,29,30]: hx=px+65;head_y=top+70
 torso_top=head_y+45; hip=foot-170 if not crouch else foot-115
 if airborne:hip=min(hip,300)
 hurt={'legs':[px-85,hip-10,px+90,foot], 'torsoArms':[px-85,torso_top,px+85,max(torso_top+40,hip+15)],'head':[hx-32,head_y,hx+32,head_y+55]}
 note=''
 if phase=='active' and a in [0,1,5,6,10,11,13,14,24,25,26,27]:
  if a in [1,6,11,14,25]:y=foot-110 if a in [6,25] else foot-225;note='Extended attacking boot and lower leg; staff excluded.'
  else:y=torso_top+20;note='Extended striking forearm and fist; staff excluded.'
  hurt['extension']=[px+70,y,px+150,y+60]
 # Keep anatomically authored rectangles inside the cell, without using weapon alpha to fit them.
 width=frame['region'][2]
 for box in hurt.values():
  box[0]=max(1,min(width-3,box[0]));box[2]=max(box[0]+1,min(width-1,box[2]));box[1]=max(1,min(509,box[1]));box[3]=max(box[1]+1,min(511,box[3]))
 out={'hurt':hurt}
 if note:out['extensionFor']=note
 if phase=='active':out['strike']=[max(0,px+30),200,min(width-1,px+150),350]
 return out
p=R/'godot/data/fighter_collision.json';collision=json.loads(p.read_text());body=collision['fighters'][3]
body['poses']['signature_windup']=[fit(f,i,'windup') for i,f in enumerate(wind)]
body['poses']['signature_active']=[fit(f,i) for i,f in enumerate(active)]
for phase,fs in [('ready',[idle[0]]),('stance',idle[2:6]),('walk',walk),('run',step)]:body['poses'][phase]=[fit(f,None,phase) for f in fs]
body['poses']['active']=[fit(f,a,'active' if 1<=i<=5 else 'support') for i,(f,a) in enumerate(zip(support,[None,0,1,3,4,21,None,None,14,22,19,31]))]
body['poses']['windup']=[fit(f,a,'windup') for f,a in zip(fighter['windup']['frames'],[None,0,1,3,4,21])]
p.write_text(json.dumps(collision,indent=2)+'\n')
print('Registered 64 directed action poses, 4 rolling idles, 1 ready, 8 walk and 8 step poses; source PNGs unchanged.')
for name in sources:
 im=Image.open(D/(name+'.png'));a=im.getchannel('A');assert a.getextrema()[0]==0
 print(name, im.size, 'alpha range',a.getextrema())
