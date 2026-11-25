#!/usr/bin/env python3
"""Record the super roster showcase in native Godot on a local display."""
import argparse,os,subprocess,time
from pathlib import Path
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--quick',action='store_true')
args=parser.parse_args()
root=Path(__file__).resolve().parents[1]
out=root/os.environ.get('SUPER_OUTPUT','build/super-showcase')
(out/'stills').mkdir(parents=True,exist_ok=True)
env=os.environ.copy();native=Path(env.get('FIGHT_TOOLS','/workspace/.fight-guild-tools'))/'native-tools/usr'
display_name=env.get('SUPER_DISPLAY',':96')
env.update(DISPLAY=display_name,LIBGL_ALWAYS_SOFTWARE='1',LP_NUM_THREADS='2')
env['LD_LIBRARY_PATH']=str(native/'lib/x86_64-linux-gnu')+':'+env.get('LD_LIBRARY_PATH','')
with (out/'display.log').open('w') as log:
 display=subprocess.Popen([str(native/'bin/Xvfb'),display_name,'-screen','0','1280x720x24','-nolisten','tcp'],env=env,stdout=log,stderr=subprocess.STDOUT)
 try:
  for _ in range(50):
   if display.poll() is not None:raise RuntimeError('Recording display failed')
   if Path('/tmp/.X11-unix/X'+display_name.lstrip(':')).exists():break
   time.sleep(.1)
  cmd=['bash','scripts/godot.sh','--display-driver','x11','--audio-driver','Dummy','--rendering-method','gl_compatibility','--resolution','1280x720']
  if not args.quick:cmd+=['--fixed-fps','60','--write-movie',str(out/'showcase.avi')]
  cmd+=['--script','res://tests/super_showcase.gd','--','--captures',str(out/'stills')]
  if args.quick:cmd+=['--quick']
  with (out/'godot.log').open('w') as game_log:subprocess.run(cmd,cwd=root,env=env,stdout=game_log,stderr=subprocess.STDOUT,check=True,timeout=1800)
  report=(out/'godot.log').read_text()
  if 'ERROR:' in report or 'Super showcase complete' not in report:raise RuntimeError('Native replay failed; see '+str(out/'godot.log'))
  print(report)
 finally:
  display.terminate();display.wait(timeout=10)
