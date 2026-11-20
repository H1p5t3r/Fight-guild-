#!/usr/bin/env python3
"""Register unchanged imagegen atlases and expose them on the combat clocks.

Source pixels are immutable. Regions, body calibration, pivots and exposures
are metadata; gameplay roots, boxes, frame data and capture events stay intact.
"""
import copy
import hashlib
import importlib.util
import json
import math
import shutil
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
PROD = ROOT / 'art/characters/fillet-v1/production/kit-timing'
GRABS = ROOT / 'art/characters/fillet-v1/production/command-grabs-v2'
ASSETS = ROOT / 'godot/assets/fighters'
load = lambda p: json.loads(p.read_text())
def save(p, value):
    p.write_text(json.dumps(value, indent=2) + '\n')


def source_records():
    records = load(PROD / 'generated-sources.json')
    if (GRABS / 'sources.json').exists():
        records += load(GRABS / 'sources.json')
    return records


def generated_bank():
    bank = {}
    for record in source_records():
        dst = ASSETS / 'fillet-kit-v1' / record['file']
        dst.parent.mkdir(parents=True, exist_ok=True)
        src = Path(record['source'])
        if not src.exists(): src = dst
        assert hashlib.sha256(src.read_bytes()).hexdigest() == record['sha256']
        if src.resolve() != dst.resolve(): shutil.copy2(src, dst)
        im = Image.open(dst)
        assert im.mode == 'RGBA'
        width, height = im.size
        frames = []
        columns, rows = record['columns'], record['rows']
        for index in range(len(record.get('ticks', record.get('poseLabels', [])))):
            row, col = divmod(index, columns)
            y, bottom = round(row*height/rows), round((row+1)*height/rows)
            # Search the generator's transparent gutters without altering pixels.
            alpha_row = im.getchannel('A').crop((0,y,width,bottom))
            pixels = alpha_row.load()
            boundaries = [0]
            for boundary in range(1,columns):
                nominal = round(boundary*width/columns)
                boundaries.append(min(range(nominal-24,nominal+25), key=lambda x:
                    (sum(pixels[xx,yy]>32 for xx in range(x-2,x+3) for yy in range(bottom-y)),abs(x-nominal))))
            boundaries.append(width)
            x,right = boundaries[col:col+2]
            alpha = alpha_row.crop((x,0,right,bottom-y))
            bounds = alpha.point(lambda a: 255 if a>32 else 0).getbbox()
            assert bounds and bounds[2]-bounds[0]>60
            px=alpha.load()
            sole=max(yy+1 for yy in range(alpha.height) if sum(px[xx,yy]>128 for xx in range(alpha.width))>=8)
            nominal=round(col*width/columns)
            root=record.get('roots',[record['root']]*len(record.get('ticks',record.get('poseLabels',[]))))[index]
            sole=record.get('soles',[sole]*len(record.get('ticks',record.get('poseLabels',[]))))[index]
            frames.append(dict(file='fillet-kit-v1/'+record['file'],sha256=record['sha256'],
                source_size=list(im.size),region=[x,y,right-x,bottom-y],bounds=list(bounds),
                pivot=[root+nominal-x,sole],body_height=record['body_height'],source_pose=index,
                weapon_ownership={'right':'long knife / bare shoulder','left':'short knife / red shoulder'}))
        bank[record['id']]=frames
        for alias in record.get('aliases',[]): bank[alias]=frames
    return bank


def fit(frame, boxes):
    root,sole=frame['pivot']; height=frame['body_height']
    result=dict(hurt={name:[math.floor(root+l*height/15000),math.floor(sole-t*height/15000),
        math.ceil(root+r*height/15000),math.ceil(sole-b*height/15000)] for name,(l,b,r,t) in boxes.items()})
    if 'extension' in boxes: result['extensionFor']='Canonical anatomical extension only; weapons excluded.'
    return result


