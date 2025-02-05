# syntax=docker/dockerfile:1.13-labs

FROM alpine:3.21 AS builder
ARG TARGETPLATFORM

# renovate datasource=github-tags depName=cloudflare/cloudflared
ENV CLOUDFLARED_VERSION=2025.2.0
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
RUN ["/usr/local/bin/cloudflared", "--version"]

CMD [ "/usr/local/bin/cloudflared" ]
