# This is just my rebuild because I always have a fixed user and password and running on k8s makes it move the files and chown all the time
# renovate datasource=github-releases depName=linuxserver/docker-homeassistant
ARG HOMEASSISTANT_VERSION=2025.5.1-ls104
FROM lscr.io/linuxserver/homeassistant:${HOMEASSISTANT_VERSION}
RUN set -x && \
    BK="$(find /usr/local/lib -name '*.bak' -maxdepth 1)" && \
    NEW="${BK/.bak/}" && \
    mv "$BK" "${NEW}" && \
    chown -R 501:1000 "${NEW}" && \
    sed -i'' 's/lsiown/# lsiown/g' /etc/s6-overlay/s6-rc.d/init-config-homeassistant/run && \
    sed -i'' 's/ \/config/# \config/g' /etc/s6-overlay/s6-rc.d/init-config-homeassistant/run
