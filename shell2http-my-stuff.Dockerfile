# renovate datasource=docker depName=msoap/shell2http
ARG SHELL2HTTP_VERSION=1.17.0

FROM msoap/shell2http:${SHELL2HTTP_VERSION}

RUN apk add -U \
    ocrmypdf \
    tesseract-ocr-data-deu \
    tesseract-ocr-data-eng \
    tesseract-ocr-data-osd \
    tesseract-ocr-data-por \
    ffmpeg \
    jo
