# renovate datasource=docker depName=alpine
ARG PROJECT_VERSION=3.23.4
ARG PROJECT_NAME=alpine
ARG TARGETPLATFORM

FROM ${PROJECT_NAME}:${PROJECT_VERSION}

LABEL org.opencontainers.image.title="reverse-proxy" \
      org.opencontainers.image.description="SSH-based reverse proxy for secure tunneling and port forwarding" \
      org.opencontainers.image.source="https://github.com/jaysonsantos/bunderwar"

RUN apk add -U openssh openssh-server bash autossh

COPY reverse-proxy.sh /
CMD ["bash", "-x", "/reverse-proxy.sh"]
