#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

function generate_password() {
    # We disable exit on error because we close the pipe
    # when we have enough characters, which results in a
    # non-zero exit status
    set +e
    tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1 | tr -cd '[:alnum:]'
    set -e
}

DEVPI_ROOT_PASSWORD="${DEVPI_ROOT_PASSWORD:-}"
if [ -f "$DEVPI_SERVER_ROOT/.root_password" ]; then
    DEVPI_ROOT_PASSWORD=$(cat "$DEVPI_SERVER_ROOT/.root_password")
elif [ -z "$DEVPI_ROOT_PASSWORD" ]; then
    DEVPI_ROOT_PASSWORD=$(generate_password)
fi

if [ ! -d "$DEVPI_SERVER_ROOT" ]; then
    echo "ENTRYPOINT: Creating devpi-server root"
    mkdir -p "$DEVPI_SERVER_ROOT"
fi

if [ ! -f "$DEVPI_SERVER_ROOT/.serverversion" ]; then
    echo "ENTRYPOINT: Initializing server root $DEVPI_SERVER_ROOT"
    devpi-init --serverdir "$DEVPI_SERVER_ROOT"

    echo "ENTRYPOINT: Initializing devpi-server"
    devpi use http://localhost:3141
    devpi login root --password=''
    
    echo "ENTRYPOINT: Setting root password to $DEVPI_ROOT_PASSWORD"
    devpi user -m root "password=$DEVPI_ROOT_PASSWORD"
    echo -n "$DEVPI_ROOT_PASSWORD" > "$DEVPI_SERVER_ROOT/.root_password"
    devpi logoff
    
fi

echo "ENTRYPOINT: Starting devpi-server"
devpi-server --host 0.0.0.0 --port 3141 --serverdir "$DEVPI_SERVER_ROOT" "$@"


