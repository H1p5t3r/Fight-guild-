#!/usr/bin/env python3
"""Register generated Smoke PNGs and body-only collision; never edit image pixels."""
from pathlib import Path
from PIL import Image
import copy,hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[1];ASSETS=ROOT/'godot/assets/fighters';DEST=ASSETS/'smoke-v1'
generation=json.loads((DEST/'generation.json').read_text())
for g in generation['generations']:
    src=Path(g['path']);out=DEST/f'actions-{g["id"]}.png'
    if src.exists():shutil.copyfile(src,out)
    assert out.exists()
names=['5P Vapor Check','5K Caustic Kick','c.S Chimney Coil','f.S Fivefold Fume','5Hs Flashover','2P Low Pressure','2K Ankle Leak','2S Soot Ribbon','2Hs Backdraft','2D Floor Spill','6P Updraft','6Hs Smoke Hammer','6[Hs] Flashpoint Hammer','5D Fire Veil','5[D] Rising Ignition','j.P Air Check','j.K Caustic Heel','j.S Vapor Lance','j.Hs Cinder Scythe','j.D Drifting Ember']
# Per-pose floor roots, independent of the bounding rectangle of the effect.
roots=[[[265,490],[205,490]],[[342,482],[227,490]],[[265,490],[248,490]],[[300,469],[230,469]],[[285,466],[247,466]],[[300,490],[250,490]],[[310,502],[220,502]],[[355,502],[260,480]],[[320,480],[220,480]],[[380,480],[330,480]]]
active_roots=[[[265,490],[205,490]],[[317,502],[162,502]],[[265,490],[248,490]],[[230,455],[177,455]],[[270,488],[240,487]],[[290,490],[240,490]],[[270,490],[225,490]],[[350,502],[260,480]],[[310,480],[200,480]],[[330,480],[330,480]]]
wind=[];active=[];offsets={'windup':[],'active':[]}
for i in range(10):
    path=DEST/f'actions-{i+1}.png';im=Image.open(path);assert im.mode=='RGBA' and im.size==(1536,1024)
    alpha=im.getchannel('A');assert alpha.getextrema()[0]==0
    pixels=list(alpha.getdata())
    row_cut=min(range(490,531),key=lambda y:(sum(v>32 for v in pixels[y*1536:(y+1)*1536]),abs(y-512)))
    for row,frames,pivots in [(0,wind,roots[i]),(1,active,active_roots[i])]:
        top,bottom=(0,row_cut) if row==0 else (row_cut,1024)
        cut=min(range(600,901),key=lambda x:(sum(pixels[y*1536+x]>32 for y in range(top,bottom)),abs(x-768)))
        for col in range(2):
            left,right=(0,cut) if col==0 else (cut,1536)
            region=[left,top,right-left,bottom-top]
            dx,dy=col*768-left,row*512-top
            offsets['windup' if row==0 else 'active'].append((dx,dy))
            bounds=alpha.crop((left,top,right,bottom)).point(lambda a:255 if a>32 else 0).getbbox();assert bounds
            frames.append({'name':names[2*i+col]+(' windup' if row==0 else ' active'),'file':'smoke-v1/'+path.name,
                'region':region,'pivot':[pivots[col][0]+dx,pivots[col][1]+dy],'bounds':list(bounds),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
                'generation_file':Path(generation['generations'][i]['path']).name})

