#!/usr/bin/env python3
"""Register approved Compact Snap sprites without modifying any source pixels or combat data."""
from pathlib import Path
import argparse
import hashlib
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'godot/assets/fighters/reactions-v1'
NAMES = ('anvil', 'hammer', 'smoke', 'tapper', 'shark', 'fillet')
FAMILIES = ('legs', 'chest', 'head', 'air')
# Fixed standing-equivalent anatomy scales, not the height of a bent silhouette.
# Air roots use independently fitted hip landmarks plus the same virtual leg length.
FITS = {
    'anvil':  {'height': 260, 'rows': [0,390,729,1075,1448], 'air_hips': [[200,185],[204,200],[198,209]], 'leg_length': 128},
    'hammer': {'height': 340, 'rows': [0,377,718,1077,1448], 'air_hips': [[212,171],[206,190],[192,199]], 'leg_length': 157},
    'smoke':  {'height': 335, 'rows': [0,371,725,1090,1448], 'air_hips': [[215,149],[206,163],[198,170]], 'leg_length': 163},
    'tapper': {'height': 345, 'rows': [0,364,727,1087,1448], 'air_hips': [[205,172],[202,181],[194,191]], 'leg_length': 160},
    'shark':  {'height': 340, 'rows': [0,367,727,1086,1448], 'air_hips': [[200,156],[204,184],[207,190]], 'leg_length': 161},
    'fillet': {'height': 390, 'rows': [0,398,744,1088,1448], 'air_hips': [[209,169],[202,191],[191,198]], 'leg_length': 183},
}

def registered():
    provenance = json.loads((ART / 'generation.json').read_text())
    manifest = {'version': 1, 'status': 'Approved A / Compact Snap; all six fighters, four visual-only reactions each.',
                'approved': '2026-11-24', 'key_action_ages': [0, 2, 5], 'fighters': {}}
    for c, name in enumerate(NAMES):
        fit = FITS[name]
        path = ART / (name + '.png')
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        source = next(g for g in provenance['generations'] if g['name'] == name)
        assert digest == source['sha256'], f'{name}: original image bytes changed'
        with Image.open(path) as image:
            assert image.mode == 'RGBA' and image.size == (1086, 1448)
            alpha = image.getchannel('A')
            clips = {}
            for row, family in enumerate(FAMILIES):
                frames = []
                top, bottom = fit['rows'][row:row+2]
                for col, key in enumerate(('Contact', 'Recoil', 'Stun hold')):
                    left = col * 362
                    mask = alpha.crop((left, top, left+362, bottom)).point(lambda a: 255 if a > 32 else 0)
                    bounds = mask.getbbox()
                    assert bounds and 0 < bounds[0] < bounds[2] < 362 and 0 < bounds[1] < bounds[3] < bottom-top, (name, family, col, bounds)
                    if row < 3:
                        # Foot sole registration. Ignore hair, cloth and weapon reach.
                        feet = mask.crop((0, bounds[3]-12, 362, bounds[3])).getbbox()
                        pivot = [round((feet[0]+feet[2])/2), bounds[3]-1]
                    else:
                        hip = fit['air_hips'][col]
                        pivot = [hip[0], hip[1] + fit['leg_length']]
                    frame = {'name': key, 'region': [left,top,362,bottom-top], 'pivot': pivot, 'bounds': list(bounds)}
                    if row == 3: frame['hip'] = fit['air_hips'][col]
                    frames.append(frame)
                clips[family] = {'file': path.name, 'body_height': fit['height'], 'sha256': digest, 'frames': frames}
            manifest['fighters'][str(c)] = clips
    return manifest

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    expected = json.dumps(registered(), indent=2) + '\n'
    path = ART / 'manifest.json'
    if args.check:
        assert path.read_text() == expected, 'Reaction registration is stale'
    else:
        path.write_text(expected)
    print('Compact Snap: 72 keys, fixed anatomy scales, planted feet/air hip anchors; PNGs and gameplay data unchanged.')
