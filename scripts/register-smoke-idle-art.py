#!/usr/bin/env python3
"""Register approved Smoke A/H loops. Generated PNG pixels remain untouched."""
import copy
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'godot/assets/fighters'
manifest = json.loads((ART / 'manifest.json').read_text())
collision_path = ROOT / 'godot/data/fighter_collision.json'
collision = json.loads(collision_path.read_text())
fighter, body = manifest['fighters'][2], collision['fighters'][2]
generation = json.loads((ART / 'smoke-idle-v1/generation.json').read_text())

# Standing-equivalent source scales, shared by every key in a clip. The low
# crouch is never normalized to its shorter bounding height.
heights = {'idle': 480, 'crouch_idle': 600, 'idle_smoke': 480}
roots = {'idle': [408, 495], 'crouch_idle': [395, 487], 'idle_smoke': [192, 480]}
names = ['Settle', 'Rise', 'Crest', 'Return']
for entry in generation['generations']:
    phase = entry['id']
    path = ART / 'smoke-idle-v1' / (phase + '.png')
    image = Image.open(path)
    assert image.mode == 'RGBA' and image.size == (1536, 1024)
    cols = 4 if phase == 'idle_smoke' else 2
    width = 1536 // cols
    frames = []
    for i in range(cols * 2):
        x, y = i % cols * width, i // cols * 512
        alpha = image.getchannel('A').crop((x, y, x + width, y + 512))
        bounds = alpha.point(lambda value: 255 if value > 8 else 0).getbbox()
        assert bounds and 0 < bounds[0] < bounds[2] < width and 0 < bounds[1] < bounds[3] < 512
        frames.append(dict(name=('Rear vapor %d' % (i + 1)) if phase == 'idle_smoke' else names[i],
            region=[x, y, width, 512], pivot=roots[phase], bounds=list(bounds)))
    sheet = dict(file='smoke-idle-v1/' + path.name, columns=cols, rows=2,
        body_height=heights[phase], sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
        generation_file=Path(entry['source']).name, transparent_samples=[[0, 0], [767, 0], [1535, 0], [0, 1023]], frames=frames)
    if phase == 'idle_smoke':
        sheet.update(frame_ticks=10, opacity=0.65, presentations={
            'idle': {'scale': [1.1, 1.14], 'offset': [-8, 0]},
            'crouch_idle': {'scale': [1.35, 0.70], 'offset': [-8, 0]},
        })
    fighter[phase] = sheet

# Independently fitted anatomical boxes. Hair, hood, coat, vials and gas never
# expand vulnerability. The fourth box covers the outstretched arm/hand.
for phase, shifts in [('idle', [0, -4, -6, 1]), ('crouch_idle', [0, -5, -9, 1])]:
    poses = []
    for dy in shifts:
        if phase == 'idle':
            legs = [356, 230 + dy, 449, 495]
            torso = [278, 85 + dy, 477, 250 + dy]
            head = [389, 32 + dy, 433, 85 + dy]
            extension = [473, 185 + dy, 537, 233 + dy]
        else:
            legs = [316, 305 + dy, 645, 488]
            torso = [298, 205 + dy, 630, 364 + dy]
            head = [410, 142 + dy, 460, 207 + dy]
            extension = [245, 332 + dy, 319, 415 + dy]
        poses.append({'hurt': {'legs': legs, 'torsoArms': torso, 'head': head, 'extension': extension},
            'extensionFor': 'Outstretched hand and forearm only; cloth, hair and rear vapor excluded.'})
    body['poses'][phase] = poses

# Static fallback users and prejump use the same approved silhouettes. Attack
# art, move tuning and the stable push profile are not regenerated.
for slot, phase in [(0, 'idle'), (11, 'crouch_idle')]:
    frame = copy.deepcopy(fighter[phase]['frames'][0])
    frame.update(file=fighter[phase]['file'], body_height=heights[phase], sha256=fighter[phase]['sha256'])
    fighter['active']['frames'][slot] = frame
    body['poses']['active'][slot] = copy.deepcopy(body['poses'][phase][0])
fighter['idle_selection'] = {'standing': 'A / Open Current', 'crouching': 'H / Uncoiled Vapor',
    'body_frame_ticks': 20, 'cycle_ticks': 80, 'grounded': True}
(ART / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
collision_path.write_text(json.dumps(collision, indent=2) + '\n')
print('Registered Smoke A/H: 8 body poses, 8 separate rear-vapor keys; unchanged PNGs and push dimensions.')
