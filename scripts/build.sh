#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build web/generated
# Runtime tests retain several independent configuration tables on the stack.
python scripts/generate-combat-data.py --check
python tests/combat_data_test.py
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/combo_physics_test.cpp -o build/combo-physics-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/movement_projectile_test.cpp -o build/movement-projectile-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/fillet_v1_test.cpp -o build/fillet-v1-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/fillet_geometry_test.cpp -o build/fillet-geometry-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/core_test.cpp -o build/core-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/collision_test.cpp -o build/collision-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/hit_timeline_test.cpp -o build/hit-timeline-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/recovery_test.cpp -o build/recovery-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/signature_test.cpp -o build/signature-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/tuning_test.cpp -o build/tuning-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/counter_test.cpp -o build/counter-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/wall_test.cpp -o build/wall-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/mechanics_test.cpp -o build/mechanics-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/tapper_test.cpp -o build/tapper-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/smoke_test.cpp -o build/smoke-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/shark_drive_test.cpp -o build/shark-drive-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/hammer_drive_test.cpp -o build/hammer-drive-tests
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
  -Wl,-z,stack-size=65536 -Wl,--initial-memory=8388608 -Wl,--max-memory=8388608 \
  core/fight.cpp -o web/generated/fight.wasm
echo 'Built native tests and web/generated/fight.wasm'
