#!/usr/bin/env python3
"""Register one authored super from metadata. Original PNGs stay byte-identical."""
import argparse
import hashlib
import json
from pathlib import Path
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'godot/assets/fighters'
def read(p):return json.loads(p.read_text())
def write(p,v):p.write_text(json.dumps(v,indent=2)+'\n')

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('super')
    parser.add_argument('--version',choices=['v2','v3'],default='v2');args=parser.parse_args()
    production=ROOT/'art/characters'/('supers-'+args.version)/args.super
    plan=read(production/'exposure-plan.json');layout=read(production/'layout.json')
    sources={v['id']:v for v in read(production/'sources.json')}
    manifest=read(ART/'manifest.json');fighter=manifest['fighters'][plan['character']]
    masks=read(ART/'pause-weapon-regions.json');frames=[];height=layout['bodyHeight'];phase='super_'+args.super.replace('-','_')
    for name,keys in layout['body'].items():
        src=sources[name];path=ROOT/src['file'];assert hashlib.sha256(path.read_bytes()).hexdigest()==src['sha256']
        im=Image.open(path);assert im.mode=='RGBA' and im.size==(1536,1024)
        alpha=np.asarray(im.getchannel('A'));assert alpha.min()==0
        for index,key in enumerate(keys):
            row,col=divmod(index,2)
            # A manually inspected column boundary can preserve an extended
            # boot/weapon without resizing or editing any source pixels.
            x,right=key.get('x_span',[col*768,(col+1)*768])
            assert 0<=x<right<=im.width
            gutter=range(384,640) if args.version=='v3' else range(470,560)
            split=min(gutter,key=lambda y:(np.count_nonzero(alpha[y,x:right]>64),abs(y-512)))
            assert not np.count_nonzero(alpha[split,x:right]>64),(name,col,'No transparent gutter')
            y,bottom=(0,split) if row==0 else (split,1024)
            yy,xx=np.where(alpha[y:bottom,x:right]>64);region=[x,y,right-x,bottom-y]
            root=key['root']
            frame=dict(file=str(path.relative_to(ART)),sha256=src['sha256'],source_size=list(im.size),region=region,
                bounds=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)],pivot=[root[0]-x,root[1]-y],
                body_height=height,source_pose=index,scale_group=args.super+'-'+args.version,render_only=True)
            for field in ['tip','grip']:
                if field in key:frame[field]=[key[field][0]-x,key[field][1]-y]
            frames.append(frame)
            if key.get('weapons'):
                masks[frame['file']+':'+','.join(map(str,region))]=[[[a-x,b-y] for a,b in poly] for poly in key['weapons']]
    fighter[phase]=dict(file=frames[0]['file'],body_height=height,frames=frames,render_only=True)
    fighter.setdefault('anatomical_scales',{})[args.super+'-'+args.version]=height
    source=sources['effects'];path=ROOT/source['file'];assert hashlib.sha256(path.read_bytes()).hexdigest()==source['sha256']
    im=Image.open(path);alpha=np.asarray(im.getchannel('A'));assert alpha.min()==0
    effects=[]
    for i in range(6):
        row,col=divmod(i,3);x,y=col*512,row*512
        yy,xx=np.where(alpha[y:y+512,x:x+512]>64)
        l,t,r,b=int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)
        effects.append(dict(region=[x+l,y+t,r-l,b-t],pivot=[(r-l)/2,b-t],bounds=[0,0,r-l,b-t]))
    fighter[phase+'_fx']=dict(file=str(path.relative_to(ART)),body_height=512,frames=effects,render_only=True)
    if 'projectile' in layout:
        config=dict(layout['projectile']);source=sources[config.pop('source')];path=ROOT/source['file']
        assert hashlib.sha256(path.read_bytes()).hexdigest()==source['sha256']
        im=Image.open(path);assert im.mode=='RGBA' and im.size==(1536,1024)
        alpha=np.asarray(im.getchannel('A'));assert alpha.min()==0
        regions=[]
        for i in range(6):
            row,col=divmod(i,3);x,y=col*512,row*512
            yy,xx=np.where(alpha[y:y+512,x:x+512]>64)
            regions.append(dict(region=[x+int(xx.min()),y+int(yy.min()),int(xx.max()-xx.min()+1),int(yy.max()-yy.min()+1)]))
        fighter.setdefault('projectile_variants',{})[str(plan['slot'])]=dict(config,file=str(path.relative_to(ART)),frames=regions)
    profile=dict(layout['presentation'],phase=phase,fx_phase=phase+'_fx',pair_ticks=plan['pairTicks'],release_freeze=plan['releaseFreeze'],owner_recovery=plan['ownerRecovery'])
    for key in ['paired','connected']:
        if key in plan:profile[key]=plan[key]
    fighter.setdefault('super_presentations',{})[str(plan['slot'])]=profile
    write(ART/'manifest.json',manifest)
    (ART/'pause-weapon-regions.json').write_text('{\n'+',\n'.join('  '+json.dumps(k)+': [\n    '+',\n    '.join(json.dumps(p,separators=(',',':')) for p in v)+'\n  ]' for k,v in masks.items())+'\n}\n')
    portraits_path=ROOT/'godot/assets/ui/super-freeze/portraits.json';portraits=read(portraits_path)
    face=sources['portrait'];assert hashlib.sha256((ROOT/face['file']).read_bytes()).hexdigest()==face['sha256']
    portraits.setdefault('moves',{})[plan['name']]=dict(character=plan['character'],enabled=True,
        file='../../'+str(Path(face['file']).relative_to('godot/assets')),region=[0,0,1536,1024],width=layout.get('faceWidth',.55),center_y=layout.get('faceY',.56),source=face['prompt'])
    write(portraits_path,portraits)
    write(production/'registration.json',dict(bodyKeys=len(frames),effectKeys=len(effects),bodyHeight=height,
        gameplayChanged=False,pixelEdits=False,phase=phase,regions=[f['region'] for f in frames]))
    print(plan['name'],':',len(frames),'body keys, 6 effects, original PNG bytes preserved.')

if __name__=='__main__':main()
