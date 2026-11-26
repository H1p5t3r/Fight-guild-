#!/usr/bin/env python3
"""Native combo-trial screenshots/video; no browser Workshop build or publish."""
from pathlib import Path
import argparse
import os
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('--quick', action='store_true')
parser.add_argument('--feedback', action='store_true', help='Review correct, early, late, wrong and missed input indicators')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
out = root / ('build/combo-trials-feedback' if args.feedback else 'build/combo-trials')
out.mkdir(parents=True, exist_ok=True)
env = os.environ.copy()
native = Path(env.get('FIGHT_TOOLS', '/workspace/.fight-guild-tools')) / 'native-tools/usr'
env['LD_LIBRARY_PATH'] = str(native / 'lib/x86_64-linux-gnu') + ':' + env.get('LD_LIBRARY_PATH', '')
env.update(DISPLAY=':96', LIBGL_ALWAYS_SOFTWARE='1', LP_NUM_THREADS='2')
with (out / 'display.log').open('w') as log:
    display = subprocess.Popen([str(native / 'bin/Xvfb'), ':96', '-screen', '0', '1280x720x24', '-nolisten', 'tcp'], env=env, stdout=log, stderr=subprocess.STDOUT)
    try:
        for _ in range(50):
            if display.poll() is not None:
                raise RuntimeError('Native review display failed')
            if Path('/tmp/.X11-unix/X96').exists():
                break
            time.sleep(.1)
        cmd = ['bash', 'scripts/godot.sh', '--verbose', '--display-driver', 'x11', '--rendering-method', 'gl_compatibility', '--resolution', '1280x720']
        if not args.quick:
            cmd += ['--fixed-fps', '60', '--write-movie', str(out / 'review.avi')]
        else:
            cmd += ['--audio-driver', 'Dummy']
        review = 'res://tests/combo_trials_feedback_review.gd' if args.feedback else 'res://tests/combo_trials_review.gd'
        cmd += ['--script', review, '--', '--test', '--output', str(out)]
        if args.quick:
            cmd += ['--quick']
        with (out / 'godot.log').open('w') as game_log:
            subprocess.run(cmd, cwd=root, env=env, stdout=game_log, stderr=subprocess.STDOUT, check=True, timeout=420)
        report = (out / 'godot.log').read_text()
        if 'ERROR:' in report or 'Native rhythm review: 0 failures' not in report:
            raise RuntimeError(f'Trial review failed; see {out / "godot.log"}')
    finally:
        display.terminate()
        display.wait(timeout=10)
if not args.quick:
    target = root / ('exports/FightGuild-Trial-Feedback-2026-11-26.mp4' if args.feedback else 'exports/FightGuild-Combo-Trials-2026-11-26.mp4')
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', str(out / 'review.avi'), '-c:v', 'libx264', '-crf', '18',
                    '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-b:a', '160k', '-movflags', '+faststart', str(target)], check=True)
    print(target)
else:
    print(out)
