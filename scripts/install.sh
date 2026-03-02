#!/bin/bash
# ABNT Model - Native Installer
# Installs ABNT model into an existing SpecCompiler installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ABNT_DIR="$(dirname "$SCRIPT_DIR")"

# Find SPECCOMPILER_HOME
# Strategy: locate speccompiler-core (the real binary), then derive the repo root.
# speccompiler-core lives at <repo>/dist/bin/speccompiler-core, so:
#   SPECCOMPILER_DIST = <repo>/dist  (parent of bin/)
#   SPECCOMPILER_HOME = <repo>       (parent of dist/)
if [ -z "$SPECCOMPILER_HOME" ]; then
    SC_CORE=""

    # 1. speccompiler-core directly in PATH
    if command -v speccompiler-core &> /dev/null; then
        SC_CORE="$(readlink -f "$(which speccompiler-core)")"

    # 2. Parse the specc wrapper to extract the speccompiler-core path
    elif command -v specc &> /dev/null; then
        SPECC_PATH="$(readlink -f "$(which specc)")"
        SC_CORE="$(grep -oP 'exec\s+"\K[^"]+speccompiler-core' "$SPECC_PATH" 2>/dev/null || true)"
        if [ -n "$SC_CORE" ]; then
            SC_CORE="$(readlink -f "$SC_CORE")"
        fi
    fi

    if [ -z "$SC_CORE" ] || [ ! -x "$SC_CORE" ]; then
        echo "Error: SPECCOMPILER_HOME not set and speccompiler-core not found"
        echo ""
        echo "Either:"
        echo "  1. Install SpecCompiler first (bash scripts/build.sh --install)"
        echo "  2. Set SPECCOMPILER_HOME environment variable"
        exit 1
    fi

    # speccompiler-core is at <repo>/dist/bin/speccompiler-core
    SPECCOMPILER_HOME="$(dirname "$(dirname "$(dirname "$SC_CORE")")")"
fi

# Sanity check: verify this is a valid SpecCompiler installation
if [ ! -d "$SPECCOMPILER_HOME/src/core" ]; then
    echo "Error: $SPECCOMPILER_HOME does not appear to be a valid SpecCompiler installation"
    echo "  (no src/core/ found)"
    echo ""
    echo "Set SPECCOMPILER_HOME to the root of your SpecCompiler installation."
    exit 1
fi

echo "Installing ABNT model into: $SPECCOMPILER_HOME"

# Create models directory if needed
mkdir -p "$SPECCOMPILER_HOME/models"

# Create symlink to ABNT model
if [ -L "$SPECCOMPILER_HOME/models/abnt" ]; then
    rm "$SPECCOMPILER_HOME/models/abnt"
fi

ln -sf "$ABNT_DIR" "$SPECCOMPILER_HOME/models/abnt"

echo ""
echo "=== ABNT Model Installation Complete ==="
echo "Model installed at: $SPECCOMPILER_HOME/models/abnt"
echo ""
echo "Usage in project.yaml:"
echo "  template: abnt"
echo "  style: academico  # or: article, book, report"
