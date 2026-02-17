# syntax=docker/dockerfile:1.21-labs
ARG PLATFORMS=linux/amd64,linux/arm64

# renovate datasource=github-tags depName=rustfs/rustfs
ARG RUSTFS_VERSION=1.0.0-alpha.83

# renovate datasource=github-tags depName=rust-lang/rust
ARG RUST_TOOLCHAIN=1.93.0
FROM --platform=${TARGETPLATFORM} rust:${RUST_TOOLCHAIN}-alpine3.23 AS builder

ARG TARGETARCH
ARG RUSTFS_VERSION

ENV PROJECT_NAME=rustfs
ENV BASE_URL=https://github.com/rustfs/${PROJECT_NAME}

WORKDIR /build
RUN apk add --no-cache \
    bash \
    build-base \
    ca-certificates \
    clang \
    cmake \
    curl \
    flatbuffers \
    flatbuffers-dev \
    git \
    linux-headers \
    lld \
    musl-dev \
    openssl-dev \
    perl \
    pkgconf \
    protobuf \
    protobuf-dev

RUN curl -sLo project.tar.gz "${BASE_URL}/archive/refs/tags/${RUSTFS_VERSION}.tar.gz" \
    && tar zxvf project.tar.gz --strip-components=1 \
    && rm project.tar.gz

RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git \
    --mount=type=cache,target=/build/target \
    set -eux; \
    case "$TARGETARCH" in \
      amd64) \
        target_triple=x86_64-unknown-linux-musl; \
        export RUSTFLAGS='-C target-cpu=x86-64-v2' \
      ;; \
      arm64) \
        target_triple=aarch64-unknown-linux-musl; \
        unset RUSTFLAGS \
      ;; \
      *) \
        echo "Unsupported TARGETARCH=$TARGETARCH" >&2; \
        exit 1 \
      ;; \
    esac; \
    rustup target add "$target_triple"; \
    cargo build --locked --release --target "$target_triple" --package rustfs --bin rustfs; \
    install -D -m 0755 "target/${target_triple}/release/rustfs" /out/rustfs

FROM alpine:3.23
COPY --from=builder --chmod=755 /out/rustfs /usr/local/bin/rustfs

RUN apk add --no-cache ca-certificates \
    && addgroup -S rustfs \
    && adduser -S -G rustfs rustfs

EXPOSE 9000 9001
USER rustfs
ENTRYPOINT ["/usr/local/bin/rustfs"]
