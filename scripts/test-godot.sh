#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
python scripts/generate-combat-data.py --check
python tests/combat_data_test.py
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/core_test.cpp -o build/core-tests
./build/core-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/collision_test.cpp -o build/collision-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/recovery_test.cpp -o build/recovery-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/signature_test.cpp -o build/signature-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/tuning_test.cpp -o build/tuning-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/counter_test.cpp -o build/counter-tests
./build/collision-tests
./build/recovery-tests
./build/signature-tests
./build/tuning-tests
./build/counter-tests
./build/core-tests --trace > build/native.trace
python tests/run_godot_tests.py
python tests/godot_network.py