def register_knife_effects(fighter, frames, actions):
    record=load(PROD/'effects-generation.json')
    dst=ASSETS/'fillet-kit-v1'/record['file']; src=Path(record['source'])
    if not src.exists(): src=dst
    assert hashlib.sha256(src.read_bytes()).hexdigest()==record['sha256']
    if src.resolve()!=dst.resolve(): shutil.copy2(src,dst)
    im=Image.open(dst);width,height=im.size;keys=[]
    for index in range(6):
        row,col=divmod(index,3);x,y=round(col*width/3),round(row*height/2)
        right,bottom=round((col+1)*width/3),round((row+1)*height/2)
        alpha=im.getchannel('A').crop((x,y,right,bottom))
        l,t,r,b=alpha.point(lambda v:255 if v>64 else 0).getbbox()
        keys.append(dict(region=[x+l,y+t,r-l,b-t],bounds=[0,0,r-l,b-t],pivot=[0,b-t]))
    fighter['knife_fx']=dict(file='fillet-kit-v1/'+record['file'],sha256=record['sha256'],size=[width,height],columns=3,rows=2,frames=keys)
    for frame in frames:
        id=frame['action_id']
        if id not in record['actions']:continue
        action=actions[id];m=action['schema22Scalars'];tick=frame['action_frame'];s=m['startup'];end=s+m['active']
        if tick<s or tick>=end+4:continue
        active_tick=min(m['active'],tick-s+1)
        key=next(k for k in reversed(action['hitboxTimeline']['keys']) if k['frame']<=active_tick)
        boxes=key['boxes']
        if not boxes:continue
        box=[min(b[0] for b in boxes)/100,min(b[1] for b in boxes)/100,max(b[2] for b in boxes)/100,max(b[3] for b in boxes)/100]
        pose=record['actions'][id]
        if id=='j.Hs' and active_tick>=3:pose=5
        frame['effect']=dict(sheet='knife_fx',pose=pose,box=box,opacity=1 if tick<end else .35 if tick<end+2 else .12,behind=False)


