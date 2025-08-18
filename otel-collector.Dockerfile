# syntax=docker/dockerfile:1.17-labs

FROM alpine:3.22 as builder
ARG TARGETPLATFORM

# renovate datasource=github-tags depName=open-telemetry/opentelemetry-collector-releases
ENV OTEL_VERSION v0.132.3
ENV BASE_URL https://github.com/open-telemetry/opentelemetry-collector-releases
WORKDIR /
RUN <<-EOF
    set -ex
    apk add -U curl
    arch=$(echo $TARGETPLATFORM | cut -d/ -f2)
    curl -sLo otel.tar.gz "${BASE_URL}/releases/download/${OTEL_VERSION}/otelcol_${OTEL_VERSION/v/}_linux_${arch}.tar.gz"
    tar zxvf otel.tar.gz
    rm otel.tar.gz
EOF

FROM gcr.io/distroless/static
COPY --from=builder /otelcol /usr/local/bin/

CMD [ "/usr/local/bin/otelcol" ]
