#!/usr/bin/env python3
"""Native Sky Foundry review: unchanged gameplay, fresh art, both facings and miss."""
import argparse
import os
import subprocess
import time
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--stills', action='store_true')
parser.add_argument('--baseline', action='store_true')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
out = root / ('build/sky-foundry-before' if args.baseline else 'build/sky-foundry')
out.mkdir(parents=True, exist_ok=True)
env = os.environ.copy()
native = Path(env.get('FIGHT_TOOLS', '/workspace/.fight-guild-tools')) / 'native-tools/usr'
env.update(DISPLAY=':96', LIBGL_ALWAYS_SOFTWARE='1', LP_NUM_THREADS='2')
env['LD_LIBRARY_PATH'] = str(native/'lib/x86_64-linux-gnu')+':'+env.get('LD_LIBRARY_PATH','')
with (out/'display.log').open('w') as log:
    display = subprocess.Popen([str(native/'bin/Xvfb'),':96','-screen','0','1280x720x24','-nolisten','tcp'],env=env,stdout=log,stderr=subprocess.STDOUT)
    try:
        for _ in range(50):
            if display.poll() is not None: raise RuntimeError('Review display failed')
            if Path('/tmp/.X11-unix/X96').exists(): break
            time.sleep(.1)
        cmd = ['bash','scripts/godot.sh','--display-driver','x11','--rendering-method','gl_compatibility','--resolution','1280x720']
        if args.stills: cmd += ['--audio-driver','Dummy']
        if not args.stills: cmd += ['--fixed-fps','60','--write-movie',str(out/'review.avi')]
        cmd += ['--script','res://tests/sky_foundry_review.gd','--','--test','--output',str(out)]
        if args.stills: cmd += ['--stills']
        if args.baseline: cmd += ['--baseline']
        with (out/'godot.log').open('w') as game_log:
            subprocess.run(cmd,cwd=root,env=env,stdout=game_log,stderr=subprocess.STDOUT,check=True,timeout=480)
        report = (out/'godot.log').read_text()
        if 'ERROR:' in report or 'Sky Foundry review: 0 failures' not in report: raise RuntimeError('Native review failed; see '+str(out/'godot.log'))
    finally:
        display.terminate()
        display.wait(timeout=10)
if not args.stills:
    target = out/'before.mp4' if args.baseline else root/'exports/FightGuild-Sky-Foundry-2026-11-25.mp4'
    subprocess.run(['ffmpeg','-y','-loglevel','error','-i',str(out/'review.avi'),'-c:v','libx264','-crf','18','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-movflags','+faststart',str(target)],check=True)
    print('Native review:',target)
else:
    print('Native stills:',out)
