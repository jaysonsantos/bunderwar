# renovate datasource=github-tags depName=rust-lang/rust
ARG RUST_VERSION=1.67
FROM rust:${RUST_VERSION}-bookworm
RUN apt update \
    && apt install --no-install-recommends -y \
    restic qemu-system qemu-utils ovmf make protobuf-compiler nodejs time \
    && rustup default nightly \
    && rustup component add rustfmt clippy \
    && rustup target add aarch64-unknown-linux-gnu \
    && rustup target add x86_64-unknown-linux-gnu \
    && rm -rf /var/lib/apt/lists/*
COPY --from=quay.io/coreos/butane /usr/local/bin/butane /usr/local/bin/butane

COPY --from=ghcr.io/jaysonsantos/bunderwar:cargo-outdated-0.11.2 /usr/local/bin/cargo-outdated /usr/local/bin/
COPY --from=ghcr.io/jaysonsantos/bunderwar:cargo-deny-0.13.7 /usr/local/bin/cargo-deny /usr/local/bin/
COPY --from=ghcr.io/jaysonsantos/bunderwar:cargo-udeps-0.1.35 /usr/local/bin/cargo-udeps /usr/local/bin/
COPY --from=ghcr.io/jaysonsantos/bunderwar:cargo-audit-0.17.4 /usr/local/bin/cargo-audit /usr/local/bin/
COPY --from=ghcr.io/jaysonsantos/bunderwar:sqlx-cli-0.6.2 /usr/local/bin/ /usr/local/bin/
COPY --from=ghcr.io/jaysonsantos/bunderwar:cargo-zigbuild-0.16.3 /usr/local/bin/ /usr/local/bin/

ARG UID=1000
RUN useradd --create-home --uid $UID code
USER code
