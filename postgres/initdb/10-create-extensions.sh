#!/usr/bin/env bash
# Create the extensions listed in POSTGRES_EXTENSIONS (comma- or space-separated)
# in the default database when the cluster is first initialised. Adding another
# extension is just a matter of installing its package (see EXTRA_EXTENSIONS in
# the Dockerfile) and listing it here or in POSTGRES_EXTENSIONS at runtime.
set -euo pipefail

extensions="${POSTGRES_EXTENSIONS:-}"
# Treat commas as separators and collapse to a clean, space-separated list.
extensions="${extensions//,/ }"

if [ -z "${extensions// /}" ]; then
    echo "POSTGRES_EXTENSIONS is empty, skipping extension creation"
    exit 0
fi

for ext in $extensions; do
    echo "Creating extension if not exists: ${ext}"
    psql -v ON_ERROR_STOP=1 \
        --username "$POSTGRES_USER" \
        --dbname "${POSTGRES_DB:-$POSTGRES_USER}" \
        -c "CREATE EXTENSION IF NOT EXISTS \"${ext}\";"
done
