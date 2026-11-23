#!/usr/bin/env python3
"""Calibrate Fillet's legacy hurt drawing without changing generated pixels."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'godot/assets/fighters'
path = ART / 'manifest.json'
manifest = json.loads(path.read_text())
fighter = manifest['fighters'][5]
assert fighter['name'] == 'Fillet'
sheet = fighter['active']
assert sheet['file'] == 'appearance-v3/fillet-active.png'
assert hashlib.sha256((ART / sheet['file']).read_bytes()).hexdigest() == 'ec937112021a82535d2304c4e97bd37c5cbd32f91097657a88dd3d5d748c029c'
frame = sheet['frames'][9]
assert frame['region'] == [384, 682, 384, 342] and frame['pivot'] == [190, 319]
# The sheet-wide 310px scale enlarged this legacy drawing relative to the
# approved Stalker stance/new attacks. Use a fixed standing-equivalent scale,
# never the changing silhouette bounds. Feet stay at the existing world root.
frame['body_height'] = 350
fighter['reaction_scale_calibration'] = {
    'reference': 'appearance-v3/fillet-ready.png / Stalker stance; fillet-ground-v1/5p.png / attack entry',
    'phase': 'active', 'pose': 9, 'previous_body_height': 310, 'body_height': 350,
    'method': 'Fixed uniform pose scale, matched in a native equal-zoom review. Ground hit, air reel, splat and captured reactions share this drawing and pivot. Knockdown/get-up, attack and locomotion scales are unchanged.',
    'rebuild': 'python scripts/calibrate-fillet-reactions.py && python scripts/generate-combat-data.py',
}
path.write_text(json.dumps(manifest, indent=2) + '\n')
print('Fillet hurt pose: fixed 350px reference; original atlas/pivot and other poses unchanged.')
