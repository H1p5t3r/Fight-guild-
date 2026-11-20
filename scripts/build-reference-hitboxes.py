#!/usr/bin/env python3
"""Register visually traced rectangles from the embedded reference diagrams.

Coordinates below are source pixels (left, top, right, bottom), not fitted
to generated weapon silhouettes. Image bytes stay unchanged. The yellow
push rectangle supplies a repeatable scale/root reference across crops.
"""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
# move, image index, source push rectangle (x1,y1,x2,y2), red rectangles,
# active frame. Boundaries between unlabeled diagrams are explicit estimates.
DIZZY = [
 ('5P',0,[134,157,205,350],[[195,127,349,165]],1),
 ('5K',0,[72,76,153,300],[[151,62,350,122]],1),
 ('c.S',0,[35,187,128,438],[[118,188,350,403]],1),
 ('f.S',0,[98,121,156,277],[[148,109,358,151]],1),
 ('5H',0,[114,142,164,277],[[158,159,338,227]],1),
 ('2P',0,[144,80,233,268],[[203,102,345,155]],1),
 ('2K',0,[63,0,167,218],[[158,113,349,209]],1),
 ('2S',0,[92,103,163,250],[[157,137,359,221]],1),
 ('2H',0,[121,189,177,332],[[147,0,285,122],[188,122,331,332]],1),
 ('2H',1,[106,207,173,345],[[127,0,262,139],[168,84,306,157],[184,145,324,345]],4),
 ('2H',2,[96,213,161,349],[[95,0,237,110],[155,94,293,164],[172,152,307,349]],7),
 ('2D',0,[93,86,147,206],[[145,146,342,201]],1),
 ('6P',1,[129,125,226,386],[[230,19,353,195]],1),
 ('6H',0,[51,180,130,394],[[141,35,334,230],[233,230,305,316]],1),
 ('6H',1,[133,63,190,220],[[134,116,318,220]],5),
 ('5D',0,[152,205,215,375],[[206,159,303,358]],1),
 ('j.P',0,[124,204,208,332],[[211,187,289,264],[259,218,336,295]],1),
 ('j.K',0,[61,114,154,254],[[191,146,312,240],[228,184,340,277]],1),
 ('j.S',0,[82,95,132,169],[[166,59,349,87]],1),
 ('j.H',0,[78,194,142,290],[[174,44,338,203],[174,203,265,241]],1),
 ('j.D',0,[128,114,173,182],[[229,75,321,166]],1),
]
LEO = [
 ('5P',0,[114,81,198,309],[[237,31,327,85],[237,85,291,122]],1),
 ('5K',0,[195,116,271,324],[[281,115,351,196],[281,196,318,220]],1),
 ('c.S',0,[143,81,218,283],[[233,80,351,180],[233,180,324,200]],1),
 ('2P',0,[99,28,202,240],[[226,55,316,129]],1),
 ('2K',0,[116,71,191,229],[[199,140,262,225],[262,175,348,225]],1),
 ('2S',0,[165,9,228,141],[[242,67,317,141],[317,108,359,141]],1),
 ('2H',0,[115,348,219,564],[[111,180,337,230],[111,230,271,248],[241,246,345,408],[241,408,294,495]],1),
 ('2H',1,[106,358,215,585],[[102,140,303,236],[102,236,339,253],[303,181,339,236]],5),
 ('j.P',0,[121,146,204,270],[[228,111,312,139],[228,139,328,164],[246,164,345,205],[263,205,345,231]],1),
 ('j.K',0,[106,213,177,316],[[185,184,268,266],[268,212,351,266]],1),
 ('j.S',0,[124,245,212,376],[[261,191,349,333]],1),
 ('j.S',1,[126,231,211,360],[[217,11,303,148],[259,63,344,198]],7),
 ('j.H',0,[134,92,183,165],[[208,10,337,103]],1),
 ('6K',0,[187,37,249,203],[[237,44,353,98],[237,98,263,130]],1),
 ('6H',0,[80,152,150,342],[[177,157,215,334],[215,143,254,334],[254,130,343,280],[254,280,292,334]],1),
 ('[s/h] h/s',0,[94,55,161,239],[[175,25,359,137],[175,137,267,179]],1),
]

def export(character, rows, push_width):
    folder = ROOT/'references/frame-data'/f'{character}-2026-11-18'
    source = json.loads((folder/'source.json').read_text())
    byid = {m['Input']: m for m in source['moves']}
    out = {'method': 'Manual trace of red rectangles; image pixel origin is top-left. Root estimated at yellow pushbox bottom-center. Normalize yellow push width to a fixed local calibration, not the live gameplay pushbox. Body hurtboxes are authored separately.',
           'calibrationWidth': push_width,
           'limits': 'Source screenshots do not supply exact numerical engine coordinates. Spatial scaling and unlabeled intra-active transition frames are adaptations. Multi-hit counts and total timing are taken from the saved tables.',
           'moves': {}}
    for move, image, push, rects, frame in rows:
        asset = byid[move]['hitboxImages'][image]
        assert asset['file'], (move,image)
        ox=(push[0]+push[2])/2; oy=push[3]; scale=push_width/(push[2]-push[0])
        boxes=[[round((l-ox)*scale),round((oy-b)*scale),round((r-ox)*scale),round((oy-t)*scale)] for l,t,r,b in rects]
        assert len(boxes)<=4 and all(l<r and b<t for l,b,r,t in boxes)
        out['moves'].setdefault(move,[]).append({'sourceImage':asset['file'],'sha256':asset['sha256'],
            'sourcePush':push,'origin':[ox,oy],'unitsPerPixel':scale,'pixelBoxes':rects,
            'activeFrame':frame,'transitionEstimated':len(byid[move]['hitboxImages'])>1 and move not in ['j.S','6P'],
            'boxes':boxes})
    (folder/'traces.json').write_text(json.dumps(out,indent=2)+'\n')
    print(character,len(out['moves']),'mapped moves')

export('queen-dizzy',DIZZY,4200)
export('leo-whitefang',LEO,4500)
