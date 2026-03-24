# syntax=docker/dockerfile:1.22-labs
ARG PLATFORMS=linux/amd64,linux/arm64

# renovate datasource=github-tags depName=rustfs/rustfs
ARG RUSTFS_VERSION=1.0.0-alpha.90

FROM --platform=linux/$TARGETARCH rust:1.93.0-trixie AS builder

ARG TARGETARCH
ARG RUSTFS_VERSION
ARG RUST_TOOLCHAIN=1.93.0

WORKDIR /build

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    ca-certificates \
    clang \
    cmake \
    curl \
    g++ \
    libsystemd-dev \
    make \
    perl \
    pkg-config \
    protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    case "$TARGETARCH" in \
      amd64|arm64) ;; \
      *) echo "Unsupported TARGETARCH=$TARGETARCH" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://api.github.com/repos/rustfs/rustfs/tarball/refs/tags/${RUSTFS_VERSION}" -o rustfs.tar.gz; \
    tar -xzf rustfs.tar.gz --strip-components=1; \
    rm rustfs.tar.gz

RUN set -eux; \
    case "$(dpkg --print-architecture)" in \
      amd64) TOOLCHAIN="${RUST_TOOLCHAIN}-x86_64-unknown-linux-gnu" ;; \
      arm64) TOOLCHAIN="${RUST_TOOLCHAIN}-aarch64-unknown-linux-gnu" ;; \
      *) echo "Unsupported builder architecture" >&2; exit 1 ;; \
    esac; \
    touch rustfs/build.rs; \
    rustup run "$TOOLCHAIN" cargo build --release -p rustfs --bins; \
    install -D target/release/rustfs /out/rustfs

FROM debian:trixie-slim
COPY --from=builder --chmod=755 /out/rustfs /usr/local/bin/rustfs

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    ca-certificates \
    libsystemd0 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system rustfs \
    && useradd --system --gid rustfs --no-create-home rustfs

EXPOSE 9000 9001
USER rustfs
ENTRYPOINT ["/usr/local/bin/rustfs"]
