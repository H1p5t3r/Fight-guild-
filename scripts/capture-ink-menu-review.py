#!/usr/bin/env python3
"""Capture the native guild-ink menu flow and its real 60 fps transitions."""
from pathlib import Path
import argparse
import os
import shutil
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('--stills', action='store_true', help='Skip the animation reel')
parser.add_argument('--size', default='1280x720')
parser.add_argument('--display', default=':97', help='X display for independent native review runs')
args = parser.parse_args()
width, height = map(int, args.size.split('x'))
root = Path(__file__).resolve().parents[1]
output = root / 'build/menu-redesign' / args.size
output.mkdir(parents=True, exist_ok=True)
native = Path(os.environ.get('FIGHT_TOOLS', '/workspace/.fight-guild-tools')) / 'native-tools/usr'
env = os.environ.copy()
env['LD_LIBRARY_PATH'] = str(native / 'lib/x86_64-linux-gnu') + ':' + env.get('LD_LIBRARY_PATH', '')
env.update(DISPLAY=args.display, LIBGL_ALWAYS_SOFTWARE='1', LP_NUM_THREADS='2')

def capture(name, extra, expected):
    with (output / (name + '.log')).open('w') as log:
        subprocess.run(['bash', 'scripts/godot.sh', '--display-driver', 'x11', '--audio-driver', 'Dummy',
                        '--resolution', args.size, *extra, '--script', 'tests/ink_menu_review.gd', '--', '--test',
                        *(['--tour'] if name == 'tour' else ['--output', str(output)])],
                       cwd=root, env=env, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=300)
    report = (output / (name + '.log')).read_text()
    if 'ERROR:' in report or expected not in report:
        raise RuntimeError('Capture failed: ' + str(output / (name + '.log')))
    print(report, flush=True)

with (output / 'display.log').open('w') as log:
    display = subprocess.Popen([str(native / 'bin/Xvfb'), args.display, '-screen', '0',
                                f'{width}x{height}x24', '-nolisten', 'tcp'], env=env,
                               stdout=log, stderr=subprocess.STDOUT)
    try:
        for _ in range(50):
            if display.poll() is not None: raise RuntimeError('Virtual display failed')
            if Path('/tmp/.X11-unix/X' + args.display.removeprefix(':')).exists(): break
            time.sleep(.1)
        capture('stills', [], 'Native ink menus: 0 failures')
        if not args.stills:
            capture('tour', ['--fixed-fps', '60', '--write-movie', str(output / 'menus.avi')],
                    'Native ink menu tour complete')
    finally:
        display.terminate()
        display.wait(timeout=10)

if args.size == '1280x720':
    for source, name in [('01-home', 'FightGuild-Ink-Main-Menu'), ('guild-shark', 'FightGuild-Ink-Fishermen'),
                         ('guild-smoke', 'FightGuild-Ink-Alchemists'), ('04-fighters', 'FightGuild-Ink-Fighter-Select'),
                         ('06-pause', 'FightGuild-Ink-Pause'), ('13-pause-active', 'FightGuild-Ink-Pause-Attack'),
                         ('pause-3-0', 'FightGuild-Ink-Pause-Blacksmiths'), ('07-results', 'FightGuild-Ink-Results'),
                         ('03-sides', 'FightGuild-Side-Select'), ('09-controls', 'FightGuild-Controls')]:
        shutil.copyfile(output / (source + '.png'), root / 'exports' / (name + '.png'))
    if not args.stills:
        subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', str(output / 'menus.avi'),
                        '-c:v', 'libx264', '-crf', '20', '-pix_fmt', 'yuv420p', '-an', '-movflags', '+faststart',
                        str(root / 'exports/FightGuild-Ink-Menu-Tour.mp4')], check=True)
        (output / 'menus.avi').unlink()
print('Native menu review saved to ' + str(output), flush=True)
