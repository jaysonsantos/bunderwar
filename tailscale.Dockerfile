# syntax=docker/dockerfile:1.6-labs
ARG PLATFORMS=linux/arm/v7
FROM --platform=${BUILDPLATFORM} golang:1.22-bullseye as builder
ARG TARGETPLATFORM
ARG TARGETARCH
ARG TARGETVARIANT

# renovate datasource=github-tags depName=tailscale/tailscale
ENV PROJECT_VERSION v1.60.1
ENV PROJECT_NAME=tailscale
ENV BASE_URL https://github.com/tailscale/${PROJECT_NAME}
WORKDIR /build
RUN apt update && apt install curl -y
RUN curl -sLo project.tar.gz "${BASE_URL}/archive/refs/tags/${PROJECT_VERSION}.tar.gz" && \
    tar zxvf project.tar.gz --strip-components=1 ${PROJECT_NAME}-$(echo $PROJECT_VERSION | sed 's/^v//')/ && \
    rm project.tar.gz
RUN <<-EOF
    set -ex

    export GOARCH=$TARGETARCH
    if [ "$TARGETARCH" = arm ]; then
        export GOARM=$(echo $TARGETVARIANT | grep -oE '[0-9]+')
    fi
    go build ./cmd/tailscale
    go build ./cmd/tailscaled
EOF

FROM debian:stable-slim
ARG TARGETPLATFORM
COPY --from=builder --chmod=755 /build/tailscale /usr/local/bin/
COPY --from=builder --chmod=755 /build/tailscaled /usr/local/bin/

ENTRYPOINT [ "/usr/local/bin/tailscaled" ]
