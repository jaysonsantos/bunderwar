# Repository Guidelines

## Project Structure & Module Organization
- Top-level `*.Dockerfile` files define standalone images (e.g., `cheapo-builder.Dockerfile`, `redis.Dockerfile`).
- The `earthly/` directory contains many image-specific subfolders with an `Earthfile` for Earthly-based builds (e.g., `earthly/ftb-revelation/Earthfile`).
- Helper scripts live at the repo root (e.g., `build.py`, `pr-ftb-changes.sh`, `reverse-proxy.sh`).
- Configuration for dependency automation is in `renovate.json`.

## Build, Test, and Development Commands
- `python3 build.py <image>` builds a specific image locally via `docker buildx`. Example: `python3 build.py cheapo-builder`.
- `PUSH_IMAGE=1 python3 build.py <image>` builds and pushes to `ghcr.io/jaysonsantos/bunderwar`.
- `python3 build.py --output-matrix` emits a GitHub Actions build matrix for CI.
- For Earthly images, run from the image directory: `earthly --ci +all` (example: `cd earthly/ftb-revelation && earthly --ci +all`).
- There is no general-purpose test command; image builds are the primary validation.

## Coding Style & Naming Conventions
- Dockerfiles use chained `RUN` steps with `&&` and `\` line continuations.
- Image versions are stored in `ARG` or `ENV` lines using `*_VERSION` naming (parsed by `build.py`).
- Keep image names and tags consistent with the Dockerfile or Earthfile name (e.g., `cheapo-builder`).
- Use concise, lowercase names for new image folders under `earthly/`.

## Testing Guidelines
- CI validates changes by building images; verify locally with `python3 build.py <image>` when feasible.
- If modifying an Earthly image, run its `Earthfile` target as the primary check.

## Commit & Pull Request Guidelines
- Follow Conventional Commits with scopes, as seen in history: `chore(cheapo-builder): add sccache`.
- PRs should state which images are affected, why the change is needed, and whether builds were run.
- If builds were not run, call it out explicitly in the PR description.

## Security & Configuration Tips
- Base image versions are pinned in Dockerfiles; update carefully and keep tags explicit.
- Renovate manages dependency bumps; align manual updates with its conventions when possible.
