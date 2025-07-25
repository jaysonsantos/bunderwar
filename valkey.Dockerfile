# syntax=docker/dockerfile:1.17-labs

FROM --platform=linux/amd64 debian:buster-slim as builder
ARG TARGETPLATFORM

# renovate datasource=github-tags depName=valkey/valkey
ENV PROJECT_VERSION 8.0.1
ENV PROJECT_NAME=valkey
ENV BASE_URL https://github.com/valkey-io/${PROJECT_NAME}

# renovate datasource=github-tags depName=ziglang/zig
ENV ZIG_VERSION 0.14.1
WORKDIR /build
RUN <<-EOF
    set -ex
    mkdir -p ${TARGETPLATFORM}
    apt update && apt install -y curl xz-utils make pkg-config
    curl -sLo zig.tar.xz https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz
    mkdir -p /opt/zig
    (cd /opt/zig && tar xvf /build/zig.tar.xz --strip-components=1)
    rm zig.tar.xz
    arch=$(echo $TARGETPLATFORM | cut -d/ -f2)
    zig_arch=$(echo $arch | sed 's/arm64/aarch64/' | sed 's/amd64/x86_64/')
    curl -sLo project.tar.gz "${BASE_URL}/archive/refs/tags/${PROJECT_VERSION}.tar.gz"
    tar zxvf project.tar.gz --strip-components=1 ${PROJECT_NAME}-$(echo $PROJECT_VERSION | sed 's/^v//')/
    rm project.tar.gz
    export PATH="$PATH:/opt/zig"
    make CC="zig cc -target $zig_arch-linux-musl" CXX="zig c++ -target $zig_arch-linux-musl" AR="zig ar" RANLIB="zig ranlib" uname_S="Linux" uname_M="$zig_arch" C11_ATOMIC=yes USE_JEMALLOC=no USE_SYSTEMD=no
    mkdir -p $TARGETPLATFORM
    find
    mv src/valkey-server src/valkey-cli $TARGETPLATFORM/
EOF

FROM gcr.io/distroless/static:nonroot
ARG TARGETPLATFORM
COPY --from=builder --chmod=755 /build/${TARGETPLATFORM} /usr/local/bin/

RUN ["/usr/local/bin/valkey-server", "--version"]
ENTRYPOINT [ "/usr/local/bin/valkey-server" ]
CMD ["/etc/valkey/external.conf.d/valkey-external.conf"]
