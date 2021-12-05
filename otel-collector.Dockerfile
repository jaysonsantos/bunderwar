# syntax=docker/dockerfile:1.3-labs

FROM alpine:3.15 as builder
ARG TARGETPLATFORM

# renovate datasource=github-tags depName=open-telemetry/opentelemetry-collector-releases
ENV OTEL_VERSION 0.39.0
ENV BASE_URL https://github.com/open-telemetry/opentelemetry-collector-releases
WORKDIR /
RUN <<-EOF
    set -ex
    apk add -U curl
    arch=$(echo $TARGETPLATFORM | cut -d/ -f2)}
    curl -sLo otel.tar.gz "${BASE_URL}/releases/download/v${OTEL_VERSION}/otelcol_${OTEL_VERSION}_linux_${arch}.tar.gz"
    tar zxvf otel.tar.gz
    rm otel.tar.gz
    exit 1
EOF

FROM debian:stable-20211201-slim
COPY --from=builder /otelcol /usr/local/bin/
