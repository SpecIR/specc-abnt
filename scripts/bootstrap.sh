#!/bin/bash
# abnt model — external dependency bootstrap.
#
# The abnt model owns its renderer (tools/echarts-render.ts) and its runtime
# dependency: deno. The engine core needs neither. This script provisions or
# verifies deno for NATIVE installs; the Docker `full` image already ships it.
#
# Usage:  bash models/abnt/scripts/bootstrap.sh [--install]
#   (no flag)  check only — exit 0 if charts can render, 1 otherwise
#   --install  install deno via the official installer if missing
set -e

if command -v deno >/dev/null 2>&1; then
    echo "charts: deno $(deno --version | head -1 | cut -d' ' -f2) found — chart rendering available."
    exit 0
fi

if [ "$1" = "--install" ]; then
    echo "charts: installing deno (official installer)..."
    curl -fsSL https://deno.land/install.sh | sh
    echo "charts: add \$HOME/.deno/bin to PATH, then re-run this script to verify."
    exit 0
fi

echo "charts: deno not found — chart floats will fail to render (loudly, at build time)." >&2
echo "Install it with:  bash models/abnt/scripts/bootstrap.sh --install" >&2
echo "or via your package manager (e.g. apk add deno)." >&2
exit 1
