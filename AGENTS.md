# AGENTS.md

## Project Overview

This repository builds a Docker image for a tool called **cloud-ops-builder**. The image is designed for cloud operations automation and deployment workflows, with a focus on multi-architecture support and modern cloud tooling.

## Architecture & Key Components

- **Dockerfile**: The central artifact. Builds a Debian-based image with:
  - Node.js v24 (via nvm, manual install for multi-arch precision)
  - AWS CLI v2
  - kubectl (latest stable)
  - Helm (latest)
  - `uv` Python tool (from Astral's image, with Python 3.12 installed and symlinked)
  - System tools: git, curl, make, xz-utils, unzip, ca-certificates
- **No application code**: This repo is infrastructure/tooling only. No app source or business logic is present.
- **Entrypoint**: Not defined in Dockerfile; image consumers are expected to provide commands at runtime.

## Build & CI/CD Workflows

- **GitHub Actions** (`.github/workflows/workflow.yml`):
  - Triggers: pushes to `main`, tags starting with `v`, PRs to `main`, manual dispatch
  - Builds and (on version tags) pushes multi-arch Docker images to GitHub Container Registry (GHCR)
  - Uses Docker Buildx for cross-arch builds
  - Image tags: `latest` (on default branch), branch/tag/sha-based tags
  - Only pushes images to GHCR on version tags (refs/tags/v*)

## Developer Workflows

- **Build locally**: `docker build -t cloud-ops-builder .`
- **Test image**: `docker run --rm -it cloud-ops-builder bash`
- **Release**: Tag a commit with `v*` (e.g., `v1.0.0`) and push; CI will build and push to GHCR
- **No local test suite**: There are no tests or app code to run

## Project Conventions & Patterns

- **Multi-arch support**: All tooling is installed with cross-architecture compatibility in mind
- **Minimal base image**: Uses `debian:bookworm-slim` for a small, secure footprint
- **Manual installs**: Node.js and some tools are installed manually for version/arch control
- **No project-specific code patterns**: This repo is for image/tooling only

## Integration Points

- **External dependencies**: AWS CLI, kubectl, Helm, Node.js, Python (via uv)
- **Image consumers**: Downstream users are expected to mount code or provide commands at runtime
- **No internal services or APIs**: This repo does not define or expose any services

## Key Files

- `Dockerfile`: All build logic and tool installation
- `.github/workflows/workflow.yml`: CI/CD pipeline for building and publishing the image
- `README.md`: Minimal project description

## Example Usage

```sh
# Build the image locally
$ docker build -t cloud-ops-builder .

# Run the image interactively
$ docker run --rm -it cloud-ops-builder bash
```

---

For more, see the Dockerfile and workflow YAML for exact tool versions and build steps.
