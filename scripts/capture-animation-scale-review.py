#!/usr/bin/env python3
"""Capture fixed-world-scale native comparisons, without editing source artwork."""
import argparse
import os
import subprocess
import time
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', default='build/animation-scale-before')
parser.add_argument('--catalog', action='store_true', help='Review every unique body cell in the roster')
parser.add_argument('--external', action='store_true', help='Review render-only reaction, grab and movement atlases')
parser.add_argument('--character',type=int,choices=range(6))
parser.add_argument('--phase',help='Only render this super phase')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
out = (root / args.output).resolve()
out.mkdir(parents=True, exist_ok=True)
env = os.environ.copy()
native = Path(env.get('FIGHT_TOOLS', '/workspace/.fight-guild-tools')) / 'native-tools/usr'
env.update(DISPLAY=':96', LIBGL_ALWAYS_SOFTWARE='1', LP_NUM_THREADS='2')
env['LD_LIBRARY_PATH'] = str(native/'lib/x86_64-linux-gnu')+':'+env.get('LD_LIBRARY_PATH','')
with (out/'display.log').open('w') as log:
    display = subprocess.Popen([str(native/'bin/Xvfb'), ':96', '-screen', '0',
                                '1800x1600x24', '-nolisten', 'tcp'],
                               env=env, stdout=log, stderr=subprocess.STDOUT)
    try:
        for _ in range(50):
            if display.poll() is not None:
                raise RuntimeError('Review display failed')
            if Path('/tmp/.X11-unix/X96').exists():
                break
            time.sleep(.1)
        command = ['bash', 'scripts/godot.sh', '--display-driver', 'x11',
                   '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy',
                   '--resolution', '1800x1600', '--script',
                   'res://tests/animation_external_scale_review.gd' if args.external else 'res://tests/animation_scale_review.gd', '--', '--test', '--output', str(out)]
        if args.catalog:
            command.append('--catalog')
        if args.character is not None:
            command += ['--character',str(args.character)]
        if args.phase:
            command += ['--phase',args.phase]
        with (out/'godot.log').open('w') as game_log:
            subprocess.run(command, cwd=root, env=env, stdout=game_log,
                           stderr=subprocess.STDOUT, check=True, timeout=180)
        report = (out/'godot.log').read_text()
        if 'ERROR:' in report or 'Animation scale review complete' not in report:
            raise RuntimeError('Native review failed; see '+str(out/'godot.log'))
    finally:
        display.terminate()
        display.wait(timeout=10)
print(out)
