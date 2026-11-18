"""Package the static editor folder; no server, executable or install required."""
from pathlib import Path
import zipfile

root = Path(__file__).resolve().parents[1]
folder = root / 'build/move-workshop'
output = root / 'build/FightGuild-Move-Workshop.zip'
with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
    for file in sorted(folder.rglob('*')):
        if file.is_file():
            archive.write(file, 'FightGuild-Move-Workshop/' + file.relative_to(folder).as_posix())
print(f'Portable editor ZIP: {output.stat().st_size / 1024**2:.1f} MiB')
