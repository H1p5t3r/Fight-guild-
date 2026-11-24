#!/usr/bin/env python3
"""Record actual Godot movement; does not build or publish the website."""
from pathlib import Path
import argparse
import os
import subprocess
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--label', default='AFTER')
parser.add_argument('--output', default='build/movement-after')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
out = (root / args.output).resolve()
out.mkdir(parents=True, exist_ok=True)
env = os.environ.copy()
native = Path(env.get('FIGHT_TOOLS', '/workspace/.fight-guild-tools')) / 'native-tools/usr'
env['LD_LIBRARY_PATH'] = str(native / 'lib/x86_64-linux-gnu') + ':' + env.get('LD_LIBRARY_PATH', '')
env['DISPLAY'] = ':97'
env['LIBGL_ALWAYS_SOFTWARE'] = '1'
with (out / 'display.log').open('w') as log:
    display = subprocess.Popen([str(native / 'bin/Xvfb'), ':97', '-screen', '0', '1440x810x24', '-nolisten', 'tcp'],
                               env=env, stdout=log, stderr=subprocess.STDOUT)
    try:
        for _ in range(50):
            if display.poll() is not None:
                raise RuntimeError('Review display failed; see ' + str(out / 'display.log'))
            if Path('/tmp/.X11-unix/X97').exists(): break
            time.sleep(.1)
        with (out / 'godot.log').open('w') as game_log:
            subprocess.run(['bash', 'scripts/godot.sh', '--display-driver', 'x11', '--audio-driver', 'Dummy',
                            '--rendering-method', 'gl_compatibility', '--resolution', '1440x810',
                            '--fixed-fps', '60', '--write-movie', str(out / 'movement.avi'),
                            '--script', 'res://tests/movement_preview.gd', '--', '--test',
                            '--label', args.label, '--output', str(out)], cwd=root, env=env,
                           stdout=game_log, stderr=subprocess.STDOUT, check=True, timeout=240)
        report = (out / 'godot.log').read_text()
        if 'ERROR:' in report or 'Native movement review: 750 simulation frames captured' not in report:
            raise RuntimeError('Godot review failed; see ' + str(out / 'godot.log'))
    finally:
        display.terminate()
        display.wait(timeout=10)
subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', str(out / 'movement.avi'),
                '-c:v', 'libx264', '-crf', '20', '-pix_fmt', 'yuv420p', '-an', '-movflags', '+faststart',
                str(out / 'movement.mp4')], check=True)
print('Native movement review saved to ' + str(out / 'movement.mp4'))
