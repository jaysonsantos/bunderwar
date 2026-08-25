# Image version is independent from the upstream shell2http dependency version.
ARG IMAGE_VERSION=1.17.1
# renovate datasource=docker depName=msoap/shell2http
ARG SHELL2HTTP_VERSION=1.17.0
# renovate datasource=github-releases depName=astral-sh/uv
ARG UV_VERSION=0.12.6

FROM msoap/shell2http:${SHELL2HTTP_VERSION}

LABEL org.opencontainers.image.title="shell2http-my-stuff" \
      org.opencontainers.image.description="HTTP server exposing shell scripts with OCR, ffmpeg and multimedia tools" \
      org.opencontainers.image.source="https://github.com/jaysonsantos/bunderwar"

RUN apk add -U \
    ocrmypdf \
    tesseract-ocr-data-deu \
    tesseract-ocr-data-eng \
    tesseract-ocr-data-osd \
    tesseract-ocr-data-por \
    ffmpeg \
    jo \
    file \
    curl \
    tini \
 && curl -LsSf "https://astral.sh/uv/${UV_VERSION}/install.sh" \
    | env UV_UNMANAGED_INSTALL=/usr/local/bin sh

ENTRYPOINT ["/sbin/tini", "--", "/app/shell2http"]

# Rebuild trigger for annotation support
