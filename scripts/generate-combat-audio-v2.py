#!/usr/bin/env python3
"""Native combat sound bank: dry attacks, material transients and restrained bass.

All samples are original deterministic synthesis. The first bank stays intact
for the paused browser editor. Requires numpy/scipy only when regenerating.
"""
from pathlib import Path
import hashlib
import json
import wave

import numpy as np
from scipy.signal import butter, sosfilt

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'godot/assets/audio/combat-v2'
RATE = 48000
FAMILIES = {
    # duration, body Hz, noise band, metal partial, decay
    'body': (.19, 105, (180, 3200), 0, .032),
    'cut': (.19, 145, (1700, 13000), 1750, .021),
    'spear': (.24, 115, (850, 10000), 940, .027),
    'hammer': (.34, 62, (180, 5700), 430, .057),
    'shield': (.29, 78, (360, 8500), 720, .044),
    'gas': (.32, 90, (550, 6800), 0, .052),
    'fire': (.33, 70, (450, 12500), 0, .050),
    'stone': (.30, 80, (220, 8000), 1350, .042),
}
DEFENSE = {
    'block': (.21, 170, (600, 11000), 1250, .024),
    'faultless': (.30, 230, (900, 7200), 1900, .038),
    'guard_break': (.42, 70, (900, 14500), 2400, .050),
    'armor': (.27, 92, (350, 8200), 810, .038),
    'counter': (.37, 46, (60, 1800), 0, .060),
    'heavy': (.27, 58, (65, 1500), 0, .047),
    'land': (.18, 85, (120, 3400), 0, .027),
    'wall': (.34, 54, (150, 5000), 0, .055),
    'wall_break': (.52, 45, (190, 11000), 380, .074),
    'clash': (.27, 150, (1200, 14000), 2250, .030),
}


def render(name, spec, variant, swing=False):
    duration, body, band, ring, decay = spec
    if swing:
        duration = .11 if name in ('body', 'cut') else .17
    seed = int.from_bytes(hashlib.sha256(f'{name}/{variant}/{swing}/v2'.encode()).digest()[:8], 'little')
    rng = np.random.default_rng(seed)
    t = np.arange(round(duration * RATE)) / RATE
    noise = rng.normal(0, 1, len(t))
    air = sosfilt(butter(2, band, 'bandpass', fs=RATE, output='sos'), noise)
    low = sosfilt(butter(2, 900, fs=RATE, output='sos'), noise)
    if swing:
        # Fast release, rather than a long swell peaking after the actual hit.
        env = (1 - np.exp(-t / .0025)) * np.exp(-t / .023)
        signal = air * env * 2.2 + low * env * .35
    else:
        env = np.exp(-t / decay)
        transient = air * np.exp(-t / .0045) * 2.6
        signal = transient + air * env * .75
        drop = 2 * np.pi * (body * t + body * .85 * .016 * (1 - np.exp(-t / .016)))
        signal += .70 * np.sin(drop) * env
        if ring:
            for ratio, gain in [(1, .16), (1.71, .10), (2.63, .065), (3.77, .025)]:
                frequency = ring * ratio * (1 + (variant - 1) * .018)
                signal += gain * np.sin(2 * np.pi * frequency * t) * np.exp(-t / (decay * 1.65))
        if name in ('gas', 'fire', 'stone', 'guard_break', 'wall_break'):
            # Different material tails: breath, embers or irregular fragments.
            scatter = 8 if name in ('stone', 'guard_break', 'wall_break') else 15
            for delay in rng.uniform(.014, duration * .6, scatter):
                dt = np.maximum(0, t - delay)
                burst = (t >= delay) * np.exp(-dt / (.004 if name == 'fire' else .010))
                signal += air * burst * (.28 if name == 'gas' else .5)
        if name == 'gas': signal += air * (1 - np.exp(-t / .012)) * np.exp(-t / .085) * .8
        if name == 'faultless':
            signal += .14 * np.sin(2 * np.pi * 2850 * t) * np.exp(-t / .065)
        if name in ('counter', 'heavy', 'wall', 'wall_break'):
            signal += low * env * .7
    signal *= np.minimum(1, t / .00035) * np.minimum(1, (duration - t) / .014)
    signal -= signal.mean()
    signal = np.tanh(signal * 1.15)
    signal *= .63 / max(.001, np.abs(signal).max())
    signal[0] = signal[-1] = 0
    return signal


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    sounds = []
    for group, specs, variants in [('hit_', FAMILIES, 3), ('swing_', FAMILIES, 2), ('', DEFENSE, 2)]:
        for name, spec in specs.items():
            for variant in range(variants):
                signal = render(name, spec, variant, group == 'swing_')
                stem = group + name + (f'_{variant + 1}' if variant else '')
                path = OUT / (stem + '.wav')
                pcm = np.round(signal * 32767).astype('<i2')
                with wave.open(str(path), 'wb') as wav:
                    wav.setparams((1, 2, RATE, len(pcm), 'NONE', 'not compressed'))
                    wav.writeframes(pcm.tobytes())
                sounds.append({'file': path.name, 'seconds': len(pcm) / RATE,
                               'peakDb': round(float(20 * np.log10(np.abs(signal).max())), 2),
                               'rmsDb': round(float(20 * np.log10(np.sqrt(np.mean(signal ** 2)))), 2),
                               'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    (OUT / 'manifest.json').write_text(json.dumps({
        'format': 2, 'author': 'Fight Guild',
        'source': 'Original deterministic synthesis; no external recordings or samples',
        'generator': 'scripts/generate-combat-audio-v2.py', 'rate': RATE,
        'sounds': sounds,
    }, indent=2) + '\n')
    print(f'Wrote {len(sounds)} original native effects to {OUT}')


if __name__ == '__main__':
    main()
