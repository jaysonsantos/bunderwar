# syntax=docker/dockerfile:1.12-labs

FROM alpine:3.21 as builder
ARG TARGETPLATFORM

# renovate datasource=github-tags depName=cloudflare/cloudflared
ENV CLOUDFLARED_VERSION 2024.12.2
ENV BASE_URL https://github.com/cloudflare/cloudflared
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

CMD [ "/usr/local/bin/cloudflared" ]
