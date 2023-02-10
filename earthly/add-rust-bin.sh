#!/usr/bin/env bash
set -eo pipefail
mapfile -d '' TEMPLATE <<'EOF'
VERSION --shell-out-anywhere 0.6

# renovate datasource=crate depName=😀crate
ARG CRATE_VERSION=😀version
ARG CRATE_NAME=😀crate

IMPORT ../rust-binaries

all:
    BUILD rust-binaries+all --CRATE_VERSION=$CRATE_VERSION --CRATE_NAME=$CRATE_NAME

EOF

main() {
    local crate="$1"
    if [ -z "$crate" ]; then
        help
    fi
    local version
    version="$(latest_version "$1")"
    if [ -z "$version" ]; then
        echo "Failed to find version for crate $crate"
        exit 1
    fi
    local folder="$PWD/$crate"
    local earthfile="$folder/Earthfile"
    echo "Creating $earthfile with version $version"
    mkdir -p "$folder"
    echo "${TEMPLATE[@]}" | crate="$crate" version="$version" envsubst -d "😀" -o "$earthfile"

}

help() {
    echo "Usage: $0 crate-name"
    exit 1
}

latest_version() {
    local crate="$1"
    curl -sL \
        "https://crates.io/api/v1/crates/${crate}" \
        -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' -H 'TE: trailers' |
        jq '.versions[].num' -r | sort -V | tail -n 1
}

main "$@"
