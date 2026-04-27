# uv-make

Minimal Docker image for Python projects that use `uv` and `make`.

## What this image provides

- Base image: `ghcr.io/astral-sh/uv:${UV_IMAGE_TAG}`
- Added package: GNU `make`
- Working directory: `/app`

See `Dockerfile` for the full image definition.

## Local build

This repo keeps a local default base image tag in `.env`.

```zsh
docker build \
  --build-arg UV_IMAGE_TAG=$(grep '^UV_IMAGE_TAG=' .env | cut -d= -f2) \
  -t uv-make:local \
  .
```

Optional explicit tag override:

```zsh
docker build --build-arg UV_IMAGE_TAG=0.11.7-python3.12-trixie-slim -t uv-make:local .
```

## Configuration model

- Local development uses `.env` (`UV_IMAGE_TAG=...`).
- CI does **not** read `.env`; it uses GitHub Actions variable `vars.UV_IMAGE_TAG`.
- The workflow passes `UV_IMAGE_TAG` into Docker build args.

## CI and release behavior

Defined in `.github/workflows/workflow.yml`:

- Runs on pushes and pull requests to `main`, plus manual dispatch.
- Also runs on tags matching `v*`.
- Builds multi-arch images for `linux/amd64` and `linux/arm64`.
- Pushes to GHCR only when the ref is a version tag (`refs/tags/v*`).
- Fails early if `UV_IMAGE_TAG` is missing in GitHub Actions variables.

## Notes

- `.env` is git-ignored and intended for local use only.
- `.dockerignore` excludes repo metadata and local-only files from build context.

