#!/usr/bin/env python3
"""Register Smoke's approved G3 drift and R4 run; never edit generated pixels."""
import copy
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'godot/assets/fighters'
manifest_path = ART / 'manifest.json'
collision_path = ROOT / 'godot/data/fighter_collision.json'
manifest = json.loads(manifest_path.read_text())
collision = json.loads(collision_path.read_text())
fighter, body = manifest['fighters'][2], collision['fighters'][2]
generation = json.loads((ART / 'smoke-movement-v1/generation.json').read_text())
heights = {'walk': 480, 'back_walk': 480, 'run': 450, 'movement_smoke': 480}
roots = {'walk': [409, 493], 'back_walk': [463, 500], 'run': [224, 496], 'movement_smoke': [300, 450]}
# Four authored drift drawings play forward and back; the repeated end keys
# ease into each change of direction. Run and vapor have eight unique drawings.
sequence = [0, 1, 2, 3, 3, 2, 1, 0]
for entry in generation['generations']:
    phase = entry['id']
    path = ART / 'smoke-movement-v1' / (phase + '.png')
    image = Image.open(path)
    assert image.mode == 'RGBA' and image.size == (1536, 1024)
    cols = 2 if phase in ('walk', 'back_walk') else 4
    width = image.width // cols
    order = sequence if cols == 2 else range(8)
    frames = []
    for key, source in enumerate(order):
        x, y = source % cols * width, source // cols * 512
        alpha = image.getchannel('A').crop((x, y, x + width, y + 512))
        bounds = alpha.point(lambda value: 255 if value > 8 else 0).getbbox()
        assert bounds and 0 < bounds[0] < bounds[2] < width and 0 < bounds[1] < bounds[3] < 512
        frames.append(dict(name=f'{phase.replace("_", " ").title()} {key + 1}',
            region=[x, y, width, 512], pivot=roots[phase], bounds=list(bounds)))
    sheet = dict(file='smoke-movement-v1/' + path.name, columns=cols, rows=2,
        body_height=heights[phase], sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
        generation_file=Path(entry['source']).name, transparent_samples=[[0, 0], [767, 0], [1535, 0], [0, 1023]], frames=frames)
    if phase == 'movement_smoke':
        sheet.update(frame_ticks=10, opacity=0.55, presentations={
            'walk': {'scale': [1.1, 1.15], 'offset': [-6, 0]},
            'back_walk': {'scale': [1.1, 1.15], 'offset': [6, 0], 'flip_x': True},
            'run': {'scale': [1.35, 1.15], 'offset': [-6, 0], 'frame_ticks': 6},
        })
    fighter[phase] = sheet

# Source-pixel anatomy. Rectangles follow the lean and leg curl; flowing cloth,
# hair, potion vials and vapor never enlarge the body's vulnerability.
walk = [
    [[361, 232, 465, 493], [347, 89, 550, 238], [447, 32, 491, 89], [286, 207, 355, 245]],
    [[353, 229, 457, 493], [340, 84, 542, 234], [438, 27, 483, 84], [281, 203, 349, 242]],
    [[361, 230, 465, 493], [347, 84, 550, 235], [447, 27, 491, 84], [286, 204, 355, 243]],
    [[354, 232, 458, 493], [340, 88, 542, 238], [439, 31, 483, 88], [280, 207, 349, 246]],
]
back = [
    [[362, 244, 499, 500], [270, 107, 455, 278], [311, 41, 352, 107], [226, 217, 282, 273]],
    [[370, 244, 499, 500], [277, 106, 457, 278], [317, 40, 358, 106], [234, 222, 288, 278]],
    [[353, 251, 499, 500], [267, 119, 457, 288], [285, 44, 330, 119], [238, 230, 294, 284]],
    [[343, 252, 499, 500], [242, 118, 437, 286], [281, 47, 324, 118], [211, 235, 268, 288]],
]
run = [
    [[151, 240, 288, 497], [166, 116, 378, 252], [265, 65, 307, 116], [121, 218, 173, 249]],
    [[164, 243, 300, 496], [167, 117, 378, 254], [264, 65, 306, 117], [126, 218, 174, 250]],
    [[164, 241, 294, 484], [163, 116, 377, 252], [264, 65, 306, 116], [122, 215, 171, 249]],
    [[172, 239, 296, 496], [167, 117, 375, 253], [266, 66, 308, 117], [130, 215, 177, 247]],
    [[160, 241, 290, 496], [170, 116, 377, 254], [267, 66, 310, 117], [128, 216, 179, 249]],
    [[164, 242, 294, 496], [169, 117, 377, 253], [267, 66, 310, 117], [127, 218, 176, 249]],
    [[154, 242, 291, 490], [169, 117, 379, 254], [268, 66, 311, 117], [124, 216, 175, 249]],
    [[160, 242, 294, 497], [168, 118, 377, 254], [269, 66, 311, 118], [128, 217, 178, 250]],
]
for phase, drawings in [('walk', walk), ('back_walk', back), ('run', run)]:
    order = sequence if phase != 'run' else range(8)
    body['poses'][phase] = [dict(hurt=dict(zip(['legs', 'torsoArms', 'head', 'extension'], copy.deepcopy(drawings[i]))),
        extensionFor='Rear hand and forearm only; hair, coat, vials and vapor excluded.') for i in order]
fighter['movement_selection'] = {'walk': 'G3 / Suspended Sway', 'run': 'R4 / Regal Surge',
    'walk_ticks_at_default_speed': 10, 'run_ticks_at_default_speed': 5,
    'walk_drawings': 4, 'run_drawings': 8, 'grounded': True}
manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
collision_path.write_text(json.dumps(collision, indent=2) + '\n')
print('Registered Smoke G3/R4: 24 body keys, 8 separate vapor keys; source PNGs and movement tuning unchanged.')
