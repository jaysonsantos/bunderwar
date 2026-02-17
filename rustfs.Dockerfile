# syntax=docker/dockerfile:1.21-labs
ARG PLATFORMS=linux/amd64,linux/arm64

# renovate datasource=github-tags depName=rustfs/rustfs
ARG RUSTFS_VERSION=1.0.0-alpha.83

FROM alpine:3.23 AS builder

ARG TARGETARCH
ARG RUSTFS_VERSION

ENV PROJECT_NAME=rustfs
ENV BASE_URL=https://github.com/rustfs/${PROJECT_NAME}

WORKDIR /build
RUN apk add --no-cache ca-certificates curl unzip

RUN set -eux; \
    case "$TARGETARCH" in \
      amd64) ARCH_SUBSTR="x86_64-musl" ;; \
      arm64) ARCH_SUBSTR="aarch64-musl" ;; \
      *) echo "Unsupported TARGETARCH=$TARGETARCH" >&2; exit 1 ;; \
    esac; \
    URL="$(curl -fsSL "https://api.github.com/repos/rustfs/rustfs/releases/tags/${RUSTFS_VERSION}" \
      | grep -o "\"browser_download_url\": \"[^\"]*${ARCH_SUBSTR}[^\"]*\\.zip\"" \
      | cut -d'"' -f4 \
      | head -n 1)"; \
    if [ -z "$URL" ]; then \
      echo "Failed to locate release asset for $ARCH_SUBSTR at tag $RUSTFS_VERSION" >&2; \
      exit 1; \
    fi; \
    curl -fL "$URL" -o rustfs.zip; \
    unzip -q rustfs.zip -d /build; \
    if [ ! -x /build/rustfs ]; then \
      BIN_PATH="$(unzip -Z -1 rustfs.zip | grep -E '(^|/)rustfs$' | head -n 1 || true)"; \
      if [ -n "$BIN_PATH" ]; then \
        mkdir -p /build/.tmp; \
        unzip -q rustfs.zip "$BIN_PATH" -d /build/.tmp; \
        mv "/build/.tmp/$BIN_PATH" /build/rustfs; \
      fi; \
    fi; \
    [ -x /build/rustfs ] || { echo "rustfs binary not found in asset" >&2; exit 1; }; \
    chmod +x /build/rustfs; \
    rm -rf rustfs.zip /build/.tmp || true

FROM alpine:3.23
COPY --from=builder --chmod=755 /build/rustfs /usr/local/bin/rustfs

RUN apk add --no-cache ca-certificates \
    && addgroup -S rustfs \
    && adduser -S -G rustfs rustfs

EXPOSE 9000 9001
USER rustfs
ENTRYPOINT ["/usr/local/bin/rustfs"]
