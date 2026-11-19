#!/usr/bin/env python3
"""Register approved imagegen PNGs unchanged and bind them to Fillet's action clock.

Pixels are never cropped, repainted or resampled. Atlas regions, roots and scale
are metadata. Canonical combat geometry stays in the versioned kit extension.
"""
import hashlib
import copy
import json
import math
import shutil
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'art/characters/fillet-v1/production/ground-v1'
INBETWEENS = ROOT / 'art/characters/fillet-v1/production/ground-twos'
SWEEP_TIMING = ROOT / 'art/characters/fillet-v1/production/sweep-timing'
DEST = ROOT / 'godot/assets/fighters/fillet-ground-v1'
load = lambda p: json.loads(p.read_text())
save = lambda p, value: p.write_text(json.dumps(value, indent=2) + '\n')

# Virtual upright body calibration, not the height of a bent pose or weapon.
# The crouch sheets were generated at a larger source scale; 2Hs was reduced
# uniformly by imagegen to restore headroom around the raised blade.
CALIBRATION = {
    '5P': (450, 230), '5K': (450, 220), 'c.S': (520, 255),
    '5S': (450, 220), '5Hs': (450, 230), '2P': (560, 230),
    '2K': (560, 220), '2S': (600, 225), '2Hs': (350, 228),
    '6P': (450, 230), '6Hs': (450, 230),
}


def register_sweep_effect(fighter, frames):
    source_record = INBETWEENS / 'sweep-arc-generation.json'
    if not source_record.exists():
        return
    record = load(source_record)
    dst = DEST.parent / 'fillet-ground-twos/sweep-arc.png'
    src = Path(record['source'])
    if not src.exists():
        src = dst
    assert hashlib.sha256(src.read_bytes()).hexdigest() == record['sha256']
    if src.resolve() != dst.resolve():
        shutil.copy2(src, dst)
    im = Image.open(dst)
    width, height = im.size
    keys = []
    for index in range(4):
        row, col = divmod(index, 2)
        x, y = round(col*width/2), round(row*height/2)
        w, h = round((col+1)*width/2)-x, round((row+1)*height/2)-y
        a = im.getchannel('A').crop((x,y,x+w,y+h))
        l,t,r,b = a.point(lambda v: 255 if v > 32 else 0).getbbox()
        # Tight atlas metadata maps the live, generated cutting arc to the
        # canonical strike corridor; pixels and combat boxes are unchanged.
        keys.append(dict(name=['outward cut','across-front cut','last active cut','recovery trail'][index],
                         region=[x+l,y+t,r-l,b-t], bounds=[0,0,r-l,b-t], pivot=[0,b-t]))
    fighter['sweep_fx'] = dict(file='fillet-ground-twos/sweep-arc.png', sha256=record['sha256'],
                              size=[width,height], columns=2, rows=2, frames=keys)
    placement = {
        12: (0, [19,0,116,27], 1.0),
        14: (1, [19,0,116,27], 1.0),
        15: (2, [19,0,108,27], 1.0),
        16: (3, [28,0,100,24], 0.50),
        18: (3, [35,2,80,20], 0.22),
    }
    for frame in frames:
        if frame['action_id'] == '2S' and frame['action_frame'] in placement:
            pose, box, opacity = placement[frame['action_frame']]
            frame['effect'] = dict(sheet='sweep_fx', pose=pose, box=box, opacity=opacity, behind=False)


def retime_sweep(records, actions):
    timing = load(SWEEP_TIMING / 'timing.json')
    source = {tick: frame for _, tick, frame, _ in records
              if frame['action_id'] == '2S' and frame['file'] == timing['sourceFile']}
    result = [r for r in records if r[2]['action_id'] != '2S']
    for key in timing['keys']:
        frame = copy.deepcopy(source[key['sourceFrame']])
        height = timing['bodyHeight']
        foot = timing['rearFootSourceX'][str(key['sourceFrame'])]
        frame['pivot'][0] = round(foot - timing['rearFootWorldX'] * height / 150)
        frame.update(action_frame=key['frame'], source_action_frame=key['sourceFrame'],
                     name='2S / '+key['cue'], motion_cue=key['cue'], body_height=height,
                     rear_foot_source_x=foot)
        root, sole = frame['pivot']
        canonical = next(k['boxes'] for k in reversed(actions['2S']['hurtboxTimeline']['keys']) if k['frame'] <= key['frame'])
        fit = dict(hurt={name: [math.floor(root+l*height/15000), math.floor(sole-t*height/15000),
                               math.ceil(root+r*height/15000), math.ceil(sole-b*height/15000)]
                        for name, (l,b,r,t) in canonical.items()})
        if 'extension' in canonical: fit['extensionFor'] = 'Canonical extended limb only; weapons excluded.'
        result.append((actions['2S']['slot'], key['frame'], frame, fit))
    return sorted(result, key=lambda r: (r[0], r[1])), timing


