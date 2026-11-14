#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/core_test.cpp -o build/core-tests
./build/core-tests
./build/core-tests --trace > build/native.trace
python tests/run_godot_tests.py
python tests/godot_network.py
