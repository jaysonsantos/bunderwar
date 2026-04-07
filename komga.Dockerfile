# syntax=docker/dockerfile:1
# renovate datasource=github-releases depName=gotson/komga
ARG KOMGA_VERSION=1.24.3
# renovate datasource=github-releases depName=rclone/rclone
ARG RCLONE_VERSION=1.73.3
FROM ghcr.io/gotson/komga:${KOMGA_VERSION} AS komga

FROM rclone/rclone:${RCLONE_VERSION} AS rclone

FROM lscr.io/linuxserver/baseimage-ubuntu:noble

LABEL org.opencontainers.image.title="komga" \
      org.opencontainers.image.description="Komga on LinuxServer Ubuntu base image with an optional s6-managed rclone Google Drive mount" \
      org.opencontainers.image.source="https://github.com/jaysonsantos/bunderwar"

ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"
ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/lib/aarch64-linux-gnu
ENV KOMGA_CONFIGDIR=/config
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV RCLONE_MOUNT_ENABLED=false
ENV RCLONE_CONFIG_FILE=/config/rclone/rclone.conf
ENV RCLONE_REMOTE=
ENV RCLONE_MOUNT_PATH=/data/gdrive
ENV RCLONE_CACHE_DIR=/config/cache/rclone
ENV RCLONE_EXTRA_ARGS=

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        fuse3 \
        libarchive-dev \
        libheif-dev \
        libjxl-dev \
        libwebp-dev \
        locales; \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen; \
    locale-gen en_US.UTF-8; \
    echo "user_allow_other" >> /etc/fuse.conf; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

COPY --from=komga /opt/java/openjdk /opt/java/openjdk
COPY --from=komga /usr/bin/kepubify /usr/bin/kepubify
COPY --from=komga /app /app
COPY --from=rclone /usr/local/bin/rclone /usr/bin/rclone
COPY komga/root/ /

RUN set -eux; \
    chmod +x \
        /etc/s6-overlay/s6-rc.d/svc-komga/run \
        /etc/s6-overlay/s6-rc.d/svc-rclone/run; \
    mkdir -p /config /data /defaults

WORKDIR /app
VOLUME /config
VOLUME /data
EXPOSE 25600
