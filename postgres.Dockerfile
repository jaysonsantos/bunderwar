# syntax=docker/dockerfile:1.22-labs
ARG PLATFORMS=linux/amd64,linux/arm64

# renovate datasource=docker depName=postgres versioning=docker
ARG POSTGRES_VERSION=17.10

FROM postgres:${POSTGRES_VERSION}-bookworm

# Extra space-separated apt packages to bake in on top of the bundled
# extensions. The official image already configures the PGDG apt repo and
# exports PG_MAJOR, so any versioned extension package can be added, e.g.:
#   --build-arg EXTRA_EXTENSIONS="postgresql-17-cron postgresql-17-hll"
ARG EXTRA_EXTENSIONS=""

LABEL org.opencontainers.image.title="postgres" \
      org.opencontainers.image.description="PostgreSQL bundled with pgvector and PostGIS, with a drop-in mechanism to add more extensions" \
      org.opencontainers.image.source="https://github.com/jaysonsantos/bunderwar"

RUN set -eux; \
    apt-get update; \
    apt-get install --no-install-recommends -y \
        postgresql-${PG_MAJOR}-pgvector \
        postgresql-${PG_MAJOR}-postgis-3 \
        postgresql-${PG_MAJOR}-postgis-3-scripts \
        postgresql-${PG_MAJOR}-cron \
        postgresql-${PG_MAJOR}-timescaledb \
        postgresql-${PG_MAJOR}-pg-uuidv7 \
        postgresql-${PG_MAJOR}-pg-ivm \
        ${EXTRA_EXTENSIONS}; \
    rm -rf /var/lib/apt/lists/*

# Auto-create the extensions listed in POSTGRES_EXTENSIONS on first cluster init.
COPY --chmod=755 postgres/initdb/10-create-extensions.sh /docker-entrypoint-initdb.d/10-create-extensions.sh

# Comma- or space-separated list of extensions created when the cluster is first
# initialised. Override at runtime to enable a different set.
ENV POSTGRES_EXTENSIONS="vector,postgis,timescaledb,pg_cron,pg_uuidv7,pg_ivm"

# pg_cron and timescaledb must be loaded at server start, so preload them. The
# official entrypoint passes these same args to the temporary init server too,
# which is why CREATE EXTENSION works during first-init. pg_cron runs its
# background worker against cron.database_name (the default "postgres" db); if
# you set POSTGRES_DB to something else and want pg_cron there, also pass
# "-c cron.database_name=<db>".
CMD ["postgres", "-c", "shared_preload_libraries=timescaledb,pg_cron"]
