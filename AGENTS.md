# Repository Guidelines

This file gives guidance to coding agents (Claude Code, Codex, and others) that work in this repository. `CLAUDE.md` is a symlink to this file.

This repository builds personal Docker images for `linux/amd64` and `linux/arm64`. Renovate keeps the versions up to date. All images go to one registry repository, `ghcr.io/jaysonsantos/bunderwar`. The tag identifies the image: `<image-name>-<version>`.

## Commands

- `python3 build.py <image>` builds one image with `docker buildx`. Example: `python3 build.py cheapo-builder`.
- `python3 build.py <path>` also accepts a file path. Examples: `redis.Dockerfile`, `earthly/ftb-revelation/Earthfile`.
- `python3 build.py` with no arguments builds all `*.Dockerfile` images. It does not build the Earthly images.
- `PUSH_IMAGE=1 python3 build.py <image>` builds the image and pushes it to the registry.
- `python3 build.py --output-matrix <files>` writes the CI build matrix to `$GITHUB_OUTPUT`. It does not build an image.
- `cd earthly/<image> && earthly --ci +all` builds one Earthly image. CI pins Earthly `v0.6.30`.
- `python3 -m doctest build.py` runs the tests of `build.py`.
  - The two `Image.load` doctests fail. They contain a fixed `otel-collector` version, and Renovate changes that version.
  - The `parse_version` doctests pass.
- No lint command and no other test command exist. An image build is the primary check.

## Architecture

### `build.py` connects all parts

- `build.py` reads a Dockerfile or an Earthfile and finds the first `ENV` or `ARG` line with a `*_VERSION` name.
- That first value is the image version. `build.py` removes each `v` character from it.
- Put the version of the primary software before all other `*_VERSION` lines. See `redis.Dockerfile`: `PROJECT_VERSION` comes before `ZIG_VERSION`.
- If a file has no `*_VERSION` line, `build.py` skips the image.
- The image name is the Dockerfile stem (`redis.Dockerfile` gives `redis`). For an Earthfile, the image name is the directory name.
- The default platforms are `linux/amd64` and `linux/arm64`. An `ARG PLATFORMS=<comma list>` line in the Dockerfile sets other platforms.
- `build.py` reads the `LABEL` blocks of a Dockerfile and passes each `key="value"` pair as a `--annotation` argument.
- The build context is always the repository root. Thus `komga.Dockerfile` copies from `komga/root`, and `postgres.Dockerfile` copies from `postgres/initdb`.

### CI (`.github/workflows/images.yaml`)

1. `collect-files` sends the changed files of the commit to `build.py --output-matrix`.
2. `build.py` skips each file that is not a `*.Dockerfile` or an `Earthfile`.
3. `run-builds` runs one matrix job for each build command.
4. On `main`, CI sets `PUSH_IMAGE=1`, and each job pushes a multi-platform image.
5. On a pull request, each job builds one platform and pushes nothing. `merge-manifests` runs only on `main`.
6. `guard` fails if a job before it failed. Use `guard` as the required status check.

A change to a support file only (for example `komga/root/...`) does not start a build. To build the image again, also change its Dockerfile, or start the workflow manually with the `manual_files` glob input.

### Renovate (`renovate.json`)

- A custom regex manager reads a comment line immediately before each version line:
  ```dockerfile
  # renovate datasource=github-tags depName=redis/redis
  ENV PROJECT_VERSION 8.6.1
  ```
- An optional `versioning=<scheme>` field comes after `depName`. The default is `semver`.
- The manager applies to `*.Dockerfile` files and to `Earthfile` files.
- `automerge` is on. A Renovate pull request merges when CI passes, and the merge on `main` publishes the new tag.
- A package rule reads the `<image-name>-<version>` tags of this registry repository. Thus one image here can use another image here as a base.

### Earthly images (`earthly/`)

Each image directory contains a small Earthfile. That Earthfile sets arguments and imports a shared Earthfile.

- `earthly/ftb/Earthfile` builds FTB Minecraft modpack servers.
  - Each `earthly/ftb-*` and `earthly/direwolf20-*` directory sets `MOD_ID`, `MOD_VERSION`, `NAME`, and `IS_BETA`.
  - `earthly/dump-ftb-modpacks.py` writes these Earthfiles again from the modpacks.ch API. Do not edit them manually.
  - `pr-ftb-changes.sh` then opens one branch and one pull request for each changed or added `earthly/` directory.
- `earthly/rust-binaries/Earthfile` builds Rust CLI tools such as `cargo-audit`.
  - To add a tool, run `./add-rust-bin.sh <crate>` in `earthly/`. The script needs `envsubst-rs`, `jq`, and `curl`.
- Earthfiles push their own tags with `SAVE IMAGE --push`. The FTB images also push a `<name>-latest` tag.

## Conventions

- Most Dockerfiles follow one pattern:
  - An amd64 builder stage downloads or cross-compiles the binary for `${TARGETPLATFORM}`. Some images use `zig cc` for this.
  - The final stage copies the binary into a distroless or minimal image.
  - A `RUN ["<binary>", "--version"]` step in the final stage checks the binary on each platform.
- Use heredoc `RUN <<-EOF` blocks or `&&` chains. Do the same as the adjacent files.
- Keep the base image tags explicit. Renovate updates them.
- Use short lowercase names with hyphens for new images and for new `earthly/` directories.

## Commits and pull requests

- Use Conventional Commits with the image name as the scope. Example: `chore(cheapo-builder): add sccache`.
- In the pull request, list the changed images and the reason for the change.
- State if you ran the builds. If you did not run them, say so.