def main():
    spec=load(ROOT/'art/characters/fillet-v1/FILLET_SPEC.json')
    actions={a['id']:a for a in spec['actions']}
    plans=load(PROD/'exposure-plans.json')['actions']
    original=load(PROD/'source-bank.json')['frames']
    generated=generated_bank()
    manifest=load(ASSETS/'manifest.json'); collision=load(ROOT/'godot/data/fighter_collision.json')
    fighter=manifest['fighters'][5]; body=collision['fighters'][5]
    frames=[]; fits=[]; clips={}
    for action_id,plan in sorted(plans.items(),key=lambda kv:kv[1]['slot']):
        action=actions[action_id]; s,a,r=[plan['timing'][k] for k in ('startup','active','recovery')]
        clip=dict(artPose=0,requiresExtendedKit=True,moveId=action_id,windup=[],active=[],recovery=[],
            exposureTiming=dict(style='held load / first-active snap / staged withdrawal',
                authoredTiming=[s,a,r],largestMotionBoundary=[s-1,s],source='art/characters/fillet-v1/production/kit-timing/exposure-plans.json'))
        for index,key in enumerate(plan['keys']):
            source=key['source']; tick=key['frame']
            if isinstance(source,dict): frame=generated[source['action']][source['pose']]
            elif plan['sourceType']=='generated': frame=generated[plan['sourceId']][source]
            else: frame=next(f for f in original if f['action_id']==action_id and f.get('source_action_frame',f['action_frame'])==source)
            frame=copy.deepcopy(frame);frame.pop('effect',None)
            if plan['sourceType']=='ground': frame['source_action_frame']=source
            frame.update(name=action_id+' / '+key['cue'],action_id=action_id,action_frame=tick,key_index=index,motion_cue=key['cue'])
            canonical=next(k['boxes'] for k in reversed(action['hurtboxTimeline']['keys']) if k['frame']<=tick)
            stage,start,duration=('windup',1,s-1) if tick<s else ('active',s,a) if tick<s+a else ('recovery',s+a,r)
            clip[stage].append(dict(start=(tick-start)*100//duration,phase='attack_animation',pose=len(frames)))
            frames.append(frame);fits.append(fit(frame,canonical))
        for stage in ('windup','active','recovery'):
            assert clip[stage][0]['start']==0 and len(clip[stage])<=16
        clips[str(plan['slot'])]=clip
    # Reuse the approved 2S arc registration and its actual hitbox placement.
    module_spec=importlib.util.spec_from_file_location('ground_register',ROOT/'scripts/register-fillet-ground.py')
    module=importlib.util.module_from_spec(module_spec);module_spec.loader.exec_module(module)
    module.register_sweep_effect(fighter,frames)
    register_knife_effects(fighter,frames,actions)
    paired={}
    pair_sources={'6P+K':'pair-forward','4P+K':'pair-backward','5D':'pair-wound','236D':'pair-cashout','214D':'pair-cashout'}
    records={r['id']:r for r in source_records()}
    grab_plans=load(GRABS/'paired-plans.json') if (GRABS/'paired-plans.json').exists() else {}
    for action_id,source_id in pair_sources.items():
        action=actions[action_id]; keys=[]
        if action_id in grab_plans:
            plan=grab_plans[action_id]
            poses=[(k['tick'],generated[plan['sourceId']][k['source']],k['cue']) for k in plan['keys']]
        else:
            poses=[(tick,source,'Capture C'+str(tick)) for tick,source in zip(records[source_id]['ticks'],generated[source_id])]
        for tick,source,cue in poses:
            frame=copy.deepcopy(source)
            frame.update(name=action_id+' / capture C'+str(tick),action_id=action_id,paired=True,capture_tick=tick,motion_cue=cue)
            keys.append(dict(tick=tick,phase='attack_animation',pose=len(frames)))
            frames.append(frame);fits.append(fit(frame,action['hurtboxTimeline']['keys'][0]['boxes']))
        paired[str(action['slot'])]=dict(moveId=action_id,requiresExtendedKit=True,keys=keys)
    first=frames[0]
    fighter['attack_animation']=dict(file=first['file'],sha256=first['sha256'],size=first['source_size'],
        columns=4,rows=2,body_height=450,transparent_samples=[[0,0],[1773,0],[0,886]],frames=frames)
    fighter['attack_animations']=clips;fighter['paired_animations']=paired
    fighter['attack_exposure_standard']='docs/attack-animation-standard.md'
    fighter['ground_normal_selection']['drawingCadence']=dict(style='held load / first-active snap / staged withdrawal',supersedes='evenly spaced on twos')
    body['poses']['attack_animation']=fits
    save(ASSETS/'manifest.json',manifest);save(ROOT/'godot/data/fighter_collision.json',collision)
    save(PROD/'registration.json',dict(version=1,actions=len(clips),pairedActions=len(paired),poses=len(frames),
        sourceSpecSHA256=hashlib.sha256((ROOT/'art/characters/fillet-v1/FILLET_SPEC.json').read_bytes()).hexdigest(),
        note='Unchanged generated pixels; saved action/capture clocks; collision and gameplay timing remain authoritative.'))
    print(f'Fillet: {len(clips)} attacks, {len(paired)} capture tracks, {len(frames)} registered timing cues.')
    # Apply the later focused guide audit after rebuilding the approved base.
    audit = ROOT / 'art/characters/fillet-v1/production/guide-audit-v1/sources.json'
    if audit.exists():
        audit_spec = importlib.util.spec_from_file_location('fillet_guide_audit', ROOT / 'scripts/register-fillet-guide-audit.py')
        audit_module = importlib.util.module_from_spec(audit_spec)
        audit_spec.loader.exec_module(audit_module)
        audit_module.main()


if __name__=='__main__': main()
