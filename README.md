# cloud-ops-builder

A multi-architecture Docker image for modern cloud operations automation and deployment workflows.

## Features

- **Multi-arch support**: Builds for `amd64` and `arm64` using Docker Buildx
- **Modern cloud tooling**:
  - Node.js v24 (manual install for precise multi-arch support)
  - AWS CLI v2
  - kubectl (latest stable)
  - Helm (latest)
  - Python 3.12 (via `uv` from Astral)
  - System tools: git, curl, make, xz-utils, unzip, ca-certificates
- **Minimal base**: Uses `debian:bookworm-slim` for a small, secure footprint
- **No entrypoint**: Consumers provide commands at runtime

## Usage

### Build Locally

```sh
docker build -t cloud-ops-builder .
```

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

### Example: Use Node.js, AWS CLI, kubectl, Helm, or Python

```sh
# Node.js
node --version
npm --version

# AWS CLI
aws --version

# kubectl
kubectl version --client

# Helm
helm version --short

# Python
python --version
```

## Release & CI/CD

- **Release**: Tag a commit with `v*` (e.g., `v1.0.0`) and push. CI will build and push multi-arch images to GHCR.
- **CI/CD**: See `.github/workflows/workflow.yml` for build and publish details.
- **Image tags**: `latest` (main branch), branch/tag/sha-based tags, and version tags (e.g., `v1.0.0`).

## Key Files

- `Dockerfile`: All build logic and tool installation (including Docker CLI via Docker's APT repo)
- `.github/workflows/workflow.yml`: CI/CD pipeline
- `AGENTS.md`: AI agent onboarding and project conventions

## License

Apache-2.0
