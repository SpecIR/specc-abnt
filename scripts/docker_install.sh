#!/bin/bash
# ABNT Model - Docker Installer
# Builds a Docker image with ABNT model included

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ABNT_DIR="$(dirname "$SCRIPT_DIR")"

IMAGE_NAME="${SPECCOMPILER_ABNT_IMAGE:-speccompiler-abnt:latest}"
BASE_IMAGE="${SPECCOMPILER_BASE_IMAGE:-speccompiler-core:latest}"

echo "Building ABNT Docker image..."
echo "  Base image: $BASE_IMAGE"
echo "  Output image: $IMAGE_NAME"

# Build the image using the Dockerfile in the repo
docker build \
    -t "$IMAGE_NAME" \
    --build-arg "BASE_IMAGE=$BASE_IMAGE" \
    "$ABNT_DIR"

# Persist image name so the specc wrapper uses this image
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/speccompiler"
mkdir -p "$CONFIG_DIR"
echo "SPECCOMPILER_IMAGE=\"$IMAGE_NAME\"" > "$CONFIG_DIR/env"

echo ""
echo "=== ABNT Docker Image Built ==="
echo "Image: $IMAGE_NAME"
echo "Wrote SPECCOMPILER_IMAGE to ~/.config/speccompiler/env"
echo ""
echo "The 'specc build' command will now use this image automatically."
echo ""
echo "Usage:"
echo "  docker run --rm -v \$(pwd):/workspace $IMAGE_NAME /opt/speccompiler/bin/speccompiler-core project.yaml"
