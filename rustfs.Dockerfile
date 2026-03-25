# syntax=docker/dockerfile:1.22-labs
ARG PLATFORMS=linux/amd64,linux/arm64

# renovate datasource=github-tags depName=rustfs/rustfs
ARG RUSTFS_VERSION=1.0.0-alpha.90

FROM --platform=${BUILDPLATFORM} rust:1.93.0-trixie AS builder

ARG TARGETPLATFORM
ARG TARGETARCH
ARG RUSTFS_VERSION
ARG RUST_TOOLCHAIN=1.93.0

WORKDIR /build

RUN set -eux; \
    case "$TARGETARCH" in \
      amd64) \
        RUST_TARGET="x86_64-unknown-linux-gnu"; \
        GNU_TRIPLE="x86_64-linux-gnu"; \
        LINKER="x86_64-linux-gnu-gcc"; \
        GCC_PACKAGE="gcc-x86-64-linux-gnu"; \
        LIBC_DEV_PACKAGE="libc6-dev-amd64-cross"; \
        CARGO_LINKER_VAR="CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER"; \
        CC_VAR="CC_x86_64_unknown_linux_gnu"; \
        CFLAGS_VAR="CFLAGS_x86_64_unknown_linux_gnu"; \
        ;; \
      arm64) \
        RUST_TARGET="aarch64-unknown-linux-gnu"; \
        GNU_TRIPLE="aarch64-linux-gnu"; \
        LINKER="aarch64-linux-gnu-gcc"; \
        GCC_PACKAGE="gcc-aarch64-linux-gnu"; \
        LIBC_DEV_PACKAGE="libc6-dev-arm64-cross"; \
        CARGO_LINKER_VAR="CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER"; \
        CC_VAR="CC_aarch64_unknown_linux_gnu"; \
        CFLAGS_VAR="CFLAGS_aarch64_unknown_linux_gnu"; \
        ;; \
      *) echo "Unsupported TARGETARCH=$TARGETARCH" >&2; exit 1 ;; \
    esac; \
    case "$(dpkg --print-architecture)" in \
      amd64) NATIVE_TOOLCHAIN="${RUST_TOOLCHAIN}-x86_64-unknown-linux-gnu" ;; \
      arm64) NATIVE_TOOLCHAIN="${RUST_TOOLCHAIN}-aarch64-unknown-linux-gnu" ;; \
      *) echo "Unsupported builder architecture" >&2; exit 1 ;; \
    esac; \
    SYSROOT="/usr/${GNU_TRIPLE}"; \
    if [ "$(dpkg --print-architecture)" != "$TARGETARCH" ]; then \
      dpkg --add-architecture "$TARGETARCH"; \
    fi; \
    apt-get update; \
    apt-get install --no-install-recommends -y \
      ca-certificates \
      clang \
      cmake \
      curl \
      g++ \
      "$LIBC_DEV_PACKAGE" \
      libsystemd-dev:${TARGETARCH} \
      make \
      perl \
      pkg-config \
      protobuf-compiler \
      "$GCC_PACKAGE"; \
    rm -rf /var/lib/apt/lists/*; \
    curl -fsSL "https://api.github.com/repos/rustfs/rustfs/tarball/refs/tags/${RUSTFS_VERSION}" -o rustfs.tar.gz; \
    tar -xzf rustfs.tar.gz --strip-components=1; \
    rm rustfs.tar.gz; \
    rustup target add --toolchain "$NATIVE_TOOLCHAIN" "$RUST_TARGET"; \
    touch rustfs/build.rs; \
    export PKG_CONFIG_ALLOW_CROSS=1; \
    export PKG_CONFIG_SYSROOT_DIR="${SYSROOT}"; \
    export PKG_CONFIG_LIBDIR="/usr/lib/${GNU_TRIPLE}/pkgconfig:/usr/share/pkgconfig"; \
    export "${CARGO_LINKER_VAR}=${LINKER}"; \
    export "${CC_VAR}=${LINKER}"; \
    export "${CFLAGS_VAR}=--sysroot=${SYSROOT}"; \
    rustup run "$NATIVE_TOOLCHAIN" cargo build --release --target "$RUST_TARGET" -p rustfs --bins; \
    install -D "target/${RUST_TARGET}/release/rustfs" "/out/${TARGETPLATFORM}/rustfs"

FROM debian:trixie-slim
ARG TARGETPLATFORM
COPY --from=builder --chmod=755 /out/${TARGETPLATFORM}/rustfs /usr/local/bin/rustfs

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
