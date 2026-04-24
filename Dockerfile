# Use the official uv image as the base
ARG UV_IMAGE_TAG=0.11.7-python3.12-trixie-slim
FROM ghcr.io/astral-sh/uv:${UV_IMAGE_TAG}

LABEL org.opencontainers.image.source="https://github.com/kimbeejay/uv-make"
LABEL org.opencontainers.image.description="Python image with uv and make installed for building projects using uv and make."
LABEL org.opencontainers.image.licenses="Apache-2.0"

# Install make and clean up to keep the image slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
