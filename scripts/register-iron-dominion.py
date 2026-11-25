#!/usr/bin/env python3
"""Register original Iron Dominion art without editing pixels or combat data."""
import hashlib
import json
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT/'godot/assets/fighters'
PRODUCTION = ROOT/'art/characters/supers-v2/iron-dominion'
PHASE = 'super_iron_dominion'
HEIGHT = 445
ROOTS = {
    'entry': [(360,475),(1105,474),(355,983),(1108,993)],
    'press': [(358,472),(1110,474),(355,993),(1110,991)],
    'crush': [(355,486),(1107,491),(355,995),(1110,995)],
    'finish': [(355,479),(1115,482),(355,973),(1106,997)],
}
# Outer shield silhouettes minus the visible fingers gripping its interior.
SHIELDS = {
    'entry': [(479,95,594,310,486,183,539,249),(1350,50,1490,287,1383,147,1435,211),(590,571,731,806,626,665,681,728),(1294,507,1442,744,1321,569,1376,640)],
    'press': [(485,211,608,446,517,307,564,361),(1237,234,1356,464,1261,324,1314,386),(528,497,689,727,587,594,638,650),(1252,487,1445,744,1315,579,1379,645)],
    'crush': [(415,5,592,216,484,82,537,136),(1162,43,1356,240,1230,114,1283,167),(535,667,717,903,597,760,651,828),(1234,711,1438,960,1310,811,1361,873)],
    'finish': [(446,67,625,288,513,142,570,196),(1231,232,1438,483,1313,327,1372,392),(460,670,651,920,538,765,589,823),(1202,610,1354,828,1230,697,1277,761)],
}

def read(p): return json.loads(p.read_text())
def write(p,v): p.write_text(json.dumps(v,indent=2)+'\n')

def main():
    sources={v['id']:v for v in read(PRODUCTION/'sources.json')}
    manifest=read(ART/'manifest.json'); fighter=manifest['fighters'][0]
    masks=read(ART/'pause-weapon-regions.json'); frames=[]
    for name,roots in ROOTS.items():
        src=sources[name]; path=ROOT/src['file']
        assert hashlib.sha256(path.read_bytes()).hexdigest()==src['sha256']
        im=Image.open(path); assert im.mode=='RGBA' and im.size==(1536,1024)
        alpha=np.asarray(im.getchannel('A'))
        for index,root in enumerate(roots):
            row,col=divmod(index,2); x=col*768
            split=min(range(480,550),key=lambda y:(np.count_nonzero(alpha[y,x:x+768]>64),abs(y-512)))
            assert not np.count_nonzero(alpha[split,x:x+768]>64),(name,col,'No transparent gutter')
            y,end=(0,split) if row==0 else (split,1024)
            yy,xx=np.where(alpha[y:end,x:x+768]>64)
            region=[x,y,768,end-y]
            l,t,r,b,hl,ht,hr,hb=SHIELDS[name][index]
            frames.append(dict(file=str(path.relative_to(ART)),sha256=src['sha256'],region=region,
                bounds=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)],
                pivot=[root[0]-x,root[1]-y],tip=[r-x,(t+b)/2-y],body_height=HEIGHT,
                source_size=list(im.size),source_pose=index,scale_group='iron-dominion-v2',render_only=True))
            masks[frames[-1]['file']+':'+','.join(map(str,region))]=[
                [[a-x,c-y],[d-x,c-y],[d-x,e-y],[a-x,e-y]]
                for a,c,d,e in [(l,t,r,ht),(l,hb,r,b),(l,ht,hl,hb),(hr,ht,r,hb)]]
    fighter[PHASE]=dict(file=frames[0]['file'],body_height=HEIGHT,frames=frames,render_only=True)
    fighter.setdefault('anatomical_scales',{})['iron-dominion-v2']=HEIGHT
    source=sources['effects']; path=ROOT/source['file']
    assert hashlib.sha256(path.read_bytes()).hexdigest()==source['sha256']
    alpha=np.asarray(Image.open(path).getchannel('A'));effects=[]
    for i in range(6):
        row,col=divmod(i,3); x,y=col*512,row*512
        yy,xx=np.where(alpha[y:y+512,x:x+512]>64)
        l,t,r,b=int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)
        effects.append(dict(region=[x+l,y+t,r-l,b-t],pivot=[(r-l)/2,b-t],bounds=[0,0,r-l,b-t]))
    fighter[PHASE+'_fx']=dict(file=str(path.relative_to(ART)),body_height=512,frames=effects,render_only=True)
    plan=read(PRODUCTION/'exposure-plan.json')
    def fx(stage,start,end,key,box,anchor='owner',fade=True):
        return dict(stage=stage,start=start,end=end,key=key,box=box,anchor=anchor,fade=fade)
    fighter.setdefault('super_presentations',{})['31']=dict(
        phase=PHASE,fx_phase=PHASE+'_fx',mode='strike',pair_ticks=90,release_freeze=22,owner_recovery=24,
        paired=plan['paired'],connected=plan['connected'],whiff=[[0,2],[28,14],[68,15]],
        sounds={'0':'iron_dominion_ram','40':'iron_dominion_press','70':'iron_dominion_crush','finish':'iron_dominion_finish'},
        effects=[dict(fx('active',0,5,0,[75,-135,180,130]),contact_box=[-35,-135,80,110]),fx('paired',0,7,0,[-65,-140,140,140],'receiver'),
            fx('paired',40,49,1,[-75,-175,140,170],'receiver'),fx('paired',70,80,2,[-75,-180,160,175],'receiver'),
            fx('connected',0,4,3,[-5,-85,190,90],fade=False),fx('connected',4,12,4,[-15,-35,210,40],fade=False),
            fx('connected',12,30,5,[-15,-75,210,80])])
    write(ART/'manifest.json',manifest)
    (ART/'pause-weapon-regions.json').write_text('{\n'+',\n'.join('  '+json.dumps(k)+': [\n    '+',\n    '.join(json.dumps(p,separators=(',',':')) for p in v)+'\n  ]' for k,v in masks.items())+'\n}\n')
    portraits_path=ROOT/'godot/assets/ui/super-freeze/portraits.json';portraits=read(portraits_path)
    portraits.setdefault('moves',{})['Iron Dominion']=dict(character=0,enabled=True,
        file='../../fighters/supers-v2/iron-dominion/portrait.png',region=[0,0,1536,1024],width=.55,center_y=.58,
        source='art/characters/supers-v2/iron-dominion/portrait-prompt.txt')
    portraits['status']='Completed supers-v2 moves have dedicated production portraits; other moves retain existing selection.'
    write(portraits_path,portraits)
    write(PRODUCTION/'registration.json',dict(bodyKeys=len(frames),effectKeys=len(effects),bodyHeight=HEIGHT,
        gameplayChanged=False,pixelEdits=False,phase=PHASE,regions=[f['region'] for f in frames]))
    print('Iron Dominion: 16 body keys, 6 effects, dedicated face, unchanged gameplay.')

if __name__=='__main__':main()
