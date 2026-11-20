#!/usr/bin/env python3
"""Measure generated sprites against neighboring approved keys; never edit pixels."""
import hashlib
import json
import statistics
from functools import lru_cache
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'art/characters/fillet-v1/production/ground-twos'
ASSETS = ROOT / 'godot/assets/fighters'


@lru_cache(None)
def alpha(path):
    return Image.open(path).getchannel('A')


def landmarks(path, region):
    x, y, w, h = region
    tile = alpha(str(path)).crop((x, y, x+w, y+h))
    px = tile.load()
    sole = max(yy+1 for yy in range(h) if sum(px[xx, yy] > 128 for xx in range(w)) >= 8)
    bounds = tile.point(lambda a: 255 if a > 64 else 0).getbbox()
    groups = []
    for xx in range(w):
        if sum(px[xx, yy] > 128 for yy in range(max(0, sole-10), sole)) < 4:
            continue
        if not groups or xx > groups[-1][-1]+12:
            groups.append([xx])
        else:
            groups[-1].append(xx)
    feet = [(g[0]+g[-1])/2 for g in groups if g[-1]-g[0] >= 20]
    assert feet, f'No planted foot: {path} {region}'
    return dict(left=feet[0], span=feet[-1]-feet[0], height=sole-bounds[1])


def main():
    baseline = json.loads((SOURCE/'baseline.json').read_text())['actions']
    jobs = json.loads((SOURCE/'generation-jobs.json').read_text())
    for job in jobs:
        path = Path(job['source'])
        if not path.exists():
            path = ASSETS/'fillet-ground-twos'/job['file']
        image = alpha(str(path))
        width, height = image.size
        old = baseline[job['id']]['frames']
        references = []
        for f in old:
            points = landmarks(ASSETS/f['file'], f['region'])
            scale = 150/f['body_height']
            references.append(dict(frame=f['action_frame'], left=(points['left']-f['pivot'][0])*scale,
                                   span=points['span']*scale, height=points['height']*scale))
        measurements = []
        for index, tick in enumerate(job['frames']):
            row, col = divmod(index, job['columns'])
            x, y = round(col*width/job['columns']), round(row*height/job['rows'])
            w, h = round((col+1)*width/job['columns'])-x, round((row+1)*height/job['rows'])-y
            points = landmarks(path, [x, y, w, h])
            before = next(r for r in reversed(references) if r['frame'] < tick)
            after = next(r for r in references if r['frame'] > tick)
            weight = (tick-before['frame'])/(after['frame']-before['frame'])
            target = {key: before[key]+weight*(after[key]-before[key]) for key in ('left', 'span', 'height')}
            measure = 'height' if job['id'] == '5K' else 'span'
            measurements.append(dict(frame=tick, pixels=points, target=target,
                                     height=150*points[measure]/target[measure]))
        virtual_height = round(statistics.median(m['height'] for m in measurements))
        roots = [round(m['pixels']['left']-m['target']['left']*virtual_height/150) for m in measurements]
        record = dict(job, sha256=hashlib.sha256(path.read_bytes()).hexdigest(), body_height=virtual_height,
                      roots=roots, keys=[dict(frame=t, label='in-between') for t in job['frames']],
                      calibration=dict(method='One fixed scale per sheet; planted-foot roots interpolate the neighboring approved keys.',
                                       scaleMeasure='standing head-to-sole height' if job['id']=='5K' else 'planted foot separation',
                                       measurements=measurements))
        (SOURCE/job['file'].replace('.png', '-source.json')).write_text(json.dumps(record, indent=2)+'\n')
        print(job['file'], 'body height', virtual_height, 'roots', roots)


if __name__ == '__main__':
    main()
