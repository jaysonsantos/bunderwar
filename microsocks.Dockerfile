# syntax=docker/dockerfile:1.22-labs

FROM alpine:3.23 AS builder
ARG TARGETPLATFORM

# renovate datasource=github-tags depName=rofl0r/microsocks
ENV MICROSOCKS_VERSION=v1.0.5
ENV PROJECT_NAME=microsocks
ENV BASE_URL=https://github.com/rofl0r/${PROJECT_NAME}

WORKDIR /build
RUN <<-EOF
    set -ex
    apk add -U --no-cache \
        build-base \
        curl
    arch=$(echo $TARGETPLATFORM | cut -d/ -f2)
    echo "Building ${PROJECT_NAME} for ${arch} from ${MICROSOCKS_VERSION}"
    curl -sLo ${PROJECT_NAME}.tar.gz "${BASE_URL}/archive/refs/tags/${MICROSOCKS_VERSION}.tar.gz"
    tar -xzvf ${PROJECT_NAME}.tar.gz --strip-components=1 "${PROJECT_NAME}-$(echo $MICROSOCKS_VERSION | sed 's/^v//')/"
    rm -f ${PROJECT_NAME}.tar.gz
    make -j"$(nproc)"
EOF

FROM alpine:3.23
ARG TARGETPLATFORM
COPY --from=builder --chmod=755 /build/microsocks /usr/local/bin/microsocks

EXPOSE 1080
ENTRYPOINT ["/usr/local/bin/microsocks"]
CMD ["-i", "0.0.0.0", "-p", "1080"]
