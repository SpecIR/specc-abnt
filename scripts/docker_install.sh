#!/bin/bash
# ABNT Model - Docker Installer
# Builds a Docker image with ABNT model included and registers it

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ABNT_DIR="$(dirname "$SCRIPT_DIR")"

VARIANT="${SPECCOMPILER_ABNT_VARIANT:-slim}"
INSTALL_LIBREOFFICE="${SPECCOMPILER_ABNT_INSTALL_LIBREOFFICE:-false}"
IMAGE_NAME="${SPECCOMPILER_ABNT_IMAGE:-}"
BASE_IMAGE="${SPECCOMPILER_BASE_IMAGE:-speccompiler-core:latest}"

usage() {
    cat <<'USAGE'
Usage: bash scripts/docker_install.sh [--slim|--with-libreoffice] [--image IMAGE]

Builds and registers a local SpecCompiler ABNT Docker image.

Options:
  --slim              Build the default slim image without LibreOffice.
  --with-libreoffice  Install LibreOffice/python3-uno for field-updated DOCX output.
  --image IMAGE       Output Docker image tag.
USAGE
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --slim)
            VARIANT="slim"
            INSTALL_LIBREOFFICE="false"
            ;;
        --with-libreoffice|--libreoffice|--lo)
            VARIANT="libreoffice"
            INSTALL_LIBREOFFICE="true"
            ;;
        --image)
            shift
            IMAGE_NAME="${1:-}"
            if [ -z "$IMAGE_NAME" ]; then
                echo "Error: --image requires a value" >&2
                exit 2
            fi
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

if [ -z "$IMAGE_NAME" ]; then
    if [ "$VARIANT" = "libreoffice" ]; then
        IMAGE_NAME="speccompiler-abnt:libreoffice"
    else
        IMAGE_NAME="speccompiler-abnt:latest"
    fi
fi

echo "Building ABNT Docker image..."
echo "  Base image: $BASE_IMAGE"
echo "  Output image: $IMAGE_NAME"
echo "  Variant: $VARIANT"

# Build the image using the Dockerfile in the repo
docker build \
    -t "$IMAGE_NAME" \
    --build-arg "BASE_IMAGE=$BASE_IMAGE" \
    --build-arg "INSTALL_LIBREOFFICE=$INSTALL_LIBREOFFICE" \
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
if [ "$INSTALL_LIBREOFFICE" = "true" ]; then
    echo "To update DOCX fields in place, set docx.update_fields: true."
    echo "To export a PDF after the LibreOffice update pass, set docx.export_pdf: true."
fi
echo ""
echo "Usage:"
echo "  docker run --rm -v \$(pwd):/workspace $IMAGE_NAME /opt/speccompiler/bin/speccompiler-core project.yaml"
