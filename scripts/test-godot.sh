#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/core_test.cpp -o build/core-tests
./build/core-tests
./build/core-tests --trace > build/native.trace
bash scripts/godot.sh --headless --editor --import
bash scripts/godot.sh --headless --script tests/core_bridge.gd -- "$PWD/build/native.trace"
bash scripts/godot.sh --headless --script tests/model_test.gd
bash scripts/godot.sh --headless --script tests/ui_smoke.gd -- --test
python tests/godot_network.py
