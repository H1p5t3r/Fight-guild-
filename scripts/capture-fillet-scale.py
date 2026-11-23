#!/usr/bin/env python3
"""Capture the native equal-zoom Fillet comparison without building the website."""
from pathlib import Path
import os
import subprocess
import time

root = Path(__file__).resolve().parents[1]
out = root / 'build/fillet-scale'
out.mkdir(parents=True, exist_ok=True)
env = os.environ.copy()
native = Path(env.get('FIGHT_TOOLS', '/workspace/.fight-guild-tools')) / 'native-tools/usr'
env['LD_LIBRARY_PATH'] = str(native / 'lib/x86_64-linux-gnu') + ':' + env.get('LD_LIBRARY_PATH', '')
env['DISPLAY'] = ':96'
env['LIBGL_ALWAYS_SOFTWARE'] = '1'
with (out / 'display.log').open('w') as log:
    display = subprocess.Popen([str(native / 'bin/Xvfb'), ':96', '-screen', '0', '1440x900x24', '-nolisten', 'tcp'], env=env, stdout=log, stderr=subprocess.STDOUT)
    try:
        for _ in range(50):
            if display.poll() is not None: raise RuntimeError('Display failed; see build/fillet-scale/display.log')
            if Path('/tmp/.X11-unix/X96').exists(): break
            time.sleep(.1)
        result = subprocess.run(['bash', 'scripts/godot.sh', '--display-driver', 'x11', '--audio-driver', 'Dummy',
            '--rendering-method', 'gl_compatibility', '--script', 'res://tests/fillet_scale_preview.gd', '--', '--test',
            '--screenshot', str(root / 'exports/Fillet-Hit-Reaction-Scale.png')], cwd=root, env=env, capture_output=True, text=True, timeout=60)
        (out / 'godot.log').write_text(result.stdout + result.stderr)
        if result.returncode or 'ERROR:' in result.stdout + result.stderr: raise RuntimeError('Native review failed; see build/fillet-scale/godot.log')
    finally:
        display.terminate()
        display.wait(timeout=10)
print('Native comparison: exports/Fillet-Hit-Reaction-Scale.png')
