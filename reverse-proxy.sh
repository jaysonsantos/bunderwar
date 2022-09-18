#!/bin/bash
set -eo pipefail

verify() {
    local valid=0
    for var in REMOTE_SSH_HOST REMOTE_SSH_PORT  REMOTE_SSH_USER LOCAL_SSH_KEY AUTHORIZED_KEYS; do
        local value="${!var}"
        if [ -z "$value" ]; then
            echo "$var must be set"
            valid=1
        fi
    done
    return $valid
}

setup_files() {
    mkdir -p ~/.ssh
    ssh-keyscan -p "$REMOTE_SSH_PORT" "$REMOTE_SSH_HOST" > ~/.ssh/known_hosts
    echo "$LOCAL_SSH_KEY" > ~/.ssh/private
    chmod 400 ~/.ssh/private
    echo "$AUTHORIZED_KEYS" > ~/.ssh/authorized_keys
}

run_agent() {
    eval "$(ssh-agent)"
    ssh-add ~/.ssh/private
}

run_tunnel() {
    AUTOSSH_LOGFILE=/tmp/debug autossh -f -M 9999:22 -N -R 0.0.0.0:12439:localhost:22 -p "$REMOTE_SSH_PORT" "$REMOTE_SSH_USER@$REMOTE_SSH_HOST"
}

run_sshd() {
    ssh-keygen -A
    $(which sshd) -De
}

quit() {
    echo "Bye"
    killall -INT sshd
}

main() {
    trap quit SIGINT
    echo "Verifying requisites"
    verify
    setup_files
    run_agent
    echo "Starting reverse tunnel in background"
    run_tunnel
    echo "Starting sshd"
    run_sshd
}

main