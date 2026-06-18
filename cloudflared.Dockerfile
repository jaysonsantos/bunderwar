# syntax=docker/dockerfile:1.22-labs

FROM alpine:3.24 AS builder
ARG TARGETPLATFORM

# renovate datasource=github-tags depName=cloudflare/cloudflared
ENV CLOUDFLARED_VERSION=2026.6.1
ENV BASE_URL=https://github.com/cloudflare/cloudflared
WORKDIR /
RUN <<-EOF
    set -ex
    apk add -U curl
    arch=$(echo $TARGETPLATFORM | cut -d/ -f2)
    curl -sLo cloudflared "${BASE_URL}/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-${arch}"
    chmod +x cloudflared
EOF

FROM gcr.io/distroless/static
COPY --from=builder /cloudflared /usr/local/bin/

LABEL org.opencontainers.image.title="cloudflared" \
      org.opencontainers.image.description="Cloudflare tunnel client for secure connections to Cloudflare network" \
      org.opencontainers.image.source="https://github.com/jaysonsantos/bunderwar"

RUN ["/usr/local/bin/cloudflared", "--version"]

CMD [ "/usr/local/bin/cloudflared" ]
