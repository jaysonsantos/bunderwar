# renovate datasource=docker depName=alpine
ARG PROJECT_VERSION=3.21.1
ARG PROJECT_NAME=alpine
ARG TARGETPLATFORM

FROM ${PROJECT_NAME}:${PROJECT_VERSION}

RUN apk add -U openssh openssh-server bash autossh

COPY reverse-proxy.sh /
CMD ["bash", "-x", "/reverse-proxy.sh"]
