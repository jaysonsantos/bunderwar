# syntax=docker/dockerfile:1.17-labs

FROM --platform=linux/amd64 golang:1.25-alpine as builder
ARG TARGETPLATFORM

# renovate datasource=github-tags depName=OT-CONTAINER-KIT/redis-operator
ENV OPERATOR_VERSION v0.21.0
ENV BASE_URL https://github.com/OT-CONTAINER-KIT/redis-operator
WORKDIR /build
RUN <<-EOF
    set -ex
    apk add -U curl
    arch=$(echo $TARGETPLATFORM | cut -d/ -f2)
    curl -sLo operator.tar.gz "${BASE_URL}/archive/refs/tags/${OPERATOR_VERSION}.tar.gz"
    tar zxvf operator.tar.gz --strip-components=1
    rm operator.tar.gz
    CGO_ENABLED=0 GOOS=linux GOARCH=$arch go build -a -o ${TARGETPLATFORM}/manager main.go
EOF

FROM gcr.io/distroless/static:nonroot
ARG TARGETPLATFORM
COPY --from=builder --chmod=755 /build/${TARGETPLATFORM}/manager /

CMD [ "/manager" ]
