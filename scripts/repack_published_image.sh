#!/usr/bin/env bash
# Repack an already-published specc-abnt image with the model from this checkout.
#
# This is intentionally local-only: it is not used by CI. The script pulls the
# current GHCR image, uses it as the Docker base image, removes the embedded ABNT
# model, copies this checkout's ABNT model into the image, and optionally pushes
# the rebuilt image back to the registry.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ABNT_DIR="$(dirname "$SCRIPT_DIR")"

DEFAULT_IMAGE="ghcr.io/specir/specc-abnt:latest"
SOURCE_IMAGE="${SPECC_ABNT_SOURCE_IMAGE:-$DEFAULT_IMAGE}"
OUTPUT_IMAGE="${SPECC_ABNT_OUTPUT_IMAGE:-}"
PLATFORM="${SPECC_ABNT_PLATFORM:-linux/amd64}"
PULL_IMAGE=true
PUSH_IMAGE=false

usage() {
    cat <<'USAGE'
Usage: bash scripts/repack_published_image.sh [options]

Pull an existing specc-abnt image, overwrite /opt/speccompiler/models/abnt
with the ABNT model from this checkout, rebuild the image locally, and
optionally push it back to the registry.

Options:
  --source-image IMAGE  Existing image to pull and use as the base image.
                        Default: ghcr.io/specir/specc-abnt:latest
  --output-image IMAGE  Tag for the rebuilt image.
                        Default: same as --source-image
  --variant TAG         Shortcut for ghcr.io/specir/specc-abnt:TAG.
                        Common values: latest, libreoffice
  --platform PLATFORM   Docker platform to pull/build. Default: linux/amd64.
  --no-pull             Use the local source image without pulling first.
  --push                Push the rebuilt output image after a successful build.
  -h, --help            Show this help.

Examples:
  bash scripts/repack_published_image.sh
  bash scripts/repack_published_image.sh --push
  bash scripts/repack_published_image.sh --variant libreoffice --push
  bash scripts/repack_published_image.sh \
    --source-image ghcr.io/specir/specc-abnt:latest \
    --output-image ghcr.io/specir/specc-abnt:local-test
USAGE
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --source-image)
            shift
            SOURCE_IMAGE="${1:-}"
            if [ -z "$SOURCE_IMAGE" ]; then
                echo "Error: --source-image requires a value" >&2
                exit 2
            fi
            ;;
        --output-image|--image|--tag)
            shift
            OUTPUT_IMAGE="${1:-}"
            if [ -z "$OUTPUT_IMAGE" ]; then
                echo "Error: --output-image requires a value" >&2
                exit 2
            fi
            ;;
        --variant)
            shift
            VARIANT="${1:-}"
            if [ -z "$VARIANT" ]; then
                echo "Error: --variant requires a value" >&2
                exit 2
            fi
            SOURCE_IMAGE="ghcr.io/specir/specc-abnt:$VARIANT"
            ;;
        --platform)
            shift
            PLATFORM="${1:-}"
            if [ -z "$PLATFORM" ]; then
                echo "Error: --platform requires a value" >&2
                exit 2
            fi
            ;;
        --no-pull)
            PULL_IMAGE=false
            ;;
        --push)
            PUSH_IMAGE=true
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

if [ -z "$OUTPUT_IMAGE" ]; then
    OUTPUT_IMAGE="$SOURCE_IMAGE"
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "Error: docker is required" >&2
    exit 1
fi

echo "Repacking specc-abnt image with local ABNT model..."
echo "  Source image: $SOURCE_IMAGE"
echo "  Output image: $OUTPUT_IMAGE"
echo "  Platform: $PLATFORM"
echo "  Push: $PUSH_IMAGE"
echo ""

if [ "$PULL_IMAGE" = true ]; then
    docker pull --platform "$PLATFORM" "$SOURCE_IMAGE"
fi

build_cmd=(
    docker build
    -f -
    --build-arg "SOURCE_IMAGE=$SOURCE_IMAGE"
    --platform "$PLATFORM"
    -t "$OUTPUT_IMAGE"
)

build_cmd+=("$ABNT_DIR")

"${build_cmd[@]}" <<'DOCKERFILE'
ARG SOURCE_IMAGE
FROM ${SOURCE_IMAGE}

USER root

RUN rm -rf /opt/speccompiler/models/abnt \
 && mkdir -p /opt/speccompiler/models/abnt

COPY types/          /opt/speccompiler/models/abnt/types/
COPY shared/         /opt/speccompiler/models/abnt/shared/
COPY filters/        /opt/speccompiler/models/abnt/filters/
COPY postprocessors/ /opt/speccompiler/models/abnt/postprocessors/
COPY styles/         /opt/speccompiler/models/abnt/styles/
COPY assets/         /opt/speccompiler/models/abnt/assets/
COPY tools/          /opt/speccompiler/models/abnt/tools/
COPY config.lua model.yaml /opt/speccompiler/models/abnt/
COPY tests/          /opt/speccompiler/models/abnt/tests/

RUN chmod -R a+rX /opt/speccompiler/models/abnt \
 && if command -v deno >/dev/null 2>&1; then \
      export DENO_DIR="${DENO_DIR:-/opt/speccompiler/vendor/deno_cache}"; \
      export DENO_NO_UPDATE_CHECK=1; \
      deno cache /opt/speccompiler/models/abnt/tools/echarts-render.ts \
      && chmod -R a+rwX "$DENO_DIR"; \
    fi
DOCKERFILE

if [ "$PUSH_IMAGE" = true ]; then
    docker push "$OUTPUT_IMAGE"
fi

echo ""
echo "=== Repacked specc-abnt Image ==="
echo "Image: $OUTPUT_IMAGE"
if [ "$PUSH_IMAGE" = true ]; then
    echo "Published: yes"
else
    echo "Published: no (--push was not set)"
fi
