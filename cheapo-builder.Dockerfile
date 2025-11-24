# renovate datasource=github-tags depName=rust-lang/rust
ARG RUST_VERSION=1.91.1
FROM rust:${RUST_VERSION}-slim
ARG ZIG_VERSION=0.14.1
RUN apt update \
    && apt install --no-install-recommends -y \
    restic qemu-system qemu-utils ovmf make protobuf-compiler nodejs time cloud-utils postgresql-client sudo curl xz-utils jq \
    && rustup default nightly \
    && rustup component add rustfmt clippy \
    && rustup target add aarch64-unknown-linux-gnu \
    && rustup target add x86_64-unknown-linux-gnu \
    && curl -sLo /tmp/zig.tar.xz https://ziglang.org/download/${ZIG_VERSION}/zig-$(uname -m)-linux-${ZIG_VERSION}.tar.xz \
    && mkdir /usr/local/zig && tar xvf /tmp/zig.tar.xz -C /usr/local/zig --strip-components=1 && rm /tmp/zig.tar.xz \
    && ln -s /usr/local/zig/zig /usr/local/bin/zig \
    && zig version \
    && rm -rf /var/lib/apt/lists/* \
    && echo "code ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/code
COPY --from=quay.io/coreos/butane /usr/local/bin/butane /usr/local/bin/butane

COPY --from=ghcr.io/jaysonsantos/bunderwar:cargo-outdated-0.17.0 /usr/local/bin/cargo-outdated /usr/local/bin/
COPY --from=ghcr.io/jaysonsantos/bunderwar:cargo-deny-0.18.6 /usr/local/bin/cargo-deny /usr/local/bin/
COPY --from=ghcr.io/jaysonsantos/bunderwar:cargo-udeps-0.1.60 /usr/local/bin/cargo-udeps /usr/local/bin/
COPY --from=ghcr.io/jaysonsantos/bunderwar:cargo-audit-0.17.4 /usr/local/bin/cargo-audit /usr/local/bin/
COPY --from=ghcr.io/jaysonsantos/bunderwar:sqlx-cli-0.8.6 /usr/local/bin/ /usr/local/bin/
COPY --from=ghcr.io/jaysonsantos/bunderwar:cargo-zigbuild-0.20.1 /usr/local/bin/ /usr/local/bin/
COPY --from=ghcr.io/jaysonsantos/bunderwar:lima-2.0.1 /opt/lima/ /usr/local/

RUN mkdir /__w/ && chown 1000:1000 /__w/ && chown -R 1000:1000 /usr/local/cargo

ARG UID=1000
RUN useradd --create-home --uid $UID code
USER code