# Source-cell anatomical rectangles: legs; torso/arms; head; optional extension.
# Do not include hood/hair, coat tails, vials or emitted gas/fire.
wind_boxes=[
 [[152,230,383,490],[172,95,341,257],[250,40,294,94]],
 [[174,230,262,490],[168,95,306,250],[226,42,266,96],[270,145,360,320]],
 [[240,290,440,482],[250,181,397,300],[350,125,392,183]],
 [[100,235,366,490],[140,102,296,248],[224,50,268,100]],
 [[152,230,383,490],[172,95,341,257],[250,40,294,94]],
 [[152,322,380,490],[170,228,310,340],[276,174,322,228]],
 [[206,275,391,469],[274,210,445,325],[384,156,424,214],[430,360,522,454]],
 [[134,272,334,469],[171,207,321,329],[264,155,306,213]],
 [[196,277,428,466],[249,184,419,300],[369,159,411,216],[127,174,249,226]],
 [[150,323,339,466],[220,249,360,370],[351,201,396,259],[362,324,451,458]],
 [[146,290,459,490],[224,194,383,318],[343,140,386,197],[388,133,451,224]],
 [[104,253,402,490],[139,105,307,274],[229,55,272,112]],
 [[138,277,489,502],[242,170,420,300],[340,126,384,181],[270,20,466,190]],
 [[70,255,378,502],[125,125,296,283],[210,77,254,130],[99,18,192,145]],
 [[178,293,527,502],[272,178,442,319],[391,138,435,189],[226,64,293,185]],
 [[200,248,394,420],[170,120,323,266],[270,65,314,116]],
 [[230,250,434,458],[192,120,355,278],[294,63,338,120]],
 [[144,236,350,400],[95,116,296,265],[213,60,257,116]],
 [[306,235,478,401],[274,112,450,257],[432,65,476,119],[453,185,537,246]],
 [[270,266,453,429],[237,125,408,283],[369,77,411,131]],
]
active_boxes=[
 [[150,235,385,490],[170,95,340,265],[245,40,289,96],[320,85,470,150]],
 [[175,230,262,490],[172,95,305,255],[230,42,274,97],[260,178,485,225]],
 [[194,270,440,502],[206,135,350,285],[265,82,310,137],[335,35,400,140]],
 [[10,252,317,502],[67,103,245,265],[130,58,174,110],[200,110,310,158]],
 [[150,235,385,490],[170,105,340,265],[245,50,289,107],[315,110,452,166]],
 [[150,340,380,490],[180,240,312,368],[264,183,310,240],[306,236,470,279]],
 [[84,327,330,453],[170,225,334,355],[272,174,318,232],[285,362,528,452]],
 [[76,280,270,453],[90,190,247,326],[190,133,237,194],[224,175,400,237]],
 [[172,326,384,488],[170,200,330,350],[260,155,304,209],[305,92,436,226]],
 [[120,350,322,487],[159,287,318,389],[302,247,344,303],[316,343,461,415]],
 [[133,314,444,490],[185,224,310,348],[270,164,312,224],[300,92,432,236]],
 [[86,290,389,490],[117,190,320,319],[207,135,250,193],[282,250,390,330]],
 [[105,313,443,490],[193,225,360,345],[310,167,354,227],[340,283,496,380]],
 [[78,253,385,490],[130,105,294,270],[228,64,272,115],[285,37,496,118]],
 [[171,305,527,502],[286,192,446,324],[402,151,446,207],[310,24,456,191]],
 [[200,248,392,404],[167,110,335,265],[265,57,309,111],[325,143,489,187]],
 [[212,269,357,372],[188,116,354,276],[287,62,331,118],[338,292,528,398]],
 [[121,232,294,439],[74,111,267,266],[163,55,207,111],[249,94,369,150]],
 [[210,277,415,418],[220,181,475,299],[408,154,452,209],[460,224,638,281]],
 [[251,263,450,448],[199,127,374,278],[339,73,383,130],[355,98,586,154]],
]
for phase,poses in [('windup',wind_boxes),('active',active_boxes)]:
    for boxes,(dx,dy) in zip(poses,offsets[phase]):
        for b in boxes:b[0]+=dx;b[2]+=dx;b[1]+=dy;b[3]+=dy
def fit(boxes,phase,index):
    out={'hurt':dict(zip(['legs','torsoArms','head','extension'],boxes))}
    if len(boxes)==4:out['extensionFor']='Extended limb only; gas, flame, hair, cloth and equipment excluded.'
    if phase=='active':out['strike']=[250,180,480,350] # move-specific traces override this fallback.
    return out
