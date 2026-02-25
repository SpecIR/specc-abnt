# SpecCompiler ABNT Model
# Builds on top of speccompiler-core with ABNT NBR 14724:2011 compliance

ARG BASE_IMAGE=ghcr.io/specir/speccompiler:latest
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.source="https://github.com/SpecIR/specc-abnt"
LABEL org.opencontainers.image.description="SpecCompiler ABNT model"
LABEL org.opencontainers.image.licenses="Apache-2.0"

# Switch to root for file operations (base image ends with USER speccompiler)
USER root

# Copy ABNT model into the models directory
COPY types/          /opt/speccompiler/models/abnt/types/
COPY filters/        /opt/speccompiler/models/abnt/filters/
COPY postprocessors/ /opt/speccompiler/models/abnt/postprocessors/
COPY styles/         /opt/speccompiler/models/abnt/styles/
COPY data_views/     /opt/speccompiler/models/abnt/data_views/
COPY config.lua      /opt/speccompiler/models/abnt/config.lua

# Ensure files are readable when running as non-root user
RUN chmod -R a+rX /opt/speccompiler/models/abnt/

# Switch back to non-root user
USER speccompiler

# Default working directory for user projects
WORKDIR /workspace
