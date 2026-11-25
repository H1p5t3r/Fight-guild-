#!/usr/bin/env python3
"""Record, verify and package the Windows GDExtension shipped with source ZIPs."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = 'godot/bin/windows-core.json'
TARGETS = ('template_debug', 'template_release')
INPUTS = (
    'core/fight.cpp', 'core/fight.h', 'core/combat_data.h', 'core/extensions.h',
    'core/extension_tables.inc', 'core/fillet_v1.inc', 'core/step_drive.inc', 'core/supers.inc', 'core/feedback.inc', 'native/fight_extension.cpp',
    'native/SConstruct', 'native/build_profile.json', 'godot/fight_core.gdextension',
)

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def library(target):
    return f'godot/bin/libfight_core.windows.{target}.x86_64.dll'

def sources(root):
    return {name: sha(root / name) for name in INPUTS}

def core_version(root):
    return int(re.search(r'constexpr int VERSION = (\d+)', (root / 'core/fight.h').read_text()).group(1))

def check_pe(path):
    data = path.read_bytes()
    if len(data) < 64 or data[:2] != b'MZ':
        raise ValueError(f'{path.name} is not a Windows DLL.')
    offset = struct.unpack_from('<I', data, 0x3c)[0]
    if offset + 24 > len(data) or data[offset:offset+4] != b'PE\0\0' or struct.unpack_from('<H', data, offset + 4)[0] != 0x8664:
        raise ValueError(f'{path.name} is not a Windows x86-64 DLL.')
    if not struct.unpack_from('<H', data, offset + 22)[0] & 0x2000:
        raise ValueError(f'{path.name} is a Windows executable, not a DLL.')

def record(root, target):
    """Called by build-godot.sh only after SCons succeeds for this target."""
    path = root / library(target)
    check_pe(path)
    manifest = json.loads((root / MANIFEST).read_text()) if (root / MANIFEST).exists() else {'format': 1, 'libraries': {}}
    bindings = os.environ.get('GODOT_CPP')
    if not bindings:
        raise ValueError('GODOT_CPP must identify the bindings used for this build.')
    revision = subprocess.check_output(['git', '-C', bindings, 'rev-parse', 'HEAD'], text=True).strip()
    manifest['libraries'][target] = {'file': library(target), 'sha256': sha(path), 'coreVersion': core_version(root), 'godotCppRevision': revision, 'sourceSha256': sources(root)}
    (root / MANIFEST).write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'Recorded Windows {target}, combat core {core_version(root)}.')

def verify(root):
    try:
        manifest = json.loads((root / MANIFEST).read_text())
    except FileNotFoundError as error:
        raise ValueError('Missing Windows build record. Build both Windows targets first.') from error
    expected = sources(root)
    bindings = re.search(r'fight_bindings_commit=([a-f0-9]+)', (root / 'scripts/setup-godot.sh').read_text()).group(1)
    if manifest.get('format') != 1 or set(manifest.get('libraries', {})) != set(TARGETS):
        raise ValueError('Unsupported Windows build record.')
    for target in TARGETS:
        entry = manifest.get('libraries', {}).get(target, {})
        path = root / library(target)
        if not path.exists():
            raise ValueError(f'Missing {path.name}. Rebuild Windows {target}.')
        check_pe(path)
        if entry.get('file') != library(target) or entry.get('sha256') != sha(path):
            raise ValueError(f'{path.name} does not match its build record. Rebuild it.')
        if entry.get('sourceSha256') != expected or entry.get('coreVersion') != core_version(root) or entry.get('godotCppRevision') != bindings:
            raise ValueError(f'{path.name} is stale. Rebuild Windows {target} after changing core/native inputs, then commit the DLLs and windows-core.json together.')
    return manifest

def package(root, output):
    manifest = verify(root)
    output.parent.mkdir(parents=True, exist_ok=True)
    instructions = '''Fight Guild — Windows editor repair

1. Close Godot completely.
2. Find the folder containing project.godot (normally the repository's godot folder).
3. Extract this ZIP INTO that folder. Merge bin and replace the two matching DLLs.
   Correct: <folder containing project.godot>/bin/libfight_core.windows.template_debug.x86_64.dll
   Avoid: <folder containing project.godot>/godot/bin or an extra nested repair folder.
4. Reopen project.godot with 64-bit Godot. Our tested editor version is 4.6.3.
5. Press F5. If the error persists, check Godot's Output tab for the FIRST GDExtension loading error.

This package contains combat core VERSION. Use it with matching source files.
Source ZIPs from the updated feat/godot-combat-lab branch already include these DLLs.
It does not overwrite moves.json, art, saves, or project.godot.
'''.replace('core VERSION', f'core {core_version(root)}')
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
        for entry in manifest['libraries'].values():
            archive.write(root / entry['file'], 'bin/' + Path(entry['file']).name)
        archive.write(root / MANIFEST, 'bin/windows-core.json')
        archive.writestr('WINDOWS-CORE-START-HERE.txt', instructions)
        for name in ('godot-cpp-LICENSE.md', 'Godot-LICENSE.txt'):
            archive.write(root / 'licenses' / name, 'licenses/' + name)
    print(f'Packaged {output.name}: {output.stat().st_size:,} bytes, SHA-256 {sha(output)}')

def verify_archive(root, path):
    manifest = verify(root)
    with zipfile.ZipFile(path) as archive:
        if json.loads(archive.read('bin/windows-core.json')) != manifest:
            raise ValueError('Repair ZIP is stale. Repackage it with scripts/windows-core.py package --output exports/FightGuild-Windows-Core.zip.')
        for entry in manifest['libraries'].values():
            if hashlib.sha256(archive.read('bin/' + Path(entry['file']).name)).hexdigest() != entry['sha256']:
                raise ValueError('Repair ZIP contains a mismatched DLL. Repackage it.')

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=('record', 'check', 'package'))
    parser.add_argument('--target', choices=TARGETS)
    parser.add_argument('--archive', type=Path, help='Also verify this existing repair ZIP during check.')
    parser.add_argument('--output', type=Path, default=ROOT / 'build/FightGuild-Windows-Core.zip')
    args = parser.parse_args()
    try:
        if args.command == 'record':
            if not args.target: parser.error('record requires --target')
            record(ROOT, args.target)
        elif args.command == 'check':
            verify(ROOT)
            if args.archive: verify_archive(ROOT, args.archive)
            print(f'Windows debug/release DLLs match combat core {core_version(ROOT)} and all compiled source inputs.')
        else:
            package(ROOT, args.output)
    except (OSError, ValueError, KeyError, zipfile.BadZipFile) as error:
        parser.exit(1, str(error) + '\n')

if __name__ == '__main__':
    main()
