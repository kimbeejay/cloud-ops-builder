# AGENTS.md

## Project Overview

This repository builds a Docker image for a tool called **cloud-ops-builder**. The image is designed for cloud operations automation and deployment workflows, with a focus on multi-architecture support and modern cloud tooling.

## Architecture & Key Components

- **Dockerfile**: The central artifact. Multi-stage build pattern that:
  - Uses `ghcr.io/astral-sh/uv:${UV_VERSION}` as the `uv-binaries` stage to extract uv and uvx binaries
  - Builds on `debian:bookworm-slim` with the extracted uv binaries
  - Installs tools in order: system tools → Node.js/nvm → AWS CLI → kubectl → Helm → uv/Python → Docker CLI → jq → databricks-cli → Terraform → docker-scout
  - Includes tooling:
    - Node.js v24 (via nvm, manual install for multi-arch precision; symlinked to `/usr/local/bin` for global access; Corepack + pnpm enabled)
    - AWS CLI v2
    - kubectl with SHA256 verification
    - Helm (installed via Helm's `get-helm-4` script)
    - `uv` Python tool (from Astral's multi-stage image, with Python 3.12 installed and symlinked)
    - Docker CLI (`docker-ce-cli`, includes `docker compose`)
    - docker-scout with SHA256 verification
    - jq with SHA256 verification
    - databricks-cli with SHA256 verification
    - Terraform with SHA256 verification
    - System tools: git, curl, make, xz-utils, unzip, ca-certificates, gnupg
  - Sets `ENV DEBIAN_FRONTEND=noninteractive` to prevent interactive prompts during build
  - Includes OCI image labels: `org.opencontainers.image.source`, `org.opencontainers.image.title`, `org.opencontainers.image.description`, `org.opencontainers.image.licenses`
- **No application code**: This repo is infrastructure/tooling only. No app source or business logic is present.
- **Entrypoint**: Not defined in Dockerfile; image consumers are expected to provide commands at runtime.

## Build & CI/CD Workflows

- **GitHub Actions** (`.github/workflows/workflow.yml`):
  - **Triggers**: Pushes to `main`, tags starting with `v` (e.g., `v1.0.0`), PRs to `main`, manual dispatch (`workflow_dispatch`)
  - **Build matrix**: Uses `docker/setup-qemu-action` and `docker/setup-buildx-action` to build multi-arch images (`linux/amd64`, `linux/arm64`)
  - **Registry**: Builds to GitHub Container Registry (GHCR) at `ghcr.io/${{ github.repository }}`
  - **Tagging strategy**: Via `docker/metadata-action`, generates tags based on branch/tag/commit:
    - `latest` (on `main` branch only, priority 10)
    - Branch names (e.g., `main`, priority 30)
    - Version tags (e.g., `v1.0.0`, priority 20)
    - Short commit SHA (priority 40)
  - **Push condition**: Only pushes to GHCR when building version tags (`startsWith(github.ref, 'refs/tags/v')`); PR and branch builds are local-only
  - **Image labels**: OCI metadata labels are automatically applied from Dockerfile `LABEL` instructions

## Developer Workflows

- **Build locally**: `docker build -t cloud-ops-builder .` (defaults to host architecture)
  - To override tool versions, pass build args: `docker build --build-arg UV_VERSION=0.12.0 --build-arg KUBECTL_VERSION=v1.37.0 -t cloud-ops-builder .`
  - Available build args to override: `UV_VERSION`, `PYTHON_VERSION`, `JQ_VERSION`, `PNPM_VERSION`, `NVM_VERSION`, `TF_VERSION`, `KUBECTL_VERSION`, `HELM_VERSION`, `SCOUT_VERSION`, `DATABRICKS_CLI_VERSION`
- **Test image**: `docker run --rm -it cloud-ops-builder bash`
- **Use Docker CLI inside container**: `docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock cloud-ops-builder bash` (mounts host Docker daemon)
- **Build multi-arch locally** (requires buildx setup): `docker buildx build --platform linux/amd64,linux/arm64 -t cloud-ops-builder .`
- **Release**: Tag a commit with `v*` (e.g., `v1.0.0`) and push; CI will build and push multi-arch images to GHCR
  - Use `git tag v1.0.0 && git push origin v1.0.0` to trigger the workflow
- **No local test suite**: There are no automated tests or app code to run; validation is via image build success and manual runtime testing

## Project Conventions & Patterns

- **Multi-arch support**: All tooling is installed with cross-architecture compatibility in mind (e.g., `${TARGETARCH}` variable used for binary downloads, `docker/setup-qemu-action` for build matrix)
- **Multi-stage Docker builds**: The Dockerfile uses a multi-stage pattern to efficiently copy uv binaries from the official Astral image: `FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv-binaries` followed by `COPY --from=uv-binaries /uv /uvx /bin/`
- **Global tool symlinks**: Node.js and related tools (node, npm, npx, corepack, pnpm) are symlinked into `/usr/local/bin` to ensure they're globally available and persist through shell environments
- **Minimal base image**: Uses `debian:bookworm-slim` for a small, secure footprint
- **Manual installs**: Node.js and some tools are installed manually for version/arch control, rather than relying on package managers
- **Version pinning in Dockerfile**: Tool versions are controlled via `ARG` declarations at the top: `UV_VERSION`, `PYTHON_VERSION`, `JQ_VERSION`, `PNPM_VERSION`, `NVM_VERSION`, `TF_VERSION`, `KUBECTL_VERSION`, `HELM_VERSION`, `SCOUT_VERSION`, `DATABRICKS_CLI_VERSION`
- **Docker ARG scope in multi-stage builds**: Args declared before `FROM` are re-declared after `FROM debian:bookworm-slim` when needed by `RUN` commands in that stage (e.g., `NVM_VERSION`, `PNPM_VERSION`, `TF_VERSION`, `TARGETARCH`)
- **Binary download verification**: Critical tools include SHA256 checksum verification before installation: `kubectl`, `jq`, `terraform`, `databricks-cli`, and `docker-scout`. Pattern: download binary and checksum, compare with `sha256sum -c -`, then install only if verified
- **Architecture debug output**: `RUN echo "Building for architecture: ${TARGETARCH}"` early in the build helps with multi-arch build troubleshooting
- **UV environment variables**: The image sets `UV_LINK_MODE=copy`, `UV_COMPILE_BYTECODE=1`, and `PYTHONUNBUFFERED=1` for uv/Python behaviour
- **Working directory**: `WORKDIR /app` is set as the default working directory in the image
- **No project-specific code patterns**: This repo is for image/tooling only

## Integration Points

- **External dependencies**: AWS CLI, kubectl, Helm, Node.js, pnpm, Python (via uv), jq, databricks-cli, Terraform, docker-scout, Docker APT repository
- **Image consumers**: Downstream users are expected to mount code or provide commands at runtime
- **Docker daemon integration (optional)**: Docker CLI usage inside the container depends on mounting `/var/run/docker.sock`
- **No internal services or APIs**: This repo does not define or expose any services

## Key Files

- `Dockerfile`: Multi-stage build logic and tool installation. Declares tool version `ARG`s at the top, uses `uv-binaries` stage, and installs all cloud operations tools with SHA256 verification where applicable
- `.github/workflows/workflow.yml`: CI/CD pipeline for building and publishing the image. Triggers on: pushes to `main`, tags starting with `v`, PRs to `main`, and manual dispatch. Only pushes to GHCR on version tags (`refs/tags/v*`)
- `.dockerignore`: Excludes build context files (LICENSE, *.md, .git, .github, .gitignore, .dockerignore, .env, .idea) to keep image build context minimal
- `README.md`: Minimal project description and runtime examples

## Example Usage

```sh
# Build the image locally
$ docker build -t cloud-ops-builder .

# Run the image interactively
$ docker run --rm -it cloud-ops-builder bash
```

---

For more, see the Dockerfile and workflow YAML for exact tool versions and build steps.