def sheet(frames):
    path=ASSETS/frames[0]['file']
    return {'file':frames[0]['file'],'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
        'size':[1536,1024],'transparent_samples':[[0,0],[1535,0],[0,1023],[1535,1023]],
        'columns':2,'rows':2,'body_height':480,'frames':copy.deepcopy(frames)}

# An optional dedicated tall launcher atlas keeps its enormous effect in frame.
launcher=next((g for g in generation.get('extras',[]) if g['id']=='launcher'),None)
if launcher:
    src=Path(launcher['path']);path=DEST/'launcher.png'
    if src.exists():shutil.copyfile(src,path)
    im=Image.open(path);assert im.size==(1536,1024) and im.mode=='RGBA'
    for col,fs in [(0,wind),(1,active)]:
        left,right=(0,600) if col==0 else (600,1536)
        old=fs[8];old.update(file='smoke-v1/launcher.png',region=[left,0,right-left,1024],pivot=[270 if col==0 else 320,986],
            bounds=list(im.getchannel('A').crop((left,0,right,1024)).getbbox()),
            sha256=hashlib.sha256(path.read_bytes()).hexdigest(),generation_file=src.name)
    wind_boxes[8]=[[211,825,405,984],[220,736,384,864],[365,700,406,752],[365,844,506,962]]
    active_boxes[8]=[[229,819,440,985],[245,723,417,848],[357,674,399,727],[403,611,538,753]]

p=ASSETS/'manifest.json';manifest=json.loads(p.read_text());fighter=manifest['fighters'][2]
# Retain existing locomotion/reaction source scaling in a mixed support atlas.
old=copy.deepcopy(fighter['active']);old_body=json.loads((ROOT/'godot/data/fighter_collision.json').read_text())['fighters'][2]
support=copy.deepcopy(old['frames']);support_fits=copy.deepcopy(old_body['poses']['active'])
for frame in support:
    frame.setdefault('file',old['file']);frame.setdefault('body_height',old['body_height'])
    frame.setdefault('sha256',hashlib.sha256((ASSETS/frame['file']).read_bytes()).hexdigest())
for slot,phase,index in [(0,'windup',0),(1,'active',0),(2,'active',1),(3,'active',3),(4,'active',4),(5,'active',13),(8,'windup',15),(11,'windup',7)]:
    fs=wind if phase=='windup' else active;boxes=wind_boxes if phase=='windup' else active_boxes
    support[slot]=copy.deepcopy(fs[index]);support_fits[slot]=fit(boxes[index],'active' if slot in range(1,6) else 'support',index)
fighter['active']=sheet(support)
fighter['windup']=sheet([wind[i] for i in [0,0,1,3,4,13]])
fighter['signature_windup']=sheet(wind);fighter['signature_active']=sheet(active)
manifest['status']='Smoke v1: 20 directed normal windup/active pairs, poison gas / smoke / ignition palette. Tapper custom kit retained. No transition smear frames.'
projectile=next((g for g in generation.get('extras',[]) if g['id']=='projectile'),None)
if projectile:
    src=Path(projectile['path']);path=DEST/'projectile.png'
    if src.exists():shutil.copyfile(src,path)
    im=Image.open(path);bounds=im.getchannel('A').point(lambda a:255 if a>32 else 0).getbbox()
    fighter['projectile']={'file':'smoke-v1/projectile.png','region':[bounds[0],bounds[1],bounds[2]-bounds[0],bounds[3]-bounds[1]],'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
p.write_text(json.dumps(manifest,indent=2)+'\n')
p=ROOT/'godot/data/fighter_collision.json';collision=json.loads(p.read_text());body=collision['fighters'][2]
body['poses']['signature_windup']=[fit(b,'windup',i) for i,b in enumerate(wind_boxes)]
body['poses']['signature_active']=[fit(b,'active',i) for i,b in enumerate(active_boxes)]
body['poses']['active']=support_fits
body['poses']['windup']=[fit(wind_boxes[i],'windup',i) for i in [0,0,1,3,4,13]]
p.write_text(json.dumps(collision,indent=2)+'\n')
print('Registered 40 Smoke normal poses; body-only hurtboxes and preserved support-frame scaling.')
