#!/usr/bin/env python3
"""Register Shark's selected A/B/A/B/A cycles; never modify generated pixels."""
import copy
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'godot/assets/fighters'
DEST = ART / 'shark-movement-v1'
ROLES = ['legs', 'torsoArms', 'head', 'extension']
# Local source-pixel anatomy: legs; torso/arms; head; knife-hand/forearm.
# The pole, hook, dagger, hair and trailing net/sash never extend these boxes.
FITS = {
    'idle': [
        [[256, 250, 532, 484], [280, 91, 501, 265], [386, 27, 434, 96], [474, 224, 524, 282]],
        [[248, 251, 518, 484], [266, 79, 490, 267], [375, 25, 425, 95], [467, 223, 516, 281]],
        [[255, 253, 531, 485], [279, 97, 503, 269], [394, 38, 445, 107], [476, 228, 526, 284]],
        [[248, 251, 517, 485], [269, 91, 492, 268], [382, 28, 434, 99], [469, 225, 517, 282]],
    ],
    'walk_near': [
        [[211, 253, 611, 480], [293, 89, 508, 266], [405, 35, 458, 100], [484, 228, 532, 281]],
        [[278, 251, 456, 478], [281, 91, 491, 267], [388, 35, 441, 101], [468, 230, 516, 280]],
        [[310, 255, 486, 479], [291, 90, 509, 274], [405, 34, 457, 102], [486, 234, 531, 286]],
        [[205, 253, 614, 479], [278, 91, 498, 269], [390, 33, 444, 101], [476, 232, 524, 283]],
    ],
    'walk_far': [
        [[201, 251, 615, 480], [291, 91, 517, 269], [405, 34, 460, 102], [491, 233, 540, 284]],
        [[240, 250, 444, 479], [270, 91, 477, 270], [372, 34, 424, 102], [451, 230, 499, 281]],
        [[294, 253, 506, 480], [293, 94, 526, 275], [410, 37, 466, 104], [498, 234, 547, 286]],
        [[169, 253, 586, 482], [262, 95, 478, 274], [367, 36, 419, 104], [451, 233, 498, 287]],
    ],
    'back_walk_near': [
        [[208, 258, 529, 483], [292, 91, 509, 268], [404, 25, 458, 97], [484, 230, 533, 283]],
        [[230, 256, 479, 484], [277, 91, 493, 270], [387, 25, 442, 98], [470, 231, 519, 283]],
        [[310, 262, 493, 490], [294, 91, 511, 275], [406, 25, 460, 97], [487, 232, 535, 284]],
        [[218, 258, 469, 487], [278, 92, 495, 270], [388, 26, 444, 98], [470, 234, 518, 286]],
    ],
    'back_walk_far': [
        [[203, 255, 566, 486], [292, 92, 517, 272], [405, 25, 461, 98], [492, 230, 541, 283]],
        [[254, 255, 487, 487], [275, 92, 500, 272], [385, 25, 441, 98], [476, 230, 525, 283]],
        [[300, 261, 496, 484], [294, 93, 519, 275], [405, 26, 461, 99], [495, 232, 543, 286]],
        [[160, 258, 508, 486], [269, 94, 497, 273], [376, 27, 431, 100], [472, 232, 521, 285]],
    ],
    'run_near': [
        [[241, 245, 492, 492], [282, 88, 524, 258], [439, 34, 492, 104], [490, 235, 548, 291]],
        [[278, 247, 494, 493], [274, 103, 521, 265], [440, 50, 495, 120], [494, 239, 549, 296]],
        [[183, 246, 526, 491], [280, 99, 529, 271], [451, 32, 507, 106], [505, 228, 560, 288]],
        [[148, 242, 527, 419], [274, 101, 523, 272], [444, 34, 502, 108], [504, 188, 544, 252]],
    ],
    'run_far': [
        [[250, 244, 587, 492], [300, 89, 541, 262], [457, 31, 512, 103], [509, 229, 564, 287]],
        [[262, 245, 502, 492], [260, 102, 518, 266], [433, 49, 489, 123], [489, 230, 542, 289]],
        [[195, 246, 546, 492], [299, 99, 549, 277], [464, 28, 521, 102], [521, 225, 576, 283]],
        [[116, 239, 613, 405], [267, 99, 519, 274], [435, 28, 491, 104], [501, 184, 543, 250]],
    ],
    'backdash': [
        [[126, 280, 378, 474], [171, 160, 354, 290], [294, 115, 345, 182], [352, 254, 396, 302]],
        [[80, 280, 426, 476], [139, 152, 349, 289], [252, 112, 306, 180], [334, 239, 386, 292]],
        [[164, 266, 358, 455], [110, 96, 350, 283], [223, 113, 278, 181], [334, 235, 382, 284]],
        [[143, 271, 383, 465], [120, 121, 349, 293], [238, 112, 293, 183], [344, 231, 394, 285]],
        [[99, 280, 359, 463], [139, 153, 337, 291], [249, 108, 303, 179], [323, 242, 374, 298]],
        [[100, 276, 355, 465], [132, 150, 328, 290], [241, 107, 296, 176], [313, 240, 364, 295]],
    ],
}


