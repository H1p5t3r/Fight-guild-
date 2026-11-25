#!/usr/bin/env python3
"""Register untouched Sky Foundry drawings. Presentation only; no combat bake."""
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'godot/assets/fighters'
PRODUCTION = ROOT / 'art/characters/supers-v2/sky-foundry'
PHASE = 'super_sky_foundry'
HEIGHT = 445

# Absolute source coordinates: virtual support root, supporting RIGHT palm,
# and shield outer rectangle / skin grip exclusion. Air roots use the pelvis
# plus the same neutral pelvis-to-floor distance, never a fit-to-bounds scale.
LANDMARKS = {
    'entry': [
        ((355, 487), (359, 161), (482, 150, 625, 358), (538, 232, 582, 291)),
        ((1100, 485), (1292, 60), (1208, 159, 1350, 357), (1260, 238, 1314, 291)),
        ((355, 1004), (518, 578), (485, 695, 610, 890), (530, 774, 575, 826)),
        ((1100, 948), (1262, 553), (1205, 637, 1328, 823), (1244, 707, 1295, 761)),
    ],
    'air': [
        ((367, 477), (506, 65), (466, 145, 587, 342), (496, 221, 546, 278)),
        ((1130, 481), (1056, 42), (1192, 150, 1319, 336), (1243, 226, 1285, 278)),
        ((380, 1008), (328, 553), (462, 684, 578, 854), (491, 752, 539, 805)),
        ((1120, 1004), (1062, 581), (1203, 656, 1320, 847), (1249, 730, 1293, 783)),
    ],
    'slam': [
        ((410, 478), (329, 55), (466, 131, 604, 316), (510, 210, 560, 261)),
        ((1154, 507), (1026, 56), (1206, 156, 1345, 350), (1250, 237, 1303, 289)),
        ((380, 987), (322, 559), (471, 664, 620, 877), (519, 751, 575, 812)),
        ((1128, 998), (1143, 968), (1204, 665, 1345, 875), (1253, 746, 1306, 805)),
    ],
    'recovery': [
        ((313, 474), (328, 446), (459, 119, 607, 345), (504, 210, 555, 271)),
        ((1028, 470), (1043, 447), (1231, 93, 1380, 335), (1282, 181, 1335, 244)),
        ((380, 985), (379, 697), (480, 622, 635, 841), (533, 707, 584, 764)),
        ((1100, 990), (1077, 615), (1240, 609, 1391, 841), (1287, 698, 1343, 761)),
    ],
}


def read(path):
    return json.loads(path.read_text())


