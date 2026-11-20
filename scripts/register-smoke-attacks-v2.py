#!/usr/bin/env python3
"""Register approved Smoke specials, timed Backdraft and clean attack entries.

Generated pixels and the original uploaded JSON stay unchanged. The playable
copy changes only the four special art selectors; all tuning/notes are retained.
"""
import copy
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'godot/assets/fighters'
DEST = ART / 'smoke-attacks-v2'
load = lambda p: json.loads(p.read_text())
save = lambda p, v: p.write_text(json.dumps(v, indent=2) + '\n')
manifest = load(ART / 'manifest.json')
collision = load(ROOT / 'godot/data/fighter_collision.json')
fighter, body = manifest['fighters'][2], collision['fighters'][2]
sources = {g['id']: g for g in load(DEST / 'generation.json')['generations']}

def frames(name, height=480, roots=None, tight=False):
    path = DEST / (name + '.png')
    image = Image.open(path)
    assert image.mode == 'RGBA' and image.size == (1536, 1024)
    result = []
    for i in range(4):
        x, y = i % 2 * 768, i // 2 * 512
        width = 768
        if name == 'sword_effects':
            x, width = (0, 500) if i % 2 == 0 else (500, 1036)
        alpha = image.getchannel('A').crop((x, y, x + width, y + 512))
        bounds = alpha.point(lambda a: 255 if a > 8 else 0).getbbox()
        assert bounds and 0 < bounds[0] < bounds[2] < width and 0 < bounds[1] < bounds[3] < 512, (name, i, bounds)
        region = [x, y, width, 512]
        pivot = [400, 490] if roots is None else roots[i]
        if tight:
            region = [x + bounds[0], y + bounds[1], bounds[2] - bounds[0], bounds[3] - bounds[1]]
            bounds = [0, 0, region[2], region[3]]
            pivot = [region[2] // 2, region[3]]
        result.append(dict(name=f'{name} {i + 1}', file='smoke-attacks-v2/' + path.name,
            sha256=hashlib.sha256(path.read_bytes()).hexdigest(), generation_file=Path(sources[name]['source']).name,
            region=region, pivot=pivot, bounds=list(bounds), body_height=height))
    return result

def sheet(items):
    return dict(file=items[0]['file'], sha256=items[0]['sha256'], size=[1536, 1024],
        columns=2, rows=2, body_height=480, frames=items,
        transparent_samples=[[0, 0], [1535, 0], [0, 1023], [1535, 1023]])

def fit(rectangles):
    result = {'hurt': dict(zip(['legs', 'torsoArms', 'head', 'extension'], rectangles))}
    if len(rectangles) == 4:
        result['extensionFor'] = 'Extended hand/forearm only; hair, coat, vials, poison, fire and crystal excluded.'
    return result

def effect(name, index, box, behind=False, opacity=1.0):
    return dict(sheet=name, pose=index, box=box, behind=behind, opacity=opacity)

animation = frames('backdraft_body_a', 600, [[395, 470]] * 4) + frames('backdraft_body_b', 600, [[395, 470]] * 4)
names = ['Gather', 'Coil', 'Eruption', 'Twist', 'Crest', 'Follow-through', 'Recover', 'Settle']
for frame, name in zip(animation, names): frame['name'] = '2Hs / ' + name
for i, box in enumerate([[-2, 0, 137, 249], [-8, 0, 116, 217], [-22, 0, 116, 226]]):
    animation[2 + i]['effect'] = effect('backdraft_fx', i, box, True)
animation[5]['effect'] = effect('backdraft_fx', 3, [10, 0, 104, 62], True, .65)
fighter['backdraft_fx'] = sheet(frames('backdraft_fx', tight=True))
fits = [
 [[290,260,658,470],[266,142,599,346],[416,76,461,144],[197,312,279,393]],
 [[279,280,631,470],[259,190,515,355],[459,146,505,201],[449,328,569,449]],
 [[287,270,653,470],[277,166,525,336],[398,90,444,156],[496,28,648,175]],
 [[288,272,659,470],[266,164,523,340],[397,84,443,152],[504,11,659,174]],
 [[281,260,690,470],[243,129,540,332],[354,59,399,126],[500,44,669,150]],
 [[287,266,690,470],[240,130,517,339],[351,60,397,130],[504,144,650,222]],
 [[286,278,689,470],[240,145,552,340],[353,64,398,132],[201,333,274,396]],
 [[286,278,689,470],[237,147,551,340],[351,68,397,133],[196,330,270,397]],
]
# One independently drawn entry for each normal/charged move, plus a shared
# reach for the two standard throws. Crouches keep H's standing-equivalent scale.
slots = [0,1,32,2, 3,4,5,6, 8,11,13,22, 17,18,19,20, 21,43,44,23]
for n in range(5): animation.extend(frames('transition_' + str(n)))
for key in [5,6,7,11]: animation[8 + key]['body_height'] = 600
for i, ground in enumerate([497,498,489,497,497,464,468,468,499,500,503,469,490,490,490,490,490,498,499,495]):
    animation[8+i]['pivot'][1] = ground
fits += [
 [[347,240,435,497],[310,92,491,255],[391,38,434,94],[255,206,323,249]],
 [[350,238,491,498],[308,90,519,255],[399,38,440,96],[243,201,311,244]],
 [[342,287,483,489],[308,146,441,313],[391,75,435,138],[246,222,322,272]],
 [[352,272,494,497],[285,104,512,290],[402,38,445,99],[504,178,545,224]],
 [[368,239,448,497],[354,92,495,263],[398,40,440,95],[490,137,536,182]],
 [[311,278,615,464],[291,206,513,367],[410,137,455,193],[248,314,317,383]],
 [[315,289,599,468],[299,226,509,378],[410,148,456,205],[247,318,316,388]],
 [[315,283,623,468],[289,218,515,372],[409,140,457,202],[245,319,319,384]],
 [[312,253,545,499],[272,94,550,276],[407,40,451,96],[239,211,289,268]],
 [[319,245,543,500],[288,84,527,264],[392,39,438,99],[434,10,532,94]],
 [[313,251,549,503],[282,110,520,274],[402,48,446,112],[257,39,343,134]],
 [[291,306,601,469],[279,220,565,368],[403,155,449,218],[212,342,291,390]],
 [[312,244,526,476],[302,105,478,268],[392,38,433,99],[242,219,307,268]],
 [[304,170,530,444],[289,93,533,264],[394,37,435,96],[228,190,306,241]],
 [[345,260,526,468],[253,126,579,288],[380,62,426,117],[270,178,355,217]],
 [[331,262,538,425],[290,112,537,287],[399,67,444,127],[253,6,335,119]],
 [[352,236,506,421],[314,83,533,252],[398,27,440,84],[265,193,326,227]],
 [[361,241,443,498],[303,86,499,260],[392,57,436,111],[350,11,470,93]],
 [[369,251,446,499],[318,92,535,270],[396,41,443,103],[294,5,374,113]],
 [[293,269,475,495],[340,126,598,290],[421,53,469,120],[571,91,614,155]],
]
upload_path = ROOT / 'godot/data/workshop/2026-11-18-user-smoke/FightGuild-moves-2026-11-18.json'
raw = upload_path.read_bytes()
draft = json.loads(raw)
assert draft['schema'] == draft['coreVersion'] == 22
default_path = ROOT / 'godot/data/starter_moves.json'
defaults = load(default_path)
moves = draft['characters'][2]['moves']

def key(start, phase, pose): return dict(start=start, phase=phase, pose=pose)
def entry(slot, index):
    move = moves[slot]
    initial = key(0, 'active', 8) if move['air'] else key(0, 'crouch_idle' if move['direction'] == 2 else 'idle', 0)
    destination = key(65, 'signature_windup', move['artPose']-1) if move['artPose'] else key(65, 'windup', 1+move['button'])
    keys = [initial, key(20, 'attack_animation', index), destination]
    if move['category'] == 4: keys = [key(0, 'attack_animation', index)]
    return dict(artPose=move['artPose'], windup=keys)

clips = {str(slot): entry(slot, 8+i) for i,slot in enumerate(slots)}
clips['24'] = entry(24, 27)
clips['7'] = dict(artPose=9,
    windup=[key(0,'crouch_idle',0),key(15,'attack_animation',0),key(55,'attack_animation',1)],
    active=[key(0,'attack_animation',2),key(33,'attack_animation',3),key(66,'attack_animation',4)],
    recovery=[key(0,'attack_animation',5),key(25,'attack_animation',6),key(65,'attack_animation',7)])
for i,slot in enumerate(slots): animation[8+i]['name'] = moves[slot]['id'] + ' / Entry'

# Preserve the previous normal-art indices. Only append four new selector pairs.
for phase in ['signature_windup', 'signature_active']:
    fighter[phase]['frames'] = fighter[phase]['frames'][:20]
    body['poses'][phase] = body['poses'][phase][:20]
# The static review of Backdraft uses the same animation drawings as gameplay.
for phase, index in [('signature_windup',1),('signature_active',2)]:
    fighter[phase]['frames'][8] = copy.deepcopy(animation[index])
    old = body['poses'][phase][8]
    body['poses'][phase][8] = fit(fits[index])
    if 'strike' in old: body['poses'][phase][8]['strike'] = old['strike']

# The approved special entries, body fits and effects are stored independently
# so metadata can be refined without changing the original generated atlases.
special = load(DEST / 'special-registration.json')
for i,frame in enumerate(frames('special_entries', roots=[[400,497]] * 4)):
    frame['name'] = ['236S','236Hs','214S','214Hs'][i] + ' / Entry'
    animation.append(frame)
fits += special['entry_boxes']
pillar, swords = frames('pillar_bodies', roots=[[400,497]] * 4), frames('sword_bodies', roots=[[400,493]] * 4)
for slot, selector, source, pair, name, entry_index in [
    (14,21,pillar,0,'236S / Crystal Pillar Close',28),
    (25,22,pillar,2,'236Hs / Crystal Pillar Far',29),
    (15,23,swords,0,'214S / Poison Sword',30),
    (16,24,swords,2,'214Hs / Flame Blade',31),
]:
    moves[slot]['artPose'] = selector
    defaults['characters'][2]['moves'][slot]['artPose'] = selector
    for phase, offset in [('signature_windup',0),('signature_active',1)]:
        frame = copy.deepcopy(source[pair+offset])
        frame['name'] = name + (' / Windup' if offset == 0 else ' / Active')
        if source is swords:
            frame['effect'] = effect('sword_fx', pair+offset, special['sword_effect_boxes'][pair+offset], offset == 0)
        fighter[phase]['frames'].append(frame)
        poses = special['pillar_boxes'] if source is pillar else special['sword_boxes']
        pose = fit(poses[pair+offset])
        if offset: pose['strike'] = [250,180,480,350] # Existing authored move geometry overrides this fallback.
        body['poses'][phase].append(pose)
    clips[str(slot)] = entry(slot, entry_index)

fighter['attack_animation'] = sheet(animation)
fighter['attack_animations'] = clips
body['poses']['attack_animation'] = [fit(boxes) for boxes in fits]
assert len(animation) == len(fits) == 32
fighter['sword_fx'] = sheet(frames('sword_effects', tight=True))
pillar_effect = sheet(frames('pillar_effect', tight=True))
fighter['projectile_variants'] = {'14': copy.deepcopy(pillar_effect), '25': copy.deepcopy(pillar_effect)}
save(ART / 'manifest.json', manifest)
save(ROOT / 'godot/data/fighter_collision.json', collision)
save(default_path, defaults)
out = upload_path.with_name('FightGuild-Smoke-Animations.json')
save(out, draft)
save(ROOT / 'godot/data/workshop/current.json', {
    'label':'Smoke specials + attack animations · 18 November 2026',
    'status':'user-authored tuning with approved artwork',
    'file':str(out.relative_to(ROOT / 'godot/data/workshop')),
    'sha256':hashlib.sha256(out.read_bytes()).hexdigest(),
    'sourceFile':str(upload_path.relative_to(ROOT / 'godot/data/workshop')),
    'sourceSha256':hashlib.sha256(raw).hexdigest(),
    'previousFile':'2026-11-18-startup/FightGuild-Startup.json',
    'baseCommit':'fe2acc2',
    'note':'Preserves all submitted move/movement values and embedded references; only Smoke special artPose selectors14/25/15/16 map to new21/22/23/24. P2 shared near/far pillar, Venom Sabre and Furnace Cleaver effects with barehand backhand motion. Normal entries and full2Hs fit existing action timing.'
})
print('Registered32 animation keys,4 special pairs, shared pillar, source-preserving workshop batch.')
