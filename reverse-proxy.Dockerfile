FROM alpine:3.16.2

RUN apk add -U openssh openssh-server bash autossh

COPY reverse-proxy.sh /
CMD ["/reverse-proxy.sh"]
