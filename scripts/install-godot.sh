#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
fight_tools="${FIGHT_TOOLS:-/workspace/.fight-guild-tools}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$fight_tools/cache}"
mkdir -p "$XDG_CACHE_HOME"
fight_version=4.6.3
fight_downloads="$fight_tools/downloads"
mkdir -p "$fight_downloads" "$fight_tools/godot"
if [[ ! -x "$fight_tools/godot/godot" ]] && ! { command -v godot >/dev/null && [[ "$(godot --version)" == "$fight_version.stable"* ]]; }; then
  fight_archive="Godot_v${fight_version}-stable_linux.x86_64.zip"
  [[ -f "$fight_downloads/$fight_archive" ]] || curl -fL --retry 3 "https://github.com/godotengine/godot-builds/releases/download/$fight_version-stable/$fight_archive" -o "$fight_downloads/$fight_archive"
  printf '%s  %s\n' a035258da32b77f966a5376f9fa29c30a6adde826a85ba918e1605bd1fc9823eba7d85f1dd5e748956bd2ba72827c0025ffa11bb82aec91128c407a2e723c99c "$fight_downloads/$fight_archive" | sha512sum --check
  python - "$fight_downloads/$fight_archive" "$fight_tools/godot" <<'PY'
import pathlib, sys, zipfile
target = pathlib.Path(sys.argv[2]) / 'godot'
with zipfile.ZipFile(sys.argv[1]) as archive:
    target.write_bytes(archive.read('Godot_v4.6.3-stable_linux.x86_64'))
target.chmod(0o755)
PY
fi
if [[ "${1:-}" == --templates ]]; then
  fight_archive="Godot_v${fight_version}-stable_export_templates.tpz"
  [[ -f "$fight_downloads/$fight_archive" ]] || curl -fL --retry 3 "https://github.com/godotengine/godot-builds/releases/download/$fight_version-stable/$fight_archive" -o "$fight_downloads/$fight_archive"
  printf '%s  %s\n' da606b61c10157844f8300172df374472665f95015495cb1a7cd132c40ede404faa96cc1016a4b9662db9909ddea69632c4948b2cd11163438dad4808881fb68 "$fight_downloads/$fight_archive" | sha512sum --check
  python - "$fight_downloads/$fight_archive" "${XDG_DATA_HOME:-$fight_tools/data}/godot/export_templates/$fight_version.stable" <<'PY'
import pathlib, sys, zipfile
target = pathlib.Path(sys.argv[2])
target.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(sys.argv[1]) as archive:
    for name in ('linux_debug.x86_64', 'linux_release.x86_64', 'windows_debug_x86_64.exe', 'windows_release_x86_64.exe'):
        output = target / name
        output.write_bytes(archive.read('templates/' + name))
        output.chmod(0o755)
PY
fi
