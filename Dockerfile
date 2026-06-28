# SpecCompiler ABNT Model
# Overlay of the abnt model onto the SpecCompiler core image (NBR 14724).
#
# The base image already carries pandoc, the SpecCompiler engine, and the
# external renderer binaries (deno, plantuml). This image adds the abnt model
# tree under /opt/speccompiler/models/abnt/ — including the model-owned chart
# capability (CHART float + tools/echarts-render.ts) — and pre-warms the deno
# cache so charts render offline at runtime.

ARG BASE_IMAGE=ghcr.io/specir/speccompiler:latest
ARG INSTALL_LIBREOFFICE=false
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.source="https://github.com/SpecIR/specc-abnt"
LABEL org.opencontainers.image.description="SpecCompiler ABNT model"
LABEL org.opencontainers.image.licenses="Apache-2.0"

ARG INSTALL_LIBREOFFICE

USER root

RUN if [ "$INSTALL_LIBREOFFICE" = "true" ]; then \
      if command -v apt-get >/dev/null 2>&1; then \
        apt-get update \
        && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
          libreoffice-writer \
          libreoffice-math \
          python3-uno \
          poppler-utils \
          fonts-liberation \
        && rm -rf /var/lib/apt/lists/*; \
      elif command -v apk >/dev/null 2>&1; then \
        apk add --no-cache \
          libreoffice-writer \
          libreoffice-math \
          python3 \
          poppler-utils \
          font-liberation; \
      else \
        echo "No supported package manager found for LibreOffice installation" >&2; \
        exit 1; \
      fi; \
    fi

# The abnt model: descriptors (types/), shared helpers, filters,
# postprocessors, styles, assets, manifest, and the model test suite
# (runnable in-image via /opt/speccompiler/tests/run.sh abnt-tests).
COPY types/          /opt/speccompiler/models/abnt/types/
COPY shared/         /opt/speccompiler/models/abnt/shared/
COPY filters/        /opt/speccompiler/models/abnt/filters/
COPY postprocessors/ /opt/speccompiler/models/abnt/postprocessors/
COPY styles/         /opt/speccompiler/models/abnt/styles/
COPY assets/         /opt/speccompiler/models/abnt/assets/
COPY tools/          /opt/speccompiler/models/abnt/tools/
COPY config.lua model.yaml /opt/speccompiler/models/abnt/
COPY tests/          /opt/speccompiler/models/abnt/tests/

RUN chmod -R a+rX /opt/speccompiler/models/abnt/

# Pre-warm the deno cache for the chart renderer (imports npm:echarts at
# runtime). World-writable so CI containers running with --user can use it.
ENV DENO_DIR=/opt/speccompiler/vendor/deno_cache \
    DENO_NO_UPDATE_CHECK=1 \
    SAL_USE_VCLPLUGIN=headless
RUN deno cache /opt/speccompiler/models/abnt/tools/echarts-render.ts \
 && chmod -R a+rwX /opt/speccompiler/vendor/deno_cache

RUN printf '%s\n' \
      '#!/bin/sh' \
      'set -e' \
      'if command -v specc >/dev/null 2>&1; then exec specc "$@"; fi' \
      'if [ -x /opt/speccompiler/bin/speccompiler-core ]; then exec /opt/speccompiler/bin/speccompiler-core "$@"; fi' \
      'exec speccompiler-core "$@"' \
      > /usr/local/bin/specc-abnt-entrypoint \
 && chmod +x /usr/local/bin/specc-abnt-entrypoint

# Default working directory for user projects
WORKDIR /workspace
ENTRYPOINT ["specc-abnt-entrypoint"]
