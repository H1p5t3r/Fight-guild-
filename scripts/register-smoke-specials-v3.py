#!/usr/bin/env python3
"""Attack-timed Smoke recovery. Register original generated PNGs; never retune moves."""
import copy
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'godot/assets/fighters'
PROD = ROOT / 'art/characters/smoke-specials-v3'
load = lambda p: json.loads(p.read_text())
def save(p, value): p.write_text(json.dumps(value, indent=2) + '\n')

def main():
    manifest = load(ART / 'manifest.json')
    collision = load(ROOT / 'godot/data/fighter_collision.json')
    base, fits = load(PROD / 'baseline-art.json'), load(PROD / 'baseline-collision.json')
    fighter, body = manifest['fighters'][2], collision['fighters'][2]
    # Only this fighter's four approved special clips are replaced. Retain all
    # earlier pose indices used by normals and the development sprite viewer.
    fighter['attack_animation']['frames'] = copy.deepcopy(base['attack_animation']['frames'])
    body['poses']['attack_animation'] = copy.deepcopy(fits['poses']['attack_animation'])
    frames = fighter['attack_animation']['frames']
    boxes = body['poses']['attack_animation']
    current = load(ROOT / 'godot/data/workshop/current.json')
    data = load(ROOT / 'godot/data/workshop' / current['file'])
    sources = load(PROD / 'sources.json')

    def old(phase, pose):
        sheet = base[phase]
        frame = copy.deepcopy(sheet['frames'][pose])
        for key in ['file', 'sha256', 'body_height']:
            frame.setdefault(key, sheet[key])
        return frame, copy.deepcopy(fits['poses'][phase][pose])

    def new(name, index):
        source = next(s for s in sources if s['id'] == name)
        path = ART / 'smoke-specials-v3' / source['file']
        assert hashlib.sha256(path.read_bytes()).hexdigest() == source['sha256']
        image = Image.open(path)
        assert image.mode == 'RGBA' and image.size == (1536, 1024)
        x, y = index % 2 * 768, index // 2 * 512
        alpha = image.getchannel('A').crop((x, y, x + 768, y + 512))
        bounds = alpha.point(lambda a: 255 if a > 32 else 0).getbbox()
        assert bounds and 0 < bounds[0] < bounds[2] < 768 and 0 < bounds[1] < bounds[3] < 512
        pivots = [[429,494],[400,493],[435,493],[400,492]] if name == 'backhand-recovery' else [[400,498]]*4
        rectangles = {
            'backhand-recovery': [
                [[203,259,641,494],[300,97,533,286],[404,34,451,101],[529,115,640,159]],
                [[311,255,537,493],[317,91,487,285],[398,31,443,100],[484,147,499,195]],
                [[157,270,672,493],[300,123,544,304],[405,48,453,116],[536,126,653,164]],
                [[283,265,522,492],[313,96,478,287],[400,34,447,105],[457,128,485,177]],
            ],
            'pillar-recovery': [
                [[360,243,436,498],[327,94,492,264],[397,35,440,97],[481,65,535,120]],
                [[360,243,436,498],[327,94,492,264],[397,35,440,97],[486,151,515,188]],
                [[360,244,436,498],[317,111,515,274],[399,35,442,98],[500,48,585,119]],
                [[360,244,436,498],[327,94,492,268],[398,35,442,98],[483,200,523,240]],
            ],
        }[name][index]
        frame = dict(file='smoke-specials-v3/'+source['file'], sha256=source['sha256'],
            generation_file=Path(source['source']).name, source_size=[1536,1024], region=[x,y,768,512],
            source_pose=index, bounds=list(bounds), pivot=pivots[index], body_height=480)
        fit = dict(hurt=dict(zip(['legs','torsoArms','head','extension'],rectangles)),
            extensionFor='Extended bare hand/forearm only. Hair, coat, vials and alchemy effects excluded.')
        return frame, fit

    def effect(pair, opacity=1, box=None):
        frame, fit = copy.deepcopy(pair)
        if 'effect' in frame:
            frame['effect']['opacity'] = opacity
            if box is not None: frame['effect']['box'] = box
        return frame, fit

    plans = {}
    for slot in [14,25,15,16]:
        move = data['characters'][2]['moves'][slot]
        s,a,r = [move[k] for k in ['startup','active','recovery']]
        selector = move['artPose'] - 1
        assert selector == {14:20,25:21,15:22,16:23}[slot]
        label = {14:'236S',25:'236Hs',15:'214S',16:'214Hs'}[slot]
        entry = old('attack_animation', {14:28,25:29,15:30,16:31}[slot])
        release = old('signature_active',selector)
        idle = old('idle',0)
        clip = dict(artPose=move['artPose'],moveId=move['id'],windup=[],active=[],recovery=[],
            exposureTiming=dict(style='held load / first-active snap / follow-through / withdrawal / drift',
                authoredTiming=[s,a,r],largestMotionBoundary=[s-1,s],source='smoke-specials-v3'))
        if slot in (15,16):
            heavy = slot == 16
            loaded = old('signature_windup',selector)
            row = 2 if heavy else 0
            brake = new('backhand-recovery',row)
            # The residual arc is a brief lower-opacity echo, never a new hit or
            # a second opaque blade. Body silhouettes stay separate from VFX.
            brake[0]['effect'] = copy.deepcopy(release[0]['effect'])
            brake[0]['effect'].update(opacity=.20,box=[35,90,300,132] if heavy else [35,90,216,138])
            cues = [(1,idle,'Read entry'),(max(2,s//5),entry,'Gather'),
                (max(3,s//2),loaded,'Loaded backhand · hold'),
                (s,release,'First-active backhand snap'),
                (s+a,effect(release,.42),'Brake · residual arc'),
                (s+a+2,brake,'Follow-through · cloth lags'),
                (s+a+max(5,r//3),new('backhand-recovery',row+1),'Withdraw the hand'),
                (s+a+2*r//3,entry,'Collect into drift'),
                (s+a+5*r//6,idle,'Settled · still recovering')]
        else:
            # A compact common coil gives the near cast a readable release.
            # The two pillar projectiles still use byte-identical atlas/size.
            loaded = old('signature_windup',21)
            cues = [(1,idle,'Read entry'),(max(2,s//5),entry,'Gather'),
                (max(3,2*s//3),loaded,'Palm coiled · hold'),
                (s,release,'First-active pillar release'),
                (s+4,new('pillar-recovery',0 if slot==14 else 2),'Follow-through · fingers unfurl')]
            if slot == 25: cues.append((s+11,old('signature_active',20),'Lower the casting wrist'))
            cues.extend([(s+18,new('pillar-recovery',1),'Collect the hand'),
                (s+26,new('pillar-recovery',3),'Return to drift'),
                (s+32,idle,'Settled · cast lock remains'),
                (s+a,idle,'Settled · still recovering')])

        plan = []
        for tick,pair,cue in cues:
            frame,fit = copy.deepcopy(pair)
            fit.pop('strike',None)
            frame.update(name=label+' / '+cue,action_id=label,action_frame=tick,motion_cue=cue)
            phase = 'windup' if tick<s else 'active' if tick<s+a else 'recovery'
            start,duration = (1,s-1) if phase=='windup' else (s,a) if phase=='active' else (s+a,r)
            percent = (tick-start)*100//max(1,duration)
            assert 0 <= percent < 100
            clip[phase].append(dict(start=percent,phase='attack_animation',pose=len(frames)))
            plan.append(dict(frame=tick,phase=phase,cue=cue,pose=len(frames),source=frame['file'],region=frame['region']))
            frames.append(frame); boxes.append(fit)
        fighter['attack_animations'][str(slot)] = clip
        plans[label] = dict(slot=slot,timing=[s,a,r],keys=plan,projectile=bool(move['projectileKind']))

    assert len(frames) == len(boxes)
    save(ART / 'manifest.json', manifest)
    save(ROOT / 'godot/data/fighter_collision.json', collision)
    save(PROD / 'exposure-plans.json', plans)
    print(f'Registered Smoke specials: {len(frames)-32} timed cues, 8 generated recovery drawings; all move data preserved.')

if __name__ == '__main__': main()
