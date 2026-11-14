#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build web/generated
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/core_test.cpp -o build/core-tests
if command -v zig >/dev/null 2>&1; then
  fight_zig="$(command -v zig)"
else
  fight_zig="${FIGHT_TOOLS:-/workspace/.fight-guild-tools}/python/ziglang/zig"
fi
if [[ ! -x "$fight_zig" ]]; then
  echo 'Zig 0.14.1 is required. Run: bash scripts/setup.sh' >&2
  exit 1
fi
export ZIG_GLOBAL_CACHE_DIR="${FIGHT_TOOLS:-/workspace/.fight-guild-tools}/zig-cache"
export ZIG_LOCAL_CACHE_DIR="$PWD/build/zig-cache"
"$fight_zig" c++ -target wasm32-freestanding -std=c++17 -O2 -nostdlib \
  -fno-exceptions -fno-rtti -Wl,--no-entry -rdynamic \
  -Wl,-z,stack-size=65536 -Wl,--initial-memory=262144 -Wl,--max-memory=262144 \
  core/fight.cpp -o web/generated/fight.wasm
echo 'Built native tests and web/generated/fight.wasm'
