#!/usr/bin/env python3
"""Add the playtest OTG routes to defaults and the latest saved workshop batch."""
import hashlib
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKSHOP = ROOT / 'godot/data/workshop'
OUTPUT = '2026-11-20-fillet-otg/FightGuild-Fillet-OTG.json'
spec = importlib.util.spec_from_file_location('fillet_data', ROOT / 'scripts/fillet-v1-data.py')
fillet_data = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fillet_data)


def save(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + '\n')


def main():
    current = json.loads((WORKSHOP / 'current.json').read_text())
    raw = (WORKSHOP / current['file']).read_bytes()
    assert hashlib.sha256(raw).hexdigest() == current['sha256'], 'Workshop checksum mismatch'
    data = json.loads(raw)
    fillet_data.apply_playtest_routes(data['characters'][5])
    # Preserve every submitted field, note, photo and sequence. This annotation
    # records the intentional change separately from the original art briefs.
    data.setdefault('_moveWorkshop', {})['filletOtgRevision'] = {
        'date': '2026-11-20',
        'routes': ['2S > 5D', '236S > 6S > 5D', '236S > 2S > 5D'],
        'rule': 'Hit-only cancel into Wound after grounded knockdown. No block or whiff cancel.',
    }
    save(WORKSHOP / OUTPUT, data)
    repeated = current['file'] == OUTPUT
    save(WORKSHOP / 'current.json', {
        'label': 'Fillet OTG routes · Shark actionable pull', 'file': OUTPUT,
        'sha256': hashlib.sha256((WORKSHOP / OUTPUT).read_bytes()).hexdigest(),
        'sourceFile': current['sourceFile'] if repeated else current['file'],
        'sourceSha256': current['sourceSha256'] if repeated else current['sha256'],
    })
    path = ROOT / 'godot/data/starter_moves.json'
    starter = json.loads(path.read_text())
    fillet_data.apply_playtest_routes(starter['characters'][5])
    save(path, starter)
    print('Added 2S / Crown / Heel → Wound hit-only routes; timings and all other tuning preserved.')


if __name__ == '__main__':
    main()
