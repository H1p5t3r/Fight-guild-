#!/usr/bin/env python3
"""Register Fillet's focused guide audit, preserving source pixels and combat data."""
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'godot/assets/fighters'
PROD = ROOT / 'art/characters/fillet-v1/production/guide-audit-v1'
load = lambda p: json.loads(p.read_text())
def save(p, value): p.write_text(json.dumps(value, indent=2) + '\n')

def main():
    manifest = load(ART / 'manifest.json')
    collision = load(ROOT / 'godot/data/fighter_collision.json')
    fighter, body = manifest['fighters'][5], collision['fighters'][5]
    base, fits = load(PROD / 'baseline-art.json'), load(PROD / 'baseline-collision.json')
    spec = {a['id']: a for a in load(ROOT / 'art/characters/fillet-v1/FILLET_SPEC.json')['actions']}
    sources = {s['id']: s for s in load(PROD / 'sources.json')}
    module_spec = importlib.util.spec_from_file_location('fillet_kit', ROOT / 'scripts/register-fillet-kit.py')
    kit = importlib.util.module_from_spec(module_spec); module_spec.loader.exec_module(kit)

    def source(name, index):
        record = sources[name]
        file = ART / 'fillet-guide-audit-v1' / record['file']
        assert hashlib.sha256(file.read_bytes()).hexdigest() == record['sha256']
        im = Image.open(file)
        assert im.mode == 'RGBA'
        w, h = im.size
        col, row = index % record['columns'], index // record['columns']
        x, y = round(col*w/record['columns']), round(row*h/record['rows'])
        r, b = round((col+1)*w/record['columns']), round((row+1)*h/record['rows'])
        bounds = im.getchannel('A').crop((x,y,r,b)).point(lambda a:255 if a>32 else 0).getbbox()
        assert bounds and bounds[0]>0 and bounds[2]<r-x and bounds[1]>0 and bounds[3]<b-y
        return dict(file='fillet-guide-audit-v1/'+record['file'],sha256=record['sha256'],
            source_size=[w,h],region=[x,y,r-x,b-y],bounds=list(bounds),pivot=record['pivots'][index],
            body_height=record['body_height'],source_pose=index,
            weapon_ownership={'right':'long knife / bare shoulder','left':'short knife / red shoulder'})

    # Reconstruct only the audited action slots. Unrelated fighter/art work is
    # retained. The baseline makes reruns deterministic without accumulating keys.
    frames = fighter['attack_animation']['frames']
    boxes = body['poses']['attack_animation']
    audited = {'c.S','j.K','623Hs'}
    for i, old in enumerate(base['attack_animation']['frames']):
        if old['action_id'] in audited and not old.get('paired'):
            frames[i] = copy.deepcopy(old)
            boxes[i] = copy.deepcopy(fits['poses']['attack_animation'][i])
    extra = next((i for i,f in enumerate(frames) if f.get('audit_key')=='623Hs-lower-elbow'),len(frames))
    if extra == len(frames): frames.append({}); boxes.append({})
    for slot in ['32','18','16']:
        fighter['attack_animations'][slot] = copy.deepcopy(base['attack_animations'][slot])

    def replace(index, tile, cue=None):
        old = frames[index]
        frame = copy.deepcopy(tile)
        for key in ['name','action_id','action_frame','key_index','motion_cue']:
            if key in old: frame[key] = old[key]
        if cue: frame['motion_cue'] = cue
        action = spec[frame['action_id']]
        canonical = next(k['boxes'] for k in reversed(action['hurtboxTimeline']['keys']) if k['frame']<=frame['action_frame'])
        frames[index] = frame
        boxes[index] = kit.fit(frame, canonical)
        return frame

    # c.S keeps the left short blade's reverse grip. Only the first active
    # tick has the low swept path; later keys must not retain that low trail.
    cs_sources = {1:5,2:0,7:1,8:1,9:2,10:2,11:2,12:2,14:3,16:3,17:4,21:5}
    fx = source('inside-cut-effect',0)
    x,y,w,h = fx['region']; l,t,r,b = fx['bounds']
    fx.update(region=[x+l,y+t,r-l,b-t],bounds=[0,0,r-l,b-t],pivot=[0,b-t])
    fighter['knife_fx']['frames'] = copy.deepcopy(base['knife_fx']['frames']) + [fx]
    for index, old in enumerate(frames):
        if old.get('action_id')=='c.S' and not old.get('paired'):
            tick = old['action_frame']
            frame = replace(index,source('inside-cut',cs_sources[tick]))
            if tick==7: frame['effect'] = dict(sheet='knife_fx',pose=6,box=[60,64,72,130],opacity=.8,behind=False)

    # The generator's third figure begins before the old guessed grid boundary.
    # Use actual transparent gutters and a pelvis origin, never bottom-of-boot
    # registration for an airborne kick. No original PNG pixels are changed.
    kick = Image.open(ART / 'fillet-kit-v1/jk.png')
    regions = [[0,0,500,512],[500,0,445,512],[945,0,591,512],
               [0,512,500,512],[500,512,445,512],[945,512,591,512]]
    pelvis_x = [140,650,1100,150,650,1100]
    pelvis_y = [264,258,248,260,266,258]
    for index, old in enumerate(frames):
        if old.get('action_id')!='j.K' or old.get('paired'): continue
        tile = copy.deepcopy(old); pose = tile['source_pose']; x,y,w,h = regions[pose]
        tile['region'] = regions[pose]
        tile['bounds'] = list(kick.getchannel('A').crop((x,y,x+w,y+h)).point(lambda a:255 if a>32 else 0).getbbox())
        tile['pivot'] = [pelvis_x[pose]-x,pelvis_y[pose]+225]
        tile['registration'] = 'Air pelvis; actual atlas gutters; fixed vertical origin'
        replace(index,tile)

    # Keep the successful load/contact/early follow-through. New recovery keys
    # lower the elbow in stages and end in Stalker within the same 29f recovery.
    new_recovery = {23:(0,'Check high / fold elbow'),35:(2,'Collect the long knife low'),40:(3,'Stalker settle / still locked')}
    for index, old in enumerate(frames):
        if old.get('action_id')=='623Hs' and old.get('action_frame') in new_recovery:
            pose,cue = new_recovery[old['action_frame']]
            replace(index,source('rising-recovery',pose),cue)
    frames[extra] = dict(action_id='623Hs',action_frame=29,key_index=8,name='623Hs / Lower the elbow',motion_cue='Lower the elbow')
    frame = replace(extra,source('rising-recovery',1))
    frame['audit_key'] = '623Hs-lower-elbow'
    clip = fighter['attack_animations']['16']
    clip['recovery'].append(dict(start=(29-16)*100//29,phase='attack_animation',pose=extra))
    clip['recovery'].sort(key=lambda k:k['start'])
    for slot in ['32','18','16']:
        fighter['attack_animations'][slot]['exposureTiming']['audit'] = 'guide-audit-v1'
    assert len(frames)==len(boxes)==271
    save(ART / 'manifest.json',manifest)
    save(ROOT / 'godot/data/fighter_collision.json',collision)
    plans = {id:[dict(frame=f['action_frame'],cue=f['motion_cue'],file=f['file'],region=f['region'],pivot=f['pivot'],body_height=f['body_height'],effect=f.get('effect'))
        for f in sorted((f for f in frames if f.get('action_id')==id and not f.get('paired')),key=lambda f:f['action_frame'])] for id in sorted(audited)}
    save(PROD / 'exposure-plans.json',plans)
    print('Fillet guide audit: c.S reach/trail, j.K atlas/pelvis, 623Hs lowering; 271 action/capture cues. Combat tuning preserved.')

if __name__=='__main__': main()
