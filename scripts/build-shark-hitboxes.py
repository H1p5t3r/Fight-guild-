#!/usr/bin/env python3
"""Calibrated manual traces of the uploaded Ky normal diagrams.

The four inline supplements have chat provenance, never invented file hashes.
These are image-derived approximations, not source-engine collision exports.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / 'references/frame-data/ky-kiske-2026-11-18'
# input, image index, yellow body push rectangle, red rectangle decomposition,
# first active frame. Pixel origin is top-left; world y points upward.
ROWS = [
 ('5P',0,[289,177,455,628],[[494,138,737,209]],1),
 ('5K',0,[143,71,222,287],[[221,124,290,280],[290,170,351,280]],1),
 ('c.S',0,[102,116,177,323],[[178,132,234,336],[151,186,178,336],[234,116,330,336],[330,186,345,336]],1),
 ('f.S',0,[97,54,157,217],[[177,88,359,122]],1),
 ('5H',0,[367,117,532,568],[[639,205,774,277],[681,277,1107,312],[639,312,1107,374]],1),
 ('2P',0,[151,11,226,166],[[250,36,350,69]],1),
 ('2K',0,[149,28,222,181],[[211,92,281,185],[281,129,352,185]],1),
 ('2S',0,[112,8,169,126],[[173,63,278,123],[278,91,351,123]],1),
 ('2H',0,[55,133,234,507],[[336,113,489,390],[489,190,643,390]],1),
 ('2H',1,[49,654,286,1148],[[505,31,743,110],[347,110,743,627],[347,627,585,706]],2),
 ('j.P',0,[140,117,210,223],[[224,24,348,73],[224,73,292,99]],1),
 ('j.K',0,[147,88,207,178],[[193,43,352,86],[193,86,269,110]],1),
 ('j.S',0,[109,87,161,164],[[185,23,285,44],[165,65,265,116],[185,44,318,93],[165,116,230,142]],1),
 ('j.H',0,[90,159,161,269],[[178,42,328,66],[178,66,339,112],[178,112,351,227],[176,227,306,272]],1),
 ('j.H',1,[112,174,176,270],[[176,222,285,290]],3),
 ('6P',0,[122,32,200,243],[[223,0,267,96],[267,14,359,96]],1),
 ('6K',0,[127,55,202,260],[[176,55,345,141]],1),
 ('6H',0,[59,62,118,222],[[170,108,249,193],[249,106,335,193]],1),
]

def main():
    source = json.loads((FOLDER / 'source.json').read_text())
    rows = {m['Input']: m for m in source['moves']}
    out = dict(calibrationWidth=4000,
        method='Red rectangles traced in image pixels; root at yellow body pushbox bottom-center. Normalize yellow width to40 local pixels (4000 simulation units). This is a fixed anatomical calibration, not a change to Shark gameplay push width.',
        limits='Spatial coordinates are estimates from cropped diagrams. Air roots, 5Hs outlined region and j.Hs frame3 transition are provisional. Body hurtboxes are fitted separately; source weapon vulnerabilities are not copied.', moves={})
    for name,index,push,rects,frame in ROWS:
        asset = rows[name]['hitboxImages'][index]
        ox,oy=(push[0]+push[2])/2,push[3]
        scale=4000/(push[2]-push[0])
        boxes=[[round((l-ox)*scale),round((oy-b)*scale),round((r-ox)*scale),round((oy-t)*scale)] for l,t,r,b in rects]
        entry=dict(sourceImage=asset['file'],sourceUrl=asset['url'],sourcePush=push,origin=[ox,oy],unitsPerPixel=scale,pixelBoxes=rects,activeFrame=frame,transitionEstimated=name=='j.H',boxes=boxes)
        if asset['file']: entry['sha256']=asset['sha256']
        else: entry['provenance']='supplemental.json: user inline image, 18 November2026'
        if name=='5H': entry['note']='Trace follows outlined forward strike; unoutlined solid red/green export artifacts above it are ambiguous and excluded. Provisional geometry.'
        assert len(boxes)<=4 and all(l<r and b<t for l,b,r,t in boxes)
        out['moves'].setdefault(name,[]).append(entry)
    (FOLDER/'traces.json').write_text(json.dumps(out,indent=2)+'\n')
    print('Shark:16 normals,18 calibrated diagram traces; j.Hs stays one hit.')

if __name__=='__main__': main()
