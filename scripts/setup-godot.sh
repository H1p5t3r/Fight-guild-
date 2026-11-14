#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
fight_tools="${FIGHT_TOOLS:-/workspace/.fight-guild-tools}"
fight_bindings_commit=e83fd0904c13356ed1d4c3d09f8bb9132bdc6b77
if ! PYTHONPATH="$fight_tools/python${PYTHONPATH:+:$PYTHONPATH}" python -c 'import SCons' 2>/dev/null; then
  python -m pip install --disable-pip-version-check --target "$fight_tools/python" scons==4.9.1
fi
if [[ ! -d "$fight_tools/godot-cpp/.git" ]]; then
  git clone --depth 1 --branch godot-4.5-stable https://github.com/godotengine/godot-cpp.git "$fight_tools/godot-cpp"
fi
if [[ "$(git -C "$fight_tools/godot-cpp" rev-parse HEAD)" != "$fight_bindings_commit" ]]; then
  echo 'godot-cpp checkout differs from the pinned revision; preserve it and use a separate FIGHT_TOOLS directory.' >&2
  exit 1
fi
bash scripts/build-godot.sh
bash scripts/test-godot.sh
