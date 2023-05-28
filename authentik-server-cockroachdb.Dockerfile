ARG AUTHENTIK_VERSION=2023.5.2
FROM ghcr.io/goauthentik/server:${AUTHENTIK_VERSION}
USER root
RUN pip install django-cockroachdb==$(python -c 'import django; v = list(django.VERSION); v[2] = "*"; print(".".join(str(p) for p in v[:3]))')
RUN sed -i'' 's/django_prometheus.db.backends.postgresql/django_cockroachdb/' authentik/root/settings.py
USER 1000
