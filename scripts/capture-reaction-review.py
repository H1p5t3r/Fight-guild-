#!/usr/bin/env python3
"""Record the native Compact Snap pose review; never build or publish the website."""
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
out = root / 'build/reaction-review'
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
            if display.poll() is not None: raise RuntimeError('Review display failed; see build/reaction-review/display.log')
            if Path('/tmp/.X11-unix/X96').exists(): break
            time.sleep(.1)
        command = ['bash','scripts/godot.sh','--display-driver','x11','--audio-driver','Dummy','--rendering-method','gl_compatibility','--resolution','1440x810']
        if not args.stills: command += ['--fixed-fps','60','--write-movie',str(out/'reactions.avi')]
        command += ['--script','res://tests/reactions_preview.gd','--','--test','--output',str(out)]
        if args.stills: command += ['--stills']
        with (out / 'godot.log').open('w') as game_log:
            subprocess.run(command,cwd=root,env=env,stdout=game_log,stderr=subprocess.STDOUT,check=True,timeout=240)
        if 'ERROR:' in (out / 'godot.log').read_text(): raise RuntimeError('Godot review reported an error; see its log')
    finally:
        display.terminate(); display.wait(timeout=10)
if not args.stills:
    subprocess.run(['ffmpeg','-y','-loglevel','error','-i',str(out/'reactions.avi'),'-c:v','libx264','-crf','19','-pix_fmt','yuv420p','-an','-movflags','+faststart',str(root/'exports/FightGuild-Compact-Snap-Reactions.mp4')],check=True)
shutil.copyfile(out / '5-reactions.png', root / 'exports/FightGuild-Compact-Snap-Fillet.png')
print('Native reaction review saved.')
