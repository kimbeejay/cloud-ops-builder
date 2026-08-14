# cloud-ops-builder

A multi-architecture Docker image for modern cloud operations automation and deployment workflows.

## Features

- **Multi-arch support**: Builds for `amd64` and `arm64` using Docker Buildx
- **Modern cloud tooling**:
  - Node.js v24 (manual install for precise multi-arch support; Corepack + pnpm enabled)
  - AWS CLI v2
  - kubectl (latest stable)
  - Helm (installed via Helm's `get-helm-4` script)
  - Docker CLI (`docker-ce-cli`, includes `docker compose`)
  - docker-scout
  - Grype
  - jq
  - databricks-cli
  - Terraform
  - Python 3.12 (via `uv` from Astral)
  - System tools: git, curl, make, xz-utils, unzip, ca-certificates, gnupg
- **Minimal base**: Uses `debian:bookworm-slim` for a small, secure footprint
- **No entrypoint**: Consumers provide commands at runtime

## Usage

### Build Locally

```sh
docker build -t cloud-ops-builder .
```

If you add a new `ARG` that is consumed by `RUN` commands in the final Debian stage, re-declare it after `FROM debian:bookworm-slim` (this Dockerfile relies on stage-local `ARG` declarations such as `NVM_VERSION`, `PNPM_VERSION`, `TF_VERSION`, and `TARGETARCH`).

The Dockerfile also pins key tool versions via `ARG`s (`KUBECTL_VERSION`, `HELM_VERSION`, `SCOUT_VERSION`) and verifies SHA256 checksums for downloaded binaries like `kubectl`, `jq`, and `terraform` before installation.

### Run Interactively

```sh
docker run --rm -it cloud-ops-builder bash
```

### Docker-in-Docker (dind) Support

To use Docker CLI and Compose inside the container, mount the host Docker socket:

```sh
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock cloud-ops-builder bash
```

You can now run Docker commands inside the container:

```sh
docker ps

docker compose version
```

### Example: Use Node.js, pnpm, AWS CLI, kubectl, Helm, jq, Python, Databricks CLI, Terraform, Grype, or Docker CLI

```sh
# Node.js
node --version
npm --version
pnpm --version

# AWS CLI
aws --version

# kubectl
kubectl version --client

# Helm
helm version --short

# jq
jq --version

# Python
python --version

# Databricks CLI
databricks --version

# Terraform
terraform version

# Grype
grype version

# Docker CLI (when `/var/run/docker.sock` is mounted)
docker version
docker compose version
```

## Release & CI/CD

- **Release**: Tag a commit with `v*` (e.g., `v1.0.0`) and push. CI will build and push multi-arch images to GHCR.
- **CI/CD**: See `.github/workflows/workflow.yml` for build and publish details.
- **Image tags**: `latest` (main branch), branch/tag/sha-based tags, and version tags (e.g., `v1.0.0`).

## Key Files

- `Dockerfile`: All build logic and tool installation (Node.js/pnpm, AWS CLI, kubectl, Helm, uv/Python, Docker CLI, docker-scout, Grype, jq, databricks-cli, Terraform)
- `.github/workflows/workflow.yml`: CI/CD pipeline
- `AGENTS.md`: AI agent onboarding and project conventions

## License

Apache-2.0
