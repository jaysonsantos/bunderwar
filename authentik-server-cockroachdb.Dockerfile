ARG AUTHENTIK_VERSION=2026.5.3
FROM ghcr.io/goauthentik/server:${AUTHENTIK_VERSION}

LABEL org.opencontainers.image.title="authentik-server-cockroachdb" \
      org.opencontainers.image.description="Authentik identity server with CockroachDB database backend support" \
      org.opencontainers.image.source="https://github.com/jaysonsantos/bunderwar"

USER root
RUN pip install django-cockroachdb==$(python -c 'import django; v = list(django.VERSION); v[2] = "*"; print(".".join(str(p) for p in v[:3]))')
RUN sed -i'' 's/django_prometheus.db.backends.postgresql/django_cockroachdb/' authentik/root/settings.py
USER 1000
