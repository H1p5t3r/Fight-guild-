#!/usr/bin/env python3
"""Register approved imagegen PNGs unchanged and bind them to Fillet's action clock.

Pixels are never cropped, repainted or resampled. Atlas regions, roots and scale
are metadata. Canonical combat geometry stays in the versioned kit extension.
"""
import hashlib
import json
import math
import shutil
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'art/characters/fillet-v1/production/ground-v1'
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
    frame_records, provenance = [], []
    for record in records.values():
        src = Path(record['source'])
        dst = DEST / record['file']
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
        rows = [0, round(height / 2), height]
        virtual_height, root = CALIBRATION[record['id']]
        row_cols = []
        for row in range(2):
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
            frame = dict(name=record['id']+' / '+key['label'],
                         file='fillet-ground-v1/'+record['file'], sha256=digest,
                         region=[x, y, w, h], pivot=[local_root, sole], bounds=list(bounds),
                         body_height=virtual_height, source_size=[width, height],
                         action_id=record['id'], action_frame=key['frame'],
                         key_index=record['keyStart']+index,
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
        provenance.append(dict(file=record['file'], sha256=digest, source=record['source'],
                               prompt=record['prompt'], references=record['references'], size=list(im.size)))
    frame_records.sort(key=lambda r: (r[0], r[1]))
    assert len(frame_records) == 92
    frames = [row[2] for row in frame_records]
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
            assert clip[stage][0]['start'] == 0 and len(clip[stage]) <= 8
        clips[str(a['slot'])] = clip
    fighter['attack_animations'] = clips
    fighter['ground_normal_selection'] = dict(version=1, actions=list(CALIBRATION),
        source='art/characters/fillet-v1/review/selection-log.json',
        sweep='B / Hip Reap, second study', antiAir='B / Rib Slip with corrected left arm')
    save(ROOT / 'godot/assets/fighters/manifest.json', manifest)
    save(ROOT / 'godot/data/fighter_collision.json', collision)
    save(DEST / 'generation.json', dict(version=1, generations=provenance))
    save(DEST / 'registration.json', dict(version=1, calibrations=CALIBRATION,
        poses=len(frames), actions=len(clips), sourceSpecSHA256=hashlib.sha256((ROOT/'art/characters/fillet-v1/FILLET_SPEC.json').read_bytes()).hexdigest(),
        notes=['Generated pixels preserved unchanged; no programmatic image edits.',
               'All phase keys follow the authored clock; edited timings scale within each phase.',
               'Current renderer uses its standard mirrored facing presentation; separate reverse-view drawings remain future art work.',
               'Canonical collision data remains authoritative. First-pass raster alignment is subject to visual refinement; no hitboxes are resized to fit art.']))
    print('Fillet: 11 selected ground normals, 92 registered pose keys, 12 original generated atlases.')


if __name__ == '__main__':
    main()
