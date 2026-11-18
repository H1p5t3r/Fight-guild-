#!/usr/bin/env python3
"""Register generated recovery sprites and Tapper scale calibration; never edit PNG pixels."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'godot/assets/fighters'
manifest = json.loads((ART / 'manifest.json').read_text())
collision_path = ROOT / 'godot/data/fighter_collision.json'
collision = json.loads(collision_path.read_text())
provenance = json.loads((ART / 'recovery-v1/generation.json').read_text())
names = ['Prone', 'Brace', 'Kneel', 'Rise', 'Ready anticipation', 'Ready']
# Standing-equivalent source height. Never normalize to the current pose's
# bounding-box height: that would enlarge a lying or crouching character.
heights = [330, 426, 446, 430, 422, 412]
heads = [
    [[335,365,400,435],[300,275,365,345],[285,210,345,280],[260,157,325,227],[250,112,310,182],[240,84,300,154]],
    [[365,367,412,425],[344,282,398,344],[295,201,349,264],[285,148,339,210],[282,91,336,153],[235,28,290,90]],
    [[405,417,462,472],[350,325,406,388],[324,260,380,325],[298,220,354,285],[271,136,327,201],[220,55,284,120]],
    [[370,346,432,411],[350,244,415,311],[327,190,392,257],[292,165,357,232],[288,99,353,166],[255,75,320,142]],
    [[373,405,439,460],[350,345,415,409],[337,280,402,344],[298,194,363,258],[271,113,336,177],[238,65,303,129]],
    [[376,432,434,487],[342,354,400,416],[330,290,388,352],[296,231,354,293],[300,174,358,236],[278,150,336,212]],
]
for c, fighter in enumerate(manifest['fighters']):
    generation = provenance['generations'][c]
    assert generation['name'] == fighter['name'].lower()
    path = ART / 'recovery-v1' / generation['file']
    image = Image.open(path)
    assert image.mode == 'RGBA' and image.size == (1536, 1024)
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    frames, boxes = [], []
    for i in range(6):
        x, y = i % 3 * 512, i // 3 * 512
        alpha = image.getchannel('A').crop((x, y, x + 512, y + 512))
        bounds = alpha.point(lambda value: 255 if value > 32 else 0).getbbox()
        assert bounds and bounds[0] > 0 and bounds[2] < 512
        ground = bounds[3] - 1
        frames.append(dict(name=names[i], region=[x, y, 512, 512], pivot=[256, ground], bounds=list(bounds)))
        head = heads[c][i]
        if i == 0:
            legs = [bounds[0]+5, ground-66, 225, ground]
            torso = [190, head[1]-25, head[2]-20, ground-5]
        else:
            hip = ground - [0, 65, 105, 140, 180, 195][i]
            legs = [max(bounds[0]+5, 75), hip-10, min(bounds[2]-10, 395), ground]
            torso = [head[0]-85, head[1]+45, min(bounds[2]-5, head[2]+15), max(head[1]+85, hip+20)]
        boxes.append({'hurt': {'legs': legs, 'torsoArms': torso, 'head': head}})
    fighter['knockdown'] = dict(file='recovery-v1/'+generation['file'], columns=3, rows=2,
        body_height=heights[c], sha256=digest, generation_file=Path(generation['source']).name,
        transparent_samples=[[0,0],[511,0],[1023,0],[1535,0],[0,1023]], frames=frames)
    collision['fighters'][c]['poses']['knockdown'] = boxes

back_provenance = json.loads((ART / 'recovery-v1/generation-back.json').read_text())
back_heads = [
    [[395,345,450,400],[330,272,390,327],[285,234,343,292],[303,165,365,220],[263,125,323,180],heads[0][5]],
    [[375,338,433,392],[327,257,386,313],[253,210,311,272],[300,160,360,224],[300,116,360,179],heads[1][5]],
    [[390,397,445,451],[344,327,400,385],[320,290,377,348],[333,224,389,285],[315,192,372,251],heads[2][5]],
    [[385,316,445,377],[330,235,392,295],[296,190,355,255],[310,149,370,215],[292,150,352,215],heads[3][5]],
    [[412,372,466,429],[337,279,391,337],[270,237,326,295],[303,189,359,251],[308,143,364,205],heads[4][5]],
    [[389,394,446,449],[328,302,387,362],[246,264,305,324],[306,219,366,281],[313,184,370,246],heads[5][5]],
]
for c, fighter in enumerate(manifest['fighters']):
    generation = back_provenance['generations'][c]
    assert generation['name'] == fighter['name'].lower()
    path = ART / 'recovery-v1' / generation['file']
    image = Image.open(path)
    assert image.mode == 'RGBA' and image.size == (1536, 1024)
    frames, boxes = [], []
    for i, name in enumerate(['Supine', 'Elbow brace', 'Seated', 'Kneel', 'Rise', 'Ready']):
        x, y = i % 3 * 512, i // 3 * 512
        bounds = image.getchannel('A').crop((x,y,x+512,y+512)).point(lambda value: 255 if value > 32 else 0).getbbox()
        assert bounds and 0 < bounds[0] < bounds[2] < 512
        ground = bounds[3] - 1
        frames.append(dict(name=name, region=[x,y,512,512], pivot=[256,ground], bounds=list(bounds)))
        head = back_heads[c][i]
        hip = ground - [90,70,85,130,160,195][i]
        legs = [max(bounds[0]+5,40), hip-35, 245 if i<3 else min(bounds[2]-10,395), ground]
        torso = [head[0]-115, head[1]+30, min(bounds[2]-5,head[2]+10), max(head[1]+85,hip+30)]
        boxes.append({'hurt': {'legs': legs, 'torsoArms': torso, 'head': head}})
    fighter['knockdown_back'] = dict(file='recovery-v1/'+generation['file'], columns=3, rows=2,
        body_height=heights[c], sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
        generation_file=Path(generation['source']).name,
        transparent_samples=[[0,0],[511,0],[1023,0],[1535,0],[0,1023]], frames=frames)
    collision['fighters'][c]['poses']['knockdown_back'] = boxes

# The original Tapper registration assigned 400px to every new sheet, including
# a 470px ready drawing. Calibrate source batches to that same anatomical model.
# A crouch, jump or extended weapon never changes the scale during playback.
calibration = {
    'tapper-v1/idle.png': 470, 'tapper-v1/walk.png': 450, 'tapper-v1/step.png': 430,
    'tapper-v1/actions-1.png': 405, 'tapper-v1/actions-2.png': 405,
    'tapper-v1/actions-3.png': 425, 'tapper-v1/actions-4.png': 410,
    'tapper-v1/actions-5.png': 405, 'tapper-v1/actions-6.png': 405,
    'tapper-v1/actions-7.png': 440, 'tapper-v1/actions-8.png': 410,
}
for phase, sheet in manifest['fighters'][3].items():
    if not isinstance(sheet, dict) or 'frames' not in sheet: continue
    for frame in sheet['frames']:
        source = frame.get('file', sheet['file'])
        if source in calibration: frame['body_height'] = calibration[source]
manifest['fighters'][3]['scale_calibration'] = {
    'reference': 'tapper-v1/idle.png / normal ready', 'world_standing_height': 150,
    'method': 'Fixed standing-equivalent source scale, shared by every use of a source frame. Bent poses retain smaller silhouettes; weapons are excluded.',
    'source_body_heights': calibration,
}
manifest['status'] = 'Recovery v1: six face-down/hard and six supine/soft knockdown/get-up poses per fighter; fixed Tapper source-scale registration. No transition smears.'
(ART / 'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
collision_path.write_text(json.dumps(collision, indent=2)+'\n')
print('Registered 72 recovery poses and calibrated Tapper scale; original PNGs unchanged.')
