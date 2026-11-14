#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
fight_tools="${FIGHT_TOOLS:-/workspace/.fight-guild-tools}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$fight_tools/cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$fight_tools/data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$fight_tools/config}"
mkdir -p "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
exec godot --path godot "$@"
