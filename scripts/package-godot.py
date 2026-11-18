"""Package native builds and an editable Godot project; never include caches or user saves."""
from pathlib import Path
import hashlib
import sys
import subprocess
import zipfile

root = Path(__file__).resolve().parents[1]
target = sys.argv[1] if len(sys.argv) > 1 else 'all'
notices = list((root / 'licenses').glob('*'))
packages = []
for platform in (['Linux', 'Windows'] if target == 'all' else [target]):
    source = root / 'build' / ('godot-' + platform.lower())
    output = root / 'build' / ('FightGuild-' + platform + '.zip')
    files = ['FightGuild.pck', 'FightGuild.x86_64', 'libfight_core.linux.template_release.x86_64.so'] if platform == 'Linux' else ['FightGuild.pck', 'FightGuild.exe', 'libfight_core.windows.template_release.x86_64.dll']
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
        for name in files:
            archive.write(source / name, 'FightGuild/' + name)
        archive.write(root / 'docs/play-native.md', 'FightGuild/START-HERE.md')
        archive.write(root / 'docs/momentum-defense.md', 'FightGuild/momentum-defense.md')
        archive.write(root / 'docs/combat-feedback.md', 'FightGuild/combat-feedback.md')
        archive.write(root / 'docs/combat-tuning.md', 'FightGuild/combat-tuning.md')
        archive.write(root / 'docs/training-lab.md', 'FightGuild/training-lab.md')
        archive.write(root / 'docs/recovery-and-walls.md', 'FightGuild/recovery-and-walls.md')
        archive.write(root / 'docs/stage-art.md', 'FightGuild/stage-art.md')
        archive.write(root / 'docs/research/strive-camera-framing-2026-11-16.md', 'FightGuild/research/strive-camera-framing-2026-11-16.md')
        archive.write(root / 'docs/signature-moves.md', 'FightGuild/signature-moves.md')
        archive.write(root / 'docs/collision-rules.md', 'FightGuild/collision-rules.md')
        archive.write(root / 'docs/move-workshop.md', 'FightGuild/move-workshop.md')
        archive.write(root / 'docs/move-stats.md', 'FightGuild/move-stats.md')
        archive.write(root / 'docs/tapper-design.md', 'FightGuild/tapper-design.md')
        archive.write(root / 'docs/menu-flow.md', 'FightGuild/menu-flow.md')
        archive.write(root / 'docs/menu-style.md', 'FightGuild/menu-style.md')
        for file in notices: archive.write(file, 'FightGuild/licenses/' + file.name)
    packages.append(output)

output = root / 'build/FightGuild-Godot-project.zip'
with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
    for file in sorted((root / 'godot').rglob('*')):
        if file.is_file() and '.godot' not in file.parts:
            archive.write(file, 'FightGuild-Godot/godot/' + str(file.relative_to(root / 'godot')))
    for file in [root / 'README.md', *sorted((root / 'docs').rglob('*.md')), *notices]:
        archive.write(file, 'FightGuild-Godot/' + str(file.relative_to(root)))
    # Include editable core/build sources, excluding compiler intermediates and caches.
    paths = subprocess.check_output(['git', 'ls-files', '-z', 'core', 'native', 'scripts', 'tests', 'web', 'art/ui-stock', 'art/stages', 'references/menu-style', '.github', 'package.json', 'package-lock.json', '.gitignore'], cwd=root).decode().split('\0')
    for path in filter(None, paths):
        archive.write(root / path, 'FightGuild-Godot/' + path)
packages.append(output)
for file in packages:
    print(file.name, file.stat().st_size, 'bytes', hashlib.sha256(file.read_bytes()).hexdigest())
