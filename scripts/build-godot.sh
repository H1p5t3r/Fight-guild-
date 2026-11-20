#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
fight_tools="${FIGHT_TOOLS:-/workspace/.fight-guild-tools}"
export PYTHONPATH="$fight_tools/python${PYTHONPATH:+:$PYTHONPATH}"
export GODOT_CPP="${GODOT_CPP:-$fight_tools/godot-cpp}"
mkdir -p godot/bin build
python -m SCons -C native platform=linux target=template_debug arch=x86_64 \
  build_profile="$PWD/native/build_profile.json" -j"${BUILD_JOBS:-4}" "$@"

# Source ZIPs ship Windows DLLs. Record the exact inputs after each successful
# build so checks reject an old DLL paired with newer scripts or combat data.
fight_platform=linux
fight_build_target=template_debug
fight_record=1
for fight_arg in "$@"; do
  case "$fight_arg" in
    platform=*) fight_platform="${fight_arg#platform=}" ;;
    target=*) fight_build_target="${fight_arg#target=}" ;;
    -n|--dry-run|--no-exec|-c|--clean|-q|--question|-h|--help|-H) fight_record=0 ;;
  esac
done
if [[ "$fight_platform" == windows && "$fight_record" == 1 ]]; then
  python scripts/windows-core.py record --target "$fight_build_target"
fi