def main():
    load = lambda p: json.loads(p.read_text())
    save = lambda p, d: p.write_text(json.dumps(d, indent=2) + '\n')
    manifest = load(ART / 'manifest.json')
    collision_path = ROOT / 'godot/data/fighter_collision.json'
    collision = load(collision_path)
    fighter, body = manifest['fighters'][4], collision['fighters'][4]
    assert fighter['name'] == body['name'] == 'Shark'
    generation = load(DEST / 'generation.json')
    entries = {j['id']: j for j in generation['generations']}
    catalog = {}
    registration = {'body_height': 480, 'units': 'source pixels', 'anatomy': {}, 'gait': {}}
    for name, fits in FITS.items():
        path = DEST / (name + '.png')
        im = Image.open(path)
        assert im.mode == 'RGBA' and im.size == (1536, 1024)
        assert hashlib.sha256(path.read_bytes()).hexdigest() == entries[name]['sha256']
        cols = 3 if name == 'backdash' else 2
        width = im.width // cols
        records = []
        for index, boxes in enumerate(fits):
            x, y = index % cols * width, index // cols * 512
            bounds = im.getchannel('A').crop((x, y, x + width, y + 512)).point(lambda a: 255 if a > 32 else 0).getbbox()
            assert bounds and 0 < bounds[0] < bounds[2] < width and 0 < bounds[1] < bounds[3] < 512
            # Air keys retain a virtual ground below their lifted boots. Ground
            # contact keys place the visible sole on the same world floor.
            ground = 493 if name.startswith('run_') and index == 3 else 480 if name == 'backdash' and index == 2 else bounds[3] - 1
            root_x = 410 if cols == 2 else [260, 250, 250, 260, 250, 245][index]
            frame = dict(name=name + ' ' + str(index + 1), file='shark-movement-v1/' + path.name,
                         sha256=entries[name]['sha256'], generation_file=Path(entries[name]['source']).name,
                         region=[x, y, width, 512], pivot=[root_x, ground], bounds=list(bounds), body_height=480)
            hurt = dict(hurt=dict(zip(ROLES, copy.deepcopy(boxes))),
                        extensionFor='Knife hand/forearm only; blade, hook, pole, hair and cloth excluded.')
            records.append((frame, hurt))
        catalog[name] = records
        registration['anatomy'][name] = fits

    def install(phase, records, names):
        frames = []
        for i, (frame, _) in enumerate(records):
            frame = copy.deepcopy(frame)
            frame['name'] = names[i]
            frames.append(frame)
        first = frames[0]
        fighter[phase] = dict(file=first['file'], sha256=first['sha256'], generation_file=first['generation_file'],
                              columns=3 if phase == 'backdash' else 2, rows=2, size=[1536, 1024], body_height=480,
                              transparent_samples=[[0, 0], [1535, 0], [0, 1023], [1535, 1023]], frames=frames)
        body['poses'][phase] = [copy.deepcopy(r[1]) for r in records]

    install('idle', catalog['idle'], ['A / Lazy Tap — rest', 'A / Lazy Tap — lift', 'A / Lazy Tap — tap', 'A / Lazy Tap — settle'])
    fighter['idle']['frame_ticks'] = [72, 12, 6, 18]
    # Static ready selectors and existing attack entry clocks use the same new
    # resting drawing. Their clocks, attack frame data and other art stay intact.
    install('ready', catalog['idle'][:1], ['A / Lazy Tap — ready'])
    for phase in ['walk', 'back_walk', 'run']:
        records = catalog[phase + '_near'] + catalog[phase + '_far']
        names = ['Right contact', 'Right load', 'Left passing / drive', 'Left reach / flight',
                 'Left contact', 'Left load', 'Right passing / drive', 'Right reach / flight']
        install(phase, records, [generation['selection'][phase] + ' — ' + n for n in names])
        supports = ['right', 'right', 'right', 'none' if phase == 'run' else 'right',
                    'left', 'left', 'left', 'none' if phase == 'run' else 'left']
        for i, frame in enumerate(fighter[phase]['frames']):
            frame['support_leg'] = supports[i]
            frame['gait_half'] = 'right' if i < 4 else 'left'
        registration['gait'][phase] = {'order': list(range(8)), 'support_legs': supports,
                                      'playback': 'chronological, not mirrored or ping-ponged'}
    install('backdash', catalog['backdash'], ['B / Shoulder Slip — load', 'B / Shoulder Slip — push',
                                             'B / Shoulder Slip — flight', 'B / Shoulder Slip — catch',
                                             'B / Shoulder Slip — absorb', 'B / Shoulder Slip — reset'])
    fighter['movement_selection'] = dict(generation['selection'], status='selected_by_user',
                                         walk_ticks_at_default_speed=5, run_ticks_at_default_speed=3,
                                         body_height=480, idle_cycle_ticks=108, grounded=True)
    save(ART / 'manifest.json', manifest)
    save(collision_path, collision)
    save(DEST / 'registration.json', registration)
    print('Registered Shark: 4 idle, 8 walk, 8 backward-walk, 6 backdash and 8 run drawings; 4 body regions each.')


if __name__ == '__main__':
    main()
