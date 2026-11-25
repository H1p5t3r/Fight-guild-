#!/usr/bin/env python3
"""Capture the native super-freeze presentation without adding supers or publishing the Workshop."""
from pathlib import Path
import argparse
import os
import shutil
import subprocess
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--stills', action='store_true')
parser.add_argument('--size', default='1280x720')
args = parser.parse_args()
width, height = map(int, args.size.split('x'))
root = Path(__file__).resolve().parents[1]
out = root / 'build/super-freeze-review' / args.size
out.mkdir(parents=True, exist_ok=True)
native = Path(os.environ.get('FIGHT_TOOLS', '/workspace/.fight-guild-tools')) / 'native-tools/usr'
env = os.environ.copy()
env['LD_LIBRARY_PATH'] = str(native / 'lib/x86_64-linux-gnu') + ':' + env.get('LD_LIBRARY_PATH', '')
env.update(DISPLAY=':96', LIBGL_ALWAYS_SOFTWARE='1', LP_NUM_THREADS='2')
with (out / 'display.log').open('w') as log:
    display = subprocess.Popen([str(native / 'bin/Xvfb'), ':96', '-screen', '0', f'{width}x{height}x24',
                                '-nolisten', 'tcp'], env=env, stdout=log, stderr=subprocess.STDOUT)
    try:
        for _ in range(50):
            if display.poll() is not None:
                raise RuntimeError('Virtual display failed; see ' + str(out / 'display.log'))
            if Path('/tmp/.X11-unix/X96').exists():
                break
            time.sleep(.1)
        command = ['bash', 'scripts/godot.sh', '--display-driver', 'x11', '--audio-driver', 'Dummy',
                   '--resolution', args.size, '--fixed-fps', '60']
        if not args.stills:
            command += ['--write-movie', str(out / 'super-freeze.avi')]
        command += ['--script', 'tests/super_freeze_preview.gd', '--', '--test', '--output', str(out)]
        if args.stills:
            command += ['--stills']
        with (out / 'godot.log').open('w') as game_log:
            subprocess.run(command, cwd=root, env=env, stdout=game_log, stderr=subprocess.STDOUT,
                           check=True, timeout=240)
        report = (out / 'godot.log').read_text()
        if 'ERROR:' in report or 'Native super freeze review: PASS' not in report:
            raise RuntimeError('Native review failed: ' + str(out / 'godot.log'))
        print(report, flush=True)
    finally:
        display.terminate()
        display.wait(timeout=10)
if not args.stills:
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', str(out / 'super-freeze.avi'),
                    '-c:v', 'libx264', '-crf', '19', '-pix_fmt', 'yuv420p', '-an', '-movflags', '+faststart',
                    str(root / 'exports/FightGuild-Super-Freeze-Review.mp4')], check=True)
    (out / 'super-freeze.avi').unlink()
for name in ['fillet', 'shark', 'smoke', 'tapper', 'hammer', 'anvil']:
    shutil.copyfile(out / (name + '.png'), root / 'exports' / ('FightGuild-Super-Freeze-' + name.capitalize() + '.png'))
print('Super-freeze review saved to ' + str(out), flush=True)
