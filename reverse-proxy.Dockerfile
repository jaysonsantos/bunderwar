# renovate datasource=docker depName=alpine
ARG PROJECT_VERSION=3.16.2
ARG PROJECT_NAME=alpine

FROM ${PROJECT_NAME}:${PROJECT_VERSION}

RUN apk add -U openssh openssh-server bash autossh

COPY reverse-proxy.sh /
CMD ["/reverse-proxy.sh"]
