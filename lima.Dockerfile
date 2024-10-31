# syntax=docker/dockerfile:1.11-labs

FROM alpine:3.20 as builder
ARG TARGETPLATFORM

# renovate datasource=github-releases depName=lima-vm/lima
ENV LIMA_VERSION v0.23.2
ENV BASE_URL https://github.com/lima-vm/lima 
WORKDIR /
RUN <<-EOF
    set -ex
    apk add -U curl
    curl -sLo lima.tgz "${BASE_URL}/releases/download/${LIMA_VERSION}/lima-${LIMA_VERSION/v/}-Linux-$(uname -m).tar.gz"
    mkdir /opt/lima
    tar zxvf lima.tgz -C /opt/lima
EOF

FROM debian
COPY --from=builder /opt/lima /opt/lima 
ENV PATH="$PATH:/opt/lima/bin"
