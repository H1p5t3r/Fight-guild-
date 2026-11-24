#!/usr/bin/env python3
"""Register approved Collar Fold artwork; never change PNG pixels or collision data."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'godot/assets/fighters/grabs-v1'
NAMES = ('anvil', 'hammer', 'smoke', 'tapper', 'shark', 'fillet')
KEYS = ('Grip catch', 'Grip load', 'Grip turn', 'Caught', 'Collar fold', 'Turned fold')
# One standing-equivalent anatomy scale per fighter, across owner and receiver
# poses. Contact landmarks are hand/forearm (owner) and front collar (receiver).
# Coordinates below are relative to nominal 512px cells; gutter cuts are actual.
FITS = {
    'anvil': {'height': 440, 'contacts': [[450,158],[446,202],[436,204],[307,143],[330,201],[345,202]]},
    'hammer': {'height': 480, 'contacts': [[467,116],[419,182],[409,176],[306,128],[342,180],[365,197]]},
    'smoke': {'height': 480, 'contacts': [[449,111],[383,200],[395,165],[323,144],[336,184],[357,188]]},
    'tapper': {'height': 450, 'contacts': [[454,139],[409,197],[389,180],[321,138],[333,193],[354,190]]},
    'shark': {'height': 480, 'columns': [0,546,1024,1536], 'contacts': [[452,144],[388,205],[372,198],[300,125],[323,184],[355,184]]},
    'fillet': {'height': 480, 'contacts': [[457,149],[388,210],[358,190],[330,139],[350,174],[354,177]]},
}


def registered():
    provenance = json.loads((ART / 'generation.json').read_text())
    result = {'version': 1, 'approved': '2026-11-24', 'direction': 'A / Collar Fold',
              'purpose': 'Native render-only paired grips. No collision-authoring frames.', 'fighters': {}}
    for character, name in enumerate(NAMES):
        fit = FITS[name]
        path = ART / (name + '.png')
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        record = next(g for g in provenance['generations'] if g['name'] == name)
        assert digest == record['sha256'], f'{name}: original PNG changed'
        with Image.open(path) as image:
            assert image.mode == 'RGBA' and image.size == (1536, 1024)
            alpha = image.getchannel('A')
            assert alpha.getpixel((0,0)) < 5, f'{name}: background is not transparent'
            columns = fit.get('columns', [0,512,1024,1536])
            frames = []
            for key, title in enumerate(KEYS):
                row, col = divmod(key, 3)
                left, right = columns[col:col+2]
                top = row * 512
                width = right - left
                mask = alpha.crop((left,top,right,top+512)).point(lambda a: 255 if a > 32 else 0)
                bounds = mask.getbbox()
                assert bounds and 0 < bounds[0] < bounds[2] < width and 0 < bounds[1] < bounds[3] < 512, (name,key,bounds)
                feet = mask.crop((0,bounds[3]-40,width,bounds[3])).getbbox()
                pivot = [round((feet[0]+feet[2])/2), bounds[3]-1]
                contact = [fit['contacts'][key][0] + col*512 - left, fit['contacts'][key][1]]
                assert 0 <= contact[0] < width and 0 <= contact[1] < 512
                frames.append({'name':title, 'region':[left,top,width,512], 'pivot':pivot,
                               'contact':contact, 'bounds':list(bounds)})
            result['fighters'][str(character)] = {'file':path.name, 'body_height':fit['height'], 'sha256':digest, 'frames':frames}
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    text = json.dumps(registered(), indent=2) + '\n'
    path = ART / 'manifest.json'
    if args.check:
        assert path.read_text() == text, 'Collar Fold registration is stale'
    else:
        path.write_text(text)
    print('Collar Fold: 36 registered drawings; fixed scale, foot roots and contact landmarks; original PNGs preserved.')
