#!/bin/bash
# ABNT Model - Native Installer
# Installs ABNT model into an existing SpecCompiler installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ABNT_DIR="$(dirname "$SCRIPT_DIR")"

# Find SPECCOMPILER_HOME
if [ -z "$SPECCOMPILER_HOME" ]; then
    if command -v speccompiler-core &> /dev/null; then
        SC_BIN="$(which speccompiler-core)"
        SC_BIN_REAL="$(readlink -f "$SC_BIN")"
        SPECCOMPILER_HOME="$(dirname "$(dirname "$SC_BIN_REAL")")"
    elif command -v specc &> /dev/null; then
        SC_BIN="$(which specc)"
        SC_BIN_REAL="$(readlink -f "$SC_BIN")"
        SPECCOMPILER_HOME="$(dirname "$(dirname "$SC_BIN_REAL")")"
    else
        echo "Error: SPECCOMPILER_HOME not set and speccompiler-core not found in PATH"
        echo ""
        echo "Either:"
        echo "  1. Install speccompiler-core first"
        echo "  2. Set SPECCOMPILER_HOME environment variable"
        exit 1
    fi
fi

# Sanity check: verify this is a valid SpecCompiler installation
if [ ! -f "$SPECCOMPILER_HOME/bin/speccompiler-core" ] && [ ! -d "$SPECCOMPILER_HOME/src/core" ]; then
    echo "Error: $SPECCOMPILER_HOME does not appear to be a valid SpecCompiler installation"
    echo "  (no bin/speccompiler-core or src/core/ found)"
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
