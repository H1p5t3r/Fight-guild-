#!/usr/bin/env python3
"""Record one finished super from its production plan, in native Godot at 60 FPS."""
import argparse
import os
import json
import subprocess
import time
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('super', help='production folder, e.g. flashpoint')
parser.add_argument('--case', choices=['hit','mirrored','block','whiff','followup'])
parser.add_argument('--stills', action='store_true')
parser.add_argument('--baseline', action='store_true')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
plan = json.loads((root/'art/characters/supers-v2'/args.super/'exposure-plan.json').read_text())
review = 'super_cast_review.gd' if plan['pairTicks']==0 else 'super_animation_review.gd'
out = root/'build'/(args.super+('-before' if args.baseline else '')+('-'+args.case if args.case else ''))
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
        cmd += ['--script','res://tests/'+review,'--','--test','--character',str(plan['character']),'--slot',str(plan['slot']),'--output',str(out)]
        if args.stills: cmd += ['--stills']
        if args.case: cmd += ['--case',args.case]
        if args.baseline: cmd += ['--baseline']
        with (out/'godot.log').open('w') as game_log:
            subprocess.run(cmd,cwd=root,env=env,stdout=game_log,stderr=subprocess.STDOUT,check=True,timeout=480)
        report = (out/'godot.log').read_text()
        if 'ERROR:' in report or 'Super animation review: 0 failures' not in report: raise RuntimeError('Native review failed; see '+str(out/'godot.log'))
    finally:
        display.terminate()
        display.wait(timeout=10)
if not args.stills:
    target = out/'case.mp4' if args.case else out/'before.mp4' if args.baseline else root/'exports'/('FightGuild-'+plan['name'].replace(' ','-')+'-2026-11-25.mp4')
    subprocess.run(['ffmpeg','-y','-loglevel','error','-i',str(out/'review.avi'),'-c:v','libx264','-crf','18','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-movflags','+faststart',str(target)],check=True)
    print('Native review:',target)
else:
    print('Native stills:',out)
