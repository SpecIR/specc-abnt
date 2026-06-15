# SpecCompiler ABNT Model
# Overlay of the abnt model onto the SpecCompiler core image (NBR 14724).
#
# The base image already carries pandoc, the SpecCompiler engine, and the
# external renderer binaries (deno, plantuml). This image adds the abnt model
# tree under /opt/speccompiler/models/abnt/ — including the model-owned chart
# capability (CHART float + tools/echarts-render.ts) — and pre-warms the deno
# cache so charts render offline at runtime.

ARG BASE_IMAGE=ghcr.io/specir/speccompiler:latest
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.source="https://github.com/SpecIR/specc-abnt"
LABEL org.opencontainers.image.description="SpecCompiler ABNT model"
LABEL org.opencontainers.image.licenses="Apache-2.0"

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
    DENO_NO_UPDATE_CHECK=1
RUN deno cache /opt/speccompiler/models/abnt/tools/echarts-render.ts \
 && chmod -R a+rwX /opt/speccompiler/vendor/deno_cache

# Default working directory for user projects
WORKDIR /workspace
