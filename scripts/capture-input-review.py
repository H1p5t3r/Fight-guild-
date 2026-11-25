#!/usr/bin/env python3
"""Capture the native control settings and local side selector at 720p."""
from pathlib import Path
import os
import shutil
import subprocess
import time

root = Path(__file__).resolve().parents[1]
output = root / 'build/input-review'
output.mkdir(parents=True, exist_ok=True)
native = Path(os.environ.get('FIGHT_TOOLS', '/workspace/.fight-guild-tools')) / 'native-tools/usr'
env = os.environ.copy()
env['LD_LIBRARY_PATH'] = str(native / 'lib/x86_64-linux-gnu') + ':' + env.get('LD_LIBRARY_PATH', '')
env['DISPLAY'] = ':98'
env['LIBGL_ALWAYS_SOFTWARE'] = '1'
env['LP_NUM_THREADS'] = '2'
with (output / 'display.log').open('w') as display_log:
    display = subprocess.Popen([str(native / 'bin/Xvfb'), ':98', '-screen', '0', '1280x720x24', '-nolisten', 'tcp'],
                               env=env, stdout=display_log, stderr=subprocess.STDOUT)
    try:
        for _ in range(50):
            if display.poll() is not None:
                raise RuntimeError('Display failed; see build/input-review/display.log')
            if Path('/tmp/.X11-unix/X98').exists():
                break
            time.sleep(.1)
        with (output / 'godot.log').open('w') as game_log:
            subprocess.run(['bash', 'scripts/godot.sh', '--display-driver', 'x11', '--audio-driver', 'Dummy',
                            '--resolution', '1280x720', '--script', 'tests/input_menu_test.gd', '--',
                            '--test', '--screenshots'], cwd=root, env=env, stdout=game_log,
                           stderr=subprocess.STDOUT, timeout=120, check=True)
        report = (output / 'godot.log').read_text()
        if 'ERROR:' in report or 'Native controls and side-select menus: 0 failures' not in report:
            raise RuntimeError('Native review failed; see build/input-review/godot.log')
    finally:
        display.terminate()
        display.wait(timeout=10)
for source, name in [('fg-side-select.png', 'FightGuild-Side-Select.png'), ('fg-control-settings.png', 'FightGuild-Controls.png')]:
    shutil.copyfile(Path('/tmp') / source, root / 'exports' / name)
print('Native 720p review saved to exports/FightGuild-Side-Select.png and exports/FightGuild-Controls.png')
