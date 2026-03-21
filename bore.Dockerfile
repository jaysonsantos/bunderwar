# syntax=docker/dockerfile:1.22-labs

FROM --platform=${BUILDPLATFORM} rust:1.94.0-slim-trixie as builder
ARG TARGETPLATFORM

# renovate datasource=github-tags depName=ekzhang/bore
ENV PROJECT_VERSION v0.6.0
ENV PROJECT_NAME=bore
ENV BASE_URL https://github.com/ekzhang/${PROJECT_NAME}
WORKDIR /build
RUN <<-EOF
    set -ex
    mkdir -p ${TARGETPLATFORM} linux/amd64 linux/arm64

    echo x86_64-unknown-linux-gnu > linux/amd64/rust-target
    echo aarch64-unknown-linux-gnu > linux/arm64/rust-target
    
    export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=x86_64-linux-gnu-gcc \
    CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc \
    CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUNNER="/linux-runner aarch64" \
    CC_x86_64_unknown_linux_gnu=x86_64-linux-gnu-gcc \
    CC_aarch64_unknown_linux_gnu=aarch64-linux-gnu-gcc

    RUST_TARGET=$(cat ${TARGETPLATFORM}/rust-target)

    apt update && apt install curl -y gcc-aarch64-linux-gnu gcc-x86-64-linux-gnu
    apt clean
    curl -sLo project.tar.gz "${BASE_URL}/archive/refs/tags/${PROJECT_VERSION}.tar.gz"
    tar zxvf project.tar.gz --strip-components=1 ${PROJECT_NAME}-$(echo $PROJECT_VERSION | sed 's/^v//')/
    rm project.tar.gz
    rustup target add "$RUST_TARGET"
    cargo build --release --target "$RUST_TARGET"
    cp "target/$RUST_TARGET/release/bore" "${TARGETPLATFORM}"
EOF

FROM debian:trixie-slim
ARG TARGETPLATFORM
COPY --from=builder --chmod=755 /build/${TARGETPLATFORM}/bore /usr/local/bin/

ENTRYPOINT [ "/usr/local/bin/bore" ]
