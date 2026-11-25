#!/usr/bin/env python3
"""Record the native Godot impact review; never builds or publishes the website."""
from pathlib import Path
import os
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'build/impact-review-v2'
OUT.mkdir(parents=True, exist_ok=True)
env = os.environ.copy()
tools = Path(env.get('FIGHT_TOOLS', '/workspace/.fight-guild-tools'))
env['LD_LIBRARY_PATH'] = str(tools / 'native-tools/usr/lib/x86_64-linux-gnu') + ':' + env.get('LD_LIBRARY_PATH', '')
env['DISPLAY'] = ':96'
env['LIBGL_ALWAYS_SOFTWARE'] = '1'
with (OUT / 'display.log').open('w') as log:
    display = subprocess.Popen([str(tools / 'native-tools/usr/bin/Xvfb'), ':96', '-screen', '0', '1280x720x24', '-nolisten', 'tcp'], env=env, stdout=log, stderr=subprocess.STDOUT)
    try:
        for _ in range(50):
            if display.poll() is not None: raise RuntimeError('Review display failed; see build/impact-review-v2/display.log')
            if Path('/tmp/.X11-unix/X96').exists(): break
            time.sleep(.1)
        with (OUT / 'godot.log').open('w') as game_log:
            subprocess.run(['bash', 'scripts/godot.sh', '--display-driver', 'x11', '--rendering-method', 'gl_compatibility',
                            '--resolution', '1280x720', '--fixed-fps', '60', '--write-movie', str(OUT / 'impacts.avi'),
                            '--script', 'res://tests/impacts_preview.gd', '--', '--test', '--output', str(OUT)],
                           cwd=ROOT, env=env, stdout=game_log, stderr=subprocess.STDOUT, check=True, timeout=480)
        if 'ERROR:' in (OUT / 'godot.log').read_text(): raise RuntimeError('Godot review reported an error; see its log')
    finally:
        display.terminate()
        display.wait(timeout=10)
subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', str(OUT / 'impacts.avi'), '-c:v', 'libx264', '-crf', '20',
                '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-b:a', '160k', '-movflags', '+faststart',
                str(ROOT / 'exports/FightGuild-Combat-Effects-2026-11-25.mp4')], check=True)
print('Native review: exports/FightGuild-Combat-Effects-2026-11-25.mp4')
