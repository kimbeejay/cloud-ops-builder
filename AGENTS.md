# AGENTS.md

## Purpose
- This repo builds a minimal Docker image for Python projects that use `uv` + `make`.
- The image extends `ghcr.io/astral-sh/uv` and adds GNU `make` (`Dockerfile`).

## Big Picture Architecture
- Single artifact project: one container image definition in `Dockerfile`.
- CI/CD boundary is `.github/workflows/workflow.yml`; no app/runtime source tree exists.
- Version selection flow:
  - Local default in `.env`: `UV_IMAGE_TAG=0.11.7-python3.12-trixie-slim`.
  - CI uses GitHub Actions variable `vars.UV_IMAGE_TAG` (not `.env`).
  - Workflow passes that value into Docker build arg `UV_IMAGE_TAG`.

## Critical Workflows
- Build locally (from repo root):
  - `docker build --build-arg UV_IMAGE_TAG=$(grep '^UV_IMAGE_TAG=' .env | cut -d= -f2) -t uv-make:local .`
- Validate base image tag before CI runs:
  - Ensure GitHub Actions variable `UV_IMAGE_TAG` is set (`workflow.yml`, "Validate required..." step).
- Release behavior:
  - Workflow runs on pushes/PRs to `main`, and tags `v*`.
  - Images are pushed to GHCR only for tag refs `refs/tags/v*` (`push:` condition in build step).
  - Multi-arch output is configured: `linux/amd64,linux/arm64`.

## Project-Specific Conventions
- Keep image slim: install only `make` and remove apt lists in the same `RUN` layer (`Dockerfile` lines 10-12).
- Keep metadata labels updated in `Dockerfile` (`org.opencontainers.image.*`).
- `.dockerignore` intentionally excludes repo metadata and docs (`.git`, `.github`, `LICENSE`, `README.md`, `.env`).
- `.env` is local-only and ignored by git (`.gitignore`); never rely on it in CI logic.

## Integration Points
- External dependency: base image `ghcr.io/astral-sh/uv:${UV_IMAGE_TAG}`.
- Registry integration: GHCR login via `${{ secrets.GITHUB_TOKEN }}` on version tags.
- Tag/label generation relies on `docker/metadata-action@v5` defaults in `workflow.yml`.

## Existing AI Guidance Files
- One required glob search for AI convention files returned no matches:
  - `**/{.github/copilot-instructions.md,AGENT.md,AGENTS.md,CLAUDE.md,.cursorrules,.windsurfrules,.clinerules,.cursor/rules/**,.windsurf/rules/**,.clinerules/**,README.md}`
- This file is now the canonical agent guidance for this repository.

