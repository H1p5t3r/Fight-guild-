#!/usr/bin/env python3
"""Native 60 Hz Anvil review; no browser build or pixel editing."""
import argparse,os,subprocess,time,shutil
from pathlib import Path
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--stills',action='store_true')
args=parser.parse_args()
root=Path(__file__).resolve().parents[1];out=root/'build/anvil-review';out.mkdir(parents=True,exist_ok=True)
env=os.environ.copy();native=Path(env.get('FIGHT_TOOLS','/workspace/.fight-guild-tools'))/'native-tools/usr'
env['LD_LIBRARY_PATH']=str(native/'lib/x86_64-linux-gnu')+':'+env.get('LD_LIBRARY_PATH','')
env['DISPLAY']=':96';env['LIBGL_ALWAYS_SOFTWARE']='1'
with (out/'display.log').open('w') as log:
    display=subprocess.Popen([str(native/'bin/Xvfb'),':96','-screen','0','1280x720x24','-nolisten','tcp'],env=env,stdout=log,stderr=subprocess.STDOUT)
    try:
        for _ in range(50):
            if display.poll() is not None:raise RuntimeError('Review display failed')
            if Path('/tmp/.X11-unix/X96').exists():break
            time.sleep(.1)
        cmd=['bash','scripts/godot.sh','--display-driver','x11','--audio-driver','Dummy','--rendering-method','gl_compatibility','--resolution','1280x720']
        if not args.stills:cmd+=['--fixed-fps','60','--write-movie',str(out/'anvil.avi')]
        cmd+=['--script','res://tests/anvil_art_review.gd','--','--test','--output',str(out)]
        if args.stills:cmd+=['--stills']
        with (out/'godot.log').open('w') as game_log:subprocess.run(cmd,cwd=root,env=env,stdout=game_log,stderr=subprocess.STDOUT,check=True,timeout=600)
        report=(out/'godot.log').read_text()
        if 'ERROR:' in report or 'Anvil native review complete' not in report:raise RuntimeError('Native review failed; see build/anvil-review/godot.log')
    finally:
        display.terminate();display.wait(timeout=10)
if not args.stills:
    subprocess.run(['ffmpeg','-y','-loglevel','error','-i',str(out/'anvil.avi'),'-c:v','libx264','-crf','20','-pix_fmt','yuv420p','-an','-movflags','+faststart',str(root/'exports/FightGuild-Anvil-Bull.mp4')],check=True)
shutil.copyfile(out/'anvil--1.png',root/'exports/FightGuild-Anvil-Bull.png')
print('Native Anvil review saved.')
