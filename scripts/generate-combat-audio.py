#!/usr/bin/env python3
"""Original, deterministic contact sounds. No recordings or third-party samples.

Regenerate with Python + numpy + scipy. Runtime only needs the checked-in WAVs.
Short noise transients, resonant material bodies and dry tails leave room for
rapid strings. Never stretch audio to alter combat timing.
"""
from pathlib import Path
import hashlib
import json
import wave
import numpy as np
from scipy.signal import butter, sosfilt

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'godot/assets/audio/combat'
RATE = 48000

def create(name, duration, cutoff, body, ring=0, sweep=False):
    seed = int.from_bytes(hashlib.sha256(name.encode()).digest()[:4], 'little')
    rng = np.random.default_rng(seed)
    t = np.arange(round(duration * RATE)) / RATE
    noise = sosfilt(butter(2, cutoff, fs=RATE, output='sos'), rng.normal(0, 1, len(t)))
    if sweep:
        env = np.sin(np.pi * np.minimum(1, t / duration)) ** 1.2
        signal = noise * env * (0.6 + 0.4 * np.sin(t * 25))
    else:
        env = np.exp(-t / (duration / 6))
        signal = noise * env * 1.6
        # A falling low body, not a pitched game/UI beep.
        phase = 2 * np.pi * (body * t + body * 0.6 * 0.025 * (1 - np.exp(-t / .025)))
        signal += .5 * np.sin(phase) * np.exp(-t / (duration / 5))
        if ring:
            for multiplier, gain in [(1, .15), (1.47, .1), (2.13, .05)]:
                signal += gain * np.sin(2 * np.pi * ring * multiplier * t) * np.exp(-t / .055)
        # Small dry after-transients suggest fragments/material rather than reverb.
        for delay, gain in [(.019, .28), (.041, .15), (.074, .07)]:
            offset = round(delay * RATE)
            if offset < len(t): signal[offset:] += noise[:-offset] * gain * np.exp(-t[:-offset] / .016)
    signal *= np.minimum(1, t / .0008) * np.minimum(1, (duration - t) / .012)
    signal -= signal.mean()
    signal = np.tanh(signal * 1.25)
    signal *= .70 / max(.001, abs(signal).max())
    pcm = np.round(signal * 32767).astype('<i2')
    with wave.open(str(OUT / (name + '.wav')), 'wb') as wav:
        wav.setparams((1, 2, RATE, len(pcm), 'NONE', 'not compressed'))
        wav.writeframes(pcm.tobytes())
    return {'file': name + '.wav', 'seconds': duration,
            'sha256': hashlib.sha256((OUT / (name + '.wav')).read_bytes()).hexdigest()}

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    sounds = []
    families = {
        'body': (.17, 1300, 100, 0), 'cut': (.15, 7800, 160, 1200),
        'spear': (.19, 5700, 125, 720), 'hammer': (.27, 2100, 65, 430),
        'gas': (.28, 3400, 80, 0), 'fire': (.29, 6400, 65, 0),
        'stone': (.24, 3100, 80, 1100),
    }
    for family, spec in families.items():
        sounds.append(create('hit_' + family, *spec))
        sounds.append(create('swing_' + family, .12 if family == 'cut' else .19,
                             spec[1] * .65, spec[2], sweep=True))
    for name, spec in {
        'block': (.19, 4100, 180, 980), 'faultless': (.25, 2300, 200, 1550),
        'guard_break': (.38, 6200, 75, 1100), 'armor': (.22, 3300, 85, 680),
        'counter': (.32, 800, 42, 0), 'land': (.17, 1900, 80, 0),
        'wall': (.32, 2300, 54, 0), 'wall_break': (.52, 5200, 42, 320),
        'clash': (.23, 5500, 130, 1600),
    }.items(): sounds.append(create(name, *spec))
    (OUT / 'manifest.json').write_text(json.dumps({
        'author': 'Fight Guild', 'source': 'Original procedural synthesis; no external samples',
        'generator': 'scripts/generate-combat-audio.py', 'rate': RATE, 'sounds': sounds,
    }, indent=2) + '\n')
    print(f'Wrote {len(sounds)} original mono effects to {OUT}')

if __name__ == '__main__': main()
