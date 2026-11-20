#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
fight_tools="${FIGHT_TOOLS:-/workspace/.fight-guild-tools}"
if ! command -v zig >/dev/null 2>&1 && [[ ! -x "$fight_tools/python/ziglang/zig" ]]; then
  python -m pip install --disable-pip-version-check --target "$fight_tools/python" ziglang==0.14.1
fi
npm ci --cache "$fight_tools/npm-cache" --no-audit --no-fund
npm run build
npm test
