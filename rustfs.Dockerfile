# syntax=docker/dockerfile:1.22-labs
ARG PLATFORMS=linux/amd64,linux/arm64

# renovate datasource=github-tags depName=rustfs/rustfs
ARG RUSTFS_VERSION=1.0.0-beta.4

FROM --platform=${BUILDPLATFORM} rust:1.95.0-trixie AS builder

ARG TARGETPLATFORM
ARG TARGETARCH
ARG RUSTFS_VERSION
ARG ZIG_VERSION=0.14.1

WORKDIR /build

COPY --from=ghcr.io/jaysonsantos/bunderwar:cargo-zigbuild-0.22.3 /usr/local/bin/cargo-zigbuild /usr/local/bin/cargo-zigbuild

RUN set -eux; \
    case "$(dpkg --print-architecture)" in \
      amd64) zig_arch="x86_64" ;; \
      arm64) zig_arch="aarch64" ;; \
      *) echo "Unsupported builder architecture" >&2; exit 1 ;; \
    esac; \
    case "$TARGETARCH" in \
      amd64) \
        RUST_TARGET="x86_64-unknown-linux-gnu"; \
        GNU_TRIPLE="x86_64-linux-gnu"; \
        SYSTEMD_PACKAGE_ARCH="amd64"; \
        ;; \
      arm64) \
        RUST_TARGET="aarch64-unknown-linux-gnu"; \
        GNU_TRIPLE="aarch64-linux-gnu"; \
        SYSTEMD_PACKAGE_ARCH="arm64"; \
        ;; \
      *) echo "Unsupported TARGETARCH=$TARGETARCH" >&2; exit 1 ;; \
    esac; \
    if [ "$(dpkg --print-architecture)" != "$SYSTEMD_PACKAGE_ARCH" ]; then \
      dpkg --add-architecture "$SYSTEMD_PACKAGE_ARCH"; \
    fi; \
    apt-get update; \
    apt-get install --no-install-recommends -y \
      ca-certificates \
      curl \
      libsystemd-dev:${SYSTEMD_PACKAGE_ARCH} \
      perl \
      pkg-config \
      protobuf-compiler \
      xz-utils; \
    rm -rf /var/lib/apt/lists/*; \
    curl -fsSL "https://ziglang.org/download/${ZIG_VERSION}/zig-${zig_arch}-linux-${ZIG_VERSION}.tar.xz" -o zig.tar.xz; \
    mkdir -p /usr/local/zig; \
    tar -xJf zig.tar.xz -C /usr/local/zig --strip-components=1; \
    ln -s /usr/local/zig/zig /usr/local/bin/zig; \
    rm zig.tar.xz; \
    curl -fsSL "https://api.github.com/repos/rustfs/rustfs/tarball/refs/tags/${RUSTFS_VERSION}" -o rustfs.tar.gz; \
    tar -xzf rustfs.tar.gz --strip-components=1; \
    rm rustfs.tar.gz; \
    rustup target add "$RUST_TARGET"; \
    touch rustfs/build.rs; \
    export PKG_CONFIG_ALLOW_CROSS=1; \
    export PKG_CONFIG_LIBDIR="/usr/lib/${GNU_TRIPLE}/pkgconfig:/usr/share/pkgconfig"; \
    cargo zigbuild --release --target "$RUST_TARGET" -p rustfs --bins; \
    install -D "target/${RUST_TARGET}/release/rustfs" "/out/${TARGETPLATFORM}/rustfs"

FROM debian:trixie-slim
ARG TARGETPLATFORM
COPY --from=builder --chmod=755 /out/${TARGETPLATFORM}/rustfs /usr/local/bin/rustfs

LABEL org.opencontainers.image.title="rustfs" \
      org.opencontainers.image.description="High-performance distributed file system built with Rust for cloud-native storage" \
      org.opencontainers.image.source="https://github.com/jaysonsantos/bunderwar"

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
