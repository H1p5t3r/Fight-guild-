#!/usr/bin/env python3
"""Lengthen native grab holds after the user's Collar Fold selection."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKSHOP = ROOT / 'godot/data/workshop'
OUTPUT = '2026-11-24-collar-fold/FightGuild-Collar-Fold.json'


def apply(data):
    for character in data['characters']:
        if character['name'] not in ('Fillet', 'Tapper'):
            for slot in (23, 24):
                character['moves'][slot]['grabFrames'] = 40
    tapper = data['characters'][3]
    for slot, duration in ((13, 40), (23, 34), (24, 34), (40, 52)):
        tapper['moves'][slot]['grabFrames'] = duration
        tapper['moves'][slot]['finishArtFrame'] = duration - 4
    fillet = data['characters'][5]
    if 'extensions' in fillet:
        for slot in (23, 24, 45, 46):
            fillet['moves'][slot]['extensions']['params']['pairTicks'] = 40 if slot < 45 else 52
        # Insert time in the held pose; preserve the original catch and final
        # root motion speeds, endpoint spacing, side switch and release gap.
        for track, ticks in ((1, [0, 4, 32, 36, 40]), (2, [0, 4, 28, 36, 40]), (3, [0, 4, 44, 48, 52])):
            keys = fillet['extensions']['pairTracks'][track]
            assert len(keys) == len(ticks)
            for key, tick in zip(keys, ticks):
                key['tick'] = tick


def save(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + '\n')


def main():
    current = json.loads((WORKSHOP / 'current.json').read_text())
    raw = (WORKSHOP / current['file']).read_bytes()
    assert hashlib.sha256(raw).hexdigest() == current['sha256']
    data = json.loads(raw)
    apply(data)
    data.setdefault('_moveWorkshop', {})['collarFoldRevision'] = {
        'date': '2026-11-24', 'direction': 'A / Collar Fold',
        'normalCaptureTicks': 40, 'commandCaptureTicks': 52,
        'notes': 'Longer grounded grab holds; original startup, tech window, damage, release recovery and knockdowns retained. Tapper normal = 6-tick tech gate + 34-tick grip. Wound and air throws retain their existing timing.'}
    save(WORKSHOP / OUTPUT, data)
    repeated = current['file'] == OUTPUT
    save(WORKSHOP / 'current.json', {
        'label': 'Collar Fold · longer grab holds', 'file': OUTPUT,
        'sha256': hashlib.sha256((WORKSHOP / OUTPUT).read_bytes()).hexdigest(),
        'sourceFile': current['sourceFile'] if repeated else current['file'],
        'sourceSha256': current['sourceSha256'] if repeated else current['sha256']})
    path = ROOT / 'godot/data/starter_moves.json'
    starter = json.loads(path.read_text())
    apply(starter)
    save(path, starter)
    print('Grounded normal holds: 40 ticks; command holds: 52; startup, tech and release outcomes retained.')


if __name__ == '__main__':
    main()
