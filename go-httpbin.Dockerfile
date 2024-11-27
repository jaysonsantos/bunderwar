# syntax=docker/dockerfile:1.12-labs

FROM --platform=linux/amd64 golang:1.18-stretch as builder
ARG TARGETPLATFORM

# renovate datasource=github-tags depName=mccutchen/go-httpbin
ENV PROJECT_VERSION v2.15.0
ENV PROJECT_NAME=go-httpbin
ENV BASE_URL https://github.com/mccutchen/${PROJECT_NAME}
WORKDIR /build
RUN <<-EOF
    set -ex
    mkdir -p ${TARGETPLATFORM}
    apt update && apt install curl -y && apt clean
    arch=$(echo $TARGETPLATFORM | cut -d/ -f2)
    curl -sLo project.tar.gz "${BASE_URL}/archive/refs/tags/${PROJECT_VERSION}.tar.gz"
    tar zxvf project.tar.gz --strip-components=1 ${PROJECT_NAME}-$(echo $PROJECT_VERSION | sed 's/^v//')/
    rm project.tar.gz
    CGO_ENABLED=0 GOOS=linux GOARCH=$arch go build -o ${TARGETPLATFORM}/${PROJECT_NAME} ./cmd/go-httpbin
EOF

FROM debian:stable-20211201-slim
ARG TARGETPLATFORM
COPY --from=builder --chmod=755 /build/${TARGETPLATFORM}/go-httpbin /usr/local/bin/

ENTRYPOINT [ "/usr/local/bin/go-httpbin" ]
