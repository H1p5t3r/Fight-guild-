#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
python scripts/generate-combat-data.py --check
python tests/combat_data_test.py
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/feedback_test.cpp -o build/feedback-tests
./build/feedback-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/grab_timing_test.cpp -o build/grab-timing-tests
./build/grab-timing-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/combo_endings_test.cpp -o build/combo-endings-tests
./build/combo-endings-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/mechanics_test.cpp -o build/mechanics-tests
./build/mechanics-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/movement_projectile_test.cpp -o build/movement-projectile-tests
./build/movement-projectile-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/core_test.cpp -o build/core-tests
./build/core-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/collision_test.cpp -o build/collision-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/recovery_test.cpp -o build/recovery-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/signature_test.cpp -o build/signature-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/tuning_test.cpp -o build/tuning-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/counter_test.cpp -o build/counter-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/wall_test.cpp -o build/wall-tests
./build/collision-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/hit_timeline_test.cpp -o build/hit-timeline-tests
./build/hit-timeline-tests
./build/recovery-tests
./build/signature-tests
./build/tuning-tests
./build/counter-tests
./build/wall-tests
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/tapper_test.cpp -o build/tapper-tests
./build/tapper-tests
./build/core-tests --trace > build/native.trace
python tests/run_godot_tests.py
bash scripts/audit-native-combat.sh
python tests/godot_network.py
