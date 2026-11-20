#!/usr/bin/env bash
# Run on a desktop / virtual display with the current Godot extension imported.
set -euo pipefail
cd "$(dirname "$0")/.."
fight_film="${1:-$PWD/build/combo-showcase/film.json}"
fight_output="$PWD/build/combo-showcase"
mkdir -p "$fight_output/stills" exports
LP_NUM_THREADS="${LP_NUM_THREADS:-2}" bash scripts/godot.sh --resolution 1280x720 --rendering-driver opengl3 --audio-driver Dummy \
  --write-movie "$fight_output/showcase.avi" --fixed-fps 60 \
  --script res://tests/combo_showcase.gd -- \
  --film "$fight_film" --single-pass --captures "$fight_output/stills" --chapters "$fight_output/chapters.json"
node scripts/encode-combo-showcase.mjs "$fight_film"
