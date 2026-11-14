"""Run the Linux release PCK from outside the project, so source resources cannot hide missing exports."""
from pathlib import Path
import os
import subprocess
import tempfile
import zipfile

root = Path(__file__).resolve().parents[1]
tools = Path(os.environ.get('FIGHT_TOOLS', '/workspace/.fight-guild-tools'))
environment = dict(os.environ)
for key, directory in [('XDG_CACHE_HOME', 'cache'), ('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config')]:
    environment.setdefault(key, str(tools / directory))
with tempfile.TemporaryDirectory(prefix='fight-guild-export-') as cwd:
    with zipfile.ZipFile(root / 'build/FightGuild-Linux.zip') as archive:
        archive.extractall(cwd)
    executable = Path(cwd) / 'FightGuild/FightGuild.x86_64'
    executable.chmod(0o755)
    result = subprocess.run([str(executable), '--headless', '--', '--test', '--verify-build', '--review', '--block-review'], cwd=cwd, env=environment,
                            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=90)
print(result.stdout, end='')
assert result.returncode == 0 and 'ERROR:' not in result.stdout and '0 failures' in result.stdout, 'Packaged gameplay smoke test failed'
print('PASS exported Linux game, Momentum/FD, six fighters and guard-break sprite review')
