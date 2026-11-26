#!/usr/bin/env python3
"""Record native overhead startup warnings without building the Workshop."""
from pathlib import Path
import os
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'build/overhead-v1'
OUT.mkdir(parents=True, exist_ok=True)
for previous_still in OUT.glob('*.png'):
    previous_still.unlink()  # Prevent screenshots from an older review surviving.
env = os.environ.copy()
native = Path(env.get('FIGHT_TOOLS', '/workspace/.fight-guild-tools')) / 'native-tools/usr'
env['LD_LIBRARY_PATH'] = str(native / 'lib/x86_64-linux-gnu') + ':' + env.get('LD_LIBRARY_PATH', '')
env.update(DISPLAY=':96', LIBGL_ALWAYS_SOFTWARE='1', LP_NUM_THREADS='2')
with (OUT / 'display.log').open('w') as log:
    display = subprocess.Popen([str(native / 'bin/Xvfb'), ':96', '-screen', '0', '1280x720x24', '-nolisten', 'tcp'], env=env, stdout=log, stderr=subprocess.STDOUT)
    try:
        for _ in range(50):
            if display.poll() is not None:
                raise RuntimeError('Native review display failed')
            if Path('/tmp/.X11-unix/X96').exists():
                break
            time.sleep(.1)
        with (OUT / 'godot.log').open('w') as game_log:
            subprocess.run(['bash', 'scripts/godot.sh', '--display-driver', 'x11', '--rendering-method', 'gl_compatibility',
                            '--resolution', '1280x720', '--fixed-fps', '60', '--write-movie', str(OUT / 'review.avi'),
                            '--script', 'res://tests/overhead_review.gd', '--', '--test', '--output', str(OUT)],
                           cwd=ROOT, env=env, stdout=game_log, stderr=subprocess.STDOUT, check=True, timeout=420)
        report = (OUT / 'godot.log').read_text()
        if 'ERROR:' in report or 'Native overhead review: 0 failures' not in report:
            raise RuntimeError('Overhead review failed; see build/overhead-v1/godot.log')
    finally:
        display.terminate()
        display.wait(timeout=10)
target = ROOT / 'exports/FightGuild-Overhead-Warnings-2026-11-26.mp4'
subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', str(OUT / 'review.avi'), '-c:v', 'libx264', '-crf', '18',
                '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-b:a', '160k', '-movflags', '+faststart', str(target)], check=True)
print(target)
