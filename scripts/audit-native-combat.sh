#!/usr/bin/env bash
# Uses the current Godot Workshop import path. Does not build or publish the web editor.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/combat-spacing-audit
bash scripts/godot.sh --headless --script res://tests/export_spacing_fixture.gd -- "$PWD/build/combat-spacing-audit/configuration.bin"
"${CXX:-g++}" -std=c++17 -O2 -Wall -Wextra -Werror -pedantic core/fight.cpp tests/spacing_audit.cpp -o build/combat-spacing-audit/run
fight_audit_output=--checks-only
if [[ "${1:-}" == --full ]]; then fight_audit_output=build/combat-spacing-audit/contacts.csv; fi
build/combat-spacing-audit/run build/combat-spacing-audit/configuration.bin "$fight_audit_output"