def write(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def main():
    sources = {item['id']: item for item in read(PRODUCTION / 'sources.json')}
    manifest = read(ART / 'manifest.json')
    fighter = manifest['fighters'][0]
    masks = read(ART / 'pause-weapon-regions.json')
    frames = []
    for name, marks in LANDMARKS.items():
        source = sources[name]
        path = ROOT / source['file']
        assert hashlib.sha256(path.read_bytes()).hexdigest() == source['sha256']
        im = Image.open(path)
        assert im.mode == 'RGBA' and im.size == (1536, 1024)
        alpha = np.asarray(im.getchannel('A'))
        for index, (root, grip, shield, hand) in enumerate(marks):
            row, col = divmod(index, 2)
            x = col * 768
            # The descending right boot crosses y512; use EACH column's real
            # empty gutter rather than clipping it or borrowing the next hand.
            split = min(range(490, 585), key=lambda y: (np.count_nonzero(alpha[y, x:x+768] > 64), abs(y - 512)))
            assert np.count_nonzero(alpha[split, x:x+768] > 64) == 0, (name, col)
            y, bottom = (0, split) if row == 0 else (split, 1024)
            yy, xx = np.where(alpha[y:bottom, x:x+768] > 64)
            region = [x, y, 768, bottom-y]
            frames.append(dict(file=str(path.relative_to(ART)), sha256=source['sha256'],
                               source_size=list(im.size), region=region,
                               bounds=[int(xx.min()), int(yy.min()), int(xx.max()+1), int(yy.max()+1)],
                               pivot=[root[0]-x, root[1]-y], grip=[grip[0]-x, grip[1]-y],
                               body_height=HEIGHT, source_pose=index, scale_group='sky-foundry-v2',
                               name='Sky Foundry / '+name+' / '+str(index+1), render_only=True))
            l, t, r, b = shield
            a, c, d, e = hand
            masks[frames[-1]['file']+':'+','.join(map(str,region))] = [
                [[x1-x,y1-y],[x2-x,y1-y],[x2-x,y2-y],[x1-x,y2-y]]
                for x1,y1,x2,y2 in [(l,t,r,c),(l,e,r,b),(l,c,a,e),(d,c,r,e)]]
    fighter[PHASE] = dict(file=frames[0]['file'], body_height=HEIGHT, frames=frames, render_only=True)
    fighter.setdefault('anatomical_scales', {})['sky-foundry-v2'] = HEIGHT
    source = sources['effects']
    path = ROOT / source['file']
    assert hashlib.sha256(path.read_bytes()).hexdigest() == source['sha256']
    alpha = np.asarray(Image.open(path).getchannel('A'))
    effects = []
    for index in range(6):
        row, col = divmod(index, 3)
        x, y = col*512, row*512
        yy, xx = np.where(alpha[y:y+512, x:x+512] > 64)
        l,t,r,b = int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)
        effects.append(dict(region=[x+l,y+t,r-l,b-t],pivot=[(r-l)/2,b-t],bounds=[0,0,r-l,b-t]))
    fighter[PHASE+'_fx'] = dict(file=str(path.relative_to(ART)),body_height=512,frames=effects,render_only=True)
    fighter['super_presentations'] = dict(fighter.get('super_presentations', {}), **{'16': {
        'phase':PHASE,'fx_phase':PHASE+'_fx','source':'supers-v2/sky-foundry',
        'pair_ticks':112,'release_freeze':24,'owner_recovery':24,
        'paired':[[0,1],[6,2],[12,3],[20,4],[30,5],[44,6],[58,7],[65,8],[88,9],[100,10]],
        'connected':[[0,11],[4,12],[8,13],[15,14],[21,15]],
        'description':'Held load, first-active catch, rising support, apex, downward load, damage-frame slam and grounded return.'}})
    write(ART / 'manifest.json', manifest)
    # Match this file's compact per-polygon convention and avoid unrelated churn.
    (ART/'pause-weapon-regions.json').write_text('{\n'+',\n'.join(
        '  '+json.dumps(k)+': [\n    '+',\n    '.join(json.dumps(p,separators=(',',':')) for p in v)+'\n  ]'
        for k,v in masks.items())+'\n}\n')
    portraits_path = ROOT/'godot/assets/ui/super-freeze/portraits.json'
    portraits = read(portraits_path)
    portraits.setdefault('moves', {})['Sky Foundry'] = {
        'character':0,'enabled':True,'file':'../../fighters/supers-v2/sky-foundry/portrait.png',
        'region':[0,0,1536,1024],'width':0.54,'center_y':0.57,
        'source':'art/characters/supers-v2/sky-foundry/portrait-prompt.txt'}
    portraits['status'] = 'Sky Foundry has a dedicated production portrait; other moves retain their existing portrait fallback.'
    write(portraits_path, portraits)
    write(PRODUCTION/'registration.json',dict(bodyKeys=len(frames),effectKeys=len(effects),bodyHeight=HEIGHT,
        gameplayChanged=False,pixelEdits=False,phase=PHASE,regions=[f['region'] for f in frames]))
    print('Sky Foundry: 16 original body drawings, 6 effect keys, one face portrait; no gameplay or collision changes.')


if __name__ == '__main__':
    main()
