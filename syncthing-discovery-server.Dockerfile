FROM alpine:3.23 as builder
ARG TARGETPLATFORM

# renovate datasource=github-tags depName=syncthing/discosrv
ENV DISCOVERY_VERSION v2.0.16
ENV BASE_URL https://github.com/syncthing/discosrv
WORKDIR /
RUN apk add -U curl
RUN arch=$(echo $TARGETPLATFORM | cut -d/ -f2) \
    && url="${BASE_URL}/releases/download/${DISCOVERY_VERSION}/stdiscosrv-linux-${arch}-${DISCOVERY_VERSION}.tar.gz" \
    && echo "Downloading $url" \
    && curl -sfLo stdiscosrv.tar.gz $url

RUN tar zxvf stdiscosrv.tar.gz --strip-components 1


FROM gcr.io/distroless/static
COPY --from=builder /stdiscosrv /usr/local/bin/

LABEL org.opencontainers.image.title="syncthing-discovery-server" \
      org.opencontainers.image.description="Global discovery server for Syncthing peer-to-peer file synchronization" \
      org.opencontainers.image.source="https://github.com/jaysonsantos/bunderwar"

CMD [ "/usr/local/bin/stdiscosrv" ]
