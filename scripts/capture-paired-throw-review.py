#!/usr/bin/env python3
"""Record native Collar Fold grips and longer holds; no website build."""
from pathlib import Path
import argparse
import os
import shutil
import subprocess
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--stills', action='store_true')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
out = root / 'build/paired-throw-review'
out.mkdir(parents=True, exist_ok=True)
env = os.environ.copy()
native = Path(env.get('FIGHT_TOOLS', '/workspace/.fight-guild-tools')) / 'native-tools/usr'
env['LD_LIBRARY_PATH'] = str(native / 'lib/x86_64-linux-gnu') + ':' + env.get('LD_LIBRARY_PATH', '')
env['DISPLAY'] = ':96'
env['LIBGL_ALWAYS_SOFTWARE'] = '1'
with (out / 'display.log').open('w') as log:
    display = subprocess.Popen([str(native / 'bin/Xvfb'), ':96', '-screen', '0', '1440x810x24', '-nolisten', 'tcp'], env=env, stdout=log, stderr=subprocess.STDOUT)
    try:
        for _ in range(50):
            if display.poll() is not None:
                raise RuntimeError('Review display failed; see build/paired-throw-review/display.log')
            if Path('/tmp/.X11-unix/X96').exists():
                break
            time.sleep(.1)
        with (out / 'godot.log').open('w') as game_log:
            command = ['bash', 'scripts/godot.sh', '--display-driver', 'x11', '--audio-driver', 'Dummy',
                       '--rendering-method', 'gl_compatibility', '--resolution', '1440x810']
            if not args.stills: command += ['--fixed-fps', '60', '--write-movie', str(out / 'throws.avi')]
            command += ['--script', 'res://tests/paired_throws_preview.gd', '--', '--test', '--output', str(out)]
            if args.stills: command += ['--stills']
            subprocess.run(command,
                           cwd=root, env=env, stdout=game_log, stderr=subprocess.STDOUT, check=True, timeout=240)
        report = (out / 'godot.log').read_text()
        if 'ERROR:' in report or 'Native paired throw review: 0 failures' not in report:
            raise RuntimeError('Godot review failed; see build/paired-throw-review/godot.log')
    finally:
        display.terminate()
        display.wait(timeout=10)
if not args.stills:
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', str(out / 'throws.avi'), '-c:v', 'libx264',
                '-crf', '20', '-pix_fmt', 'yuv420p', '-an', '-movflags', '+faststart',
                str(root / 'exports/FightGuild-Collar-Fold-Grabs.mp4')], check=True)
shutil.copyfile(out / '5-24-hold.png', root / 'exports/FightGuild-Collar-Fold-Grab.png')
print('Native Collar Fold review saved.')
