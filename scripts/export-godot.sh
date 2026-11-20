#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Build native libraries first. Export templates can be installed with install-godot.sh --templates.
fight_target="${1:-all}"
mkdir -p build/godot-linux build/godot-windows
export FIGHT_EXPORT_TARGET="$fight_target"
python - <<'PY'
import os, pathlib, subprocess, sys
target = os.environ['FIGHT_EXPORT_TARGET']
if target not in ('all', 'Linux', 'Windows'):
    sys.exit('Choose all, Linux, or Windows.')
for name in (['Linux', 'Windows'] if target == 'all' else [target]):
    extension = 'linux.template_release.x86_64.so' if name == 'Linux' else 'windows.template_release.x86_64.dll'
    if not pathlib.Path('godot/bin/libfight_core.' + extension).exists():
        sys.exit('Build the ' + name + ' native extension before exporting.')
    result = subprocess.run(['bash', 'scripts/godot.sh', '--headless', '--export-release', name],
                            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
    if result.returncode or 'ERROR:' in result.stdout:
        print(result.stdout)
        sys.exit(1)
    print('Exported ' + name)
PY
python scripts/package-godot.py "$fight_target"
