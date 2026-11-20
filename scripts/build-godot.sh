#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
fight_tools="${FIGHT_TOOLS:-/workspace/.fight-guild-tools}"
export PYTHONPATH="$fight_tools/python${PYTHONPATH:+:$PYTHONPATH}"
export GODOT_CPP="${GODOT_CPP:-$fight_tools/godot-cpp}"
mkdir -p godot/bin build
python -m SCons -C native platform=linux target=template_debug arch=x86_64 \
  build_profile="$PWD/native/build_profile.json" -j"${BUILD_JOBS:-4}" "$@"