def main():
    spec = load(ROOT / 'art/characters/fillet-v1/FILLET_SPEC.json')
    actions = {a['id']: a for a in spec['actions']}
    manifest = load(ROOT / 'godot/assets/fighters/manifest.json')
    collision = load(ROOT / 'godot/data/fighter_collision.json')
    fighter, body = manifest['fighters'][5], collision['fighters'][5]
    assert fighter['name'] == body['name'] == 'Fillet'
    DEST.mkdir(parents=True, exist_ok=True)
    records = {}
    for path in sorted(SOURCE.glob('*-source.json')):
        record = load(path)
        # A refined image replaces only its own production atlas.
        if record['file'] not in records or '-refined-source' in path.name:
            records[record['file']] = record
    assert len(records) == 12, f'Expected 12 source atlases, got {len(records)}'
    cadence = load(INBETWEENS / 'cadence.json')
    for path in sorted(INBETWEENS.glob('*-source.json')):
        record = load(path)
        record['directory'] = 'fillet-ground-twos'
        records[record['file']] = record
    frame_records, provenance = [], []
    for record in records.values():
        src = Path(record['source'])
        directory = record.get('directory', 'fillet-ground-v1')
        asset_file = directory + '/' + record['file']
        dst = DEST.parent / asset_file
        dst.parent.mkdir(parents=True, exist_ok=True)
        if not src.is_file():
            src = dst  # Rebuild metadata from the unchanged tracked PNG on a fresh checkout.
        assert hashlib.sha256(src.read_bytes()).hexdigest() == record['sha256']
        if src.resolve() != dst.resolve():
            shutil.copy2(src, dst)
        digest = hashlib.sha256(src.read_bytes()).hexdigest()
        im = Image.open(src)
        assert im.mode == 'RGBA'
        width, height = im.size
        columns = record['columns']
        nominal_cols = [round(i * width / columns) for i in range(columns + 1)]
        row_count = record.get('rows', 2)
        rows = [round(i * height / row_count) for i in range(row_count + 1)]
        virtual_height, root = CALIBRATION[record['id']]
        virtual_height = record.get('body_height', virtual_height)
        root = record.get('root', root)
        row_cols = []
        for row in range(row_count):
            row_alpha = im.getchannel('A').crop((0, rows[row], width, rows[row+1]))
            px = row_alpha.load()
            cols = [0]
            for nominal in nominal_cols[1:-1]:
                # The generator's gutters can drift a few pixels. Put the
                # region boundary in a clear seven-pixel gutter, not a knife
                # tip. Both adjacent regions retain transparent edge padding.
                search = range(max(cols[-1]+1, nominal-40), min(width, nominal+41))
                cols.append(min(search, key=lambda x: (sum(px[xx, yy] > 32 for xx in range(max(0, x-3), min(width, x+4)) for yy in range(row_alpha.height)), abs(x-nominal))))
            row_cols.append(cols+[width])
        for index, key in enumerate(record['keys']):
            row, col = divmod(index, columns)
            cols = row_cols[row]
            x, y = cols[col], rows[row]
            w, h = cols[col + 1] - x, rows[row + 1] - y
            alpha = im.getchannel('A').crop((x, y, x+w, y+h))
            bounds = alpha.point(lambda a: 255 if a > 32 else 0).getbbox()
            assert bounds and bounds[2] - bounds[0] > 60
            # Sole is the last dense alpha row. Ignore tiny generator fringe.
            pixels = alpha.load()
            sole = max(yy + 1 for yy in range(h) if sum(pixels[xx, yy] > 128 for xx in range(w)) >= 8)
            local_root = root + nominal_cols[col] - x
            if 'roots' in record:
                local_root = record['roots'][index] + nominal_cols[col] - x
            frame = dict(name=record['id']+' / '+key['label'],
                         file=asset_file, sha256=digest,
                         region=[x, y, w, h], pivot=[local_root, sole], bounds=list(bounds),
                         body_height=virtual_height, source_size=[width, height],
                         action_id=record['id'], action_frame=key['frame'],
                         key_index=record.get('keyStart', 0)+index,
                         weapon_ownership={'left': 'short knife / red shoulder', 'right': 'long knife / bare shoulder'})
            action = actions[record['id']]
            canonical = next(k['boxes'] for k in reversed(action['hurtboxTimeline']['keys']) if k['frame'] <= key['frame'])
            # Metadata fallback is derived from the canonical anatomical boxes;
            # the active kit uses the exact unrounded extension data directly.
            def rect(box):
                l, b, r, t = box
                return [math.floor(local_root+l*virtual_height/15000), math.floor(sole-t*virtual_height/15000),
                        math.ceil(local_root+r*virtual_height/15000), math.ceil(sole-b*virtual_height/15000)]
            fit = dict(hurt={name: rect(box) for name, box in canonical.items()})
            if 'extension' in canonical:
                fit['extensionFor'] = 'Canonical extended limb only; weapons excluded.'
            frame_records.append((action['slot'], key['frame'], frame, fit))
        provenance.append(dict(file=record['file'], asset=asset_file, sha256=digest, source=record['source'],
                               prompt=record['prompt'], references=record['references'], size=list(im.size)))
    frame_records.sort(key=lambda r: (r[0], r[1]))
    assert len(frame_records) == 116
    frame_records, sweep_timing = retime_sweep(frame_records, actions)
    assert len(frame_records) == 105
    frames = [row[2] for row in frame_records]
    for action_id in CALIBRATION:
        selected = [f for f in frames if f['action_id'] == action_id]
        actual = [f['action_frame'] for f in selected]
        expected = {key['frame'] for key in actions[action_id]['animation']['keys']}
        if action_id in cadence['actions']:
            m = actions[action_id]['schema22Scalars']
            s, a, r = [m[k] for k in ('startup', 'active', 'recovery')]
            expected |= set(range(1, s, 2)) | set(range(s, s+a, 2)) | set(range(s+a, s+a+r, 2))
        if action_id == '2S': expected = {key['frame'] for key in sweep_timing['keys']}
        assert actual == sorted(expected), f'{action_id}: incorrect phase-entry / two-frame cadence'
        for index, frame in enumerate(selected):
            frame['key_index'] = index
    register_sweep_effect(fighter, frames)
    first = frames[0]
    fighter['attack_animation'] = dict(file=first['file'], sha256=first['sha256'],
        size=first['source_size'], columns=4, rows=2, body_height=450,
        transparent_samples=[[0, 0], [1773, 0], [0, 886]], frames=frames)
    body['poses']['attack_animation'] = [row[3] for row in frame_records]
    clips = {}
    for action_id in CALIBRATION:
        a = actions[action_id]
        scalar = a['schema22Scalars']
        startup, active, recovery = [scalar[k] for k in ['startup', 'active', 'recovery']]
        clip = dict(artPose=0, requiresExtendedKit=True, moveId=action_id, windup=[], active=[], recovery=[])
        for pose, frame in enumerate(frames):
            if frame['action_id'] != action_id:
                continue
            tick = frame['action_frame']
            stage, start, duration = ('windup', 1, startup-1) if tick < startup else ('active', startup, active) if tick < startup+active else ('recovery', startup+active, recovery)
            clip[stage].append(dict(start=(tick-start)*100//duration, phase='attack_animation', pose=pose))
        for stage in ('windup', 'active', 'recovery'):
            assert clip[stage][0]['start'] == 0 and len(clip[stage]) <= 16
        if action_id == '2S':
            clip['exposureTiming'] = dict(style='held anticipation / sharp cut / measured recovery',
                authoredTiming=[startup, active, recovery], bodyDrawings=7,
                source='art/characters/fillet-v1/production/sweep-timing/timing.json')
        elif action_id in cadence['actions']:
            clip['drawingCadence'] = dict(interval=2, phaseEntry=True, authoredTiming=[startup, active, recovery])
        clips[str(a['slot'])] = clip
    fighter['attack_animations'] = clips
    fighter['ground_normal_selection'] = dict(version=1, actions=list(CALIBRATION),
        source='art/characters/fillet-v1/review/selection-log.json',
        sweep='B / Hip Reap, second study', antiAir='B / Rib Slip with corrected left arm',
        drawingCadence=dict(actions=[a for a in cadence['actions'] if a != '2S'], interval=2, phaseEntry=True),
        sweepExposure='art/characters/fillet-v1/production/sweep-timing/timing.json')
    save(ROOT / 'godot/assets/fighters/manifest.json', manifest)
    save(ROOT / 'godot/data/fighter_collision.json', collision)
    save(DEST / 'generation.json', dict(version=1, generations=provenance))
    save(DEST / 'registration.json', dict(version=1, calibrations=CALIBRATION,
        poses=len(frames), actions=len(clips), sourceSpecSHA256=hashlib.sha256((ROOT/'art/characters/fillet-v1/FILLET_SPEC.json').read_bytes()).hexdigest(),
        notes=['Generated pixels preserved unchanged; no programmatic image edits.',
               'All phase keys follow the authored clock; edited timings scale within each phase.',
               'Current renderer uses its standard mirrored facing presentation; separate reverse-view drawings remain future art work.',
               'Canonical collision data remains authoritative. First-pass raster alignment is subject to visual refinement; no hitboxes are resized to fit art.']))
    print(f'Fillet: 11 ground normals, {len(frames)} registered keys; 2S uses 7 consistent body poses with held anticipation, contact and recovery cues.')


if __name__ == '__main__':
    if (ROOT / 'art/characters/fillet-v1/production/kit-timing/generated-sources.json').exists():
        import runpy
        runpy.run_path(str(ROOT / 'scripts/register-fillet-kit.py'), run_name='__main__')
    else:
        main()
