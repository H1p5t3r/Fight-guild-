#!/usr/bin/env bash
# The capture helper creates a private local virtual display.
set -euo pipefail
cd "$(dirname "$0")/.."
fight_film="${1:-$PWD/build/combo-showcase-current/film.json}"
export COMBO_OUTPUT="$(dirname "$fight_film")"
python scripts/capture-combo-showcase.py
node scripts/encode-combo-showcase.mjs "$fight_film"
