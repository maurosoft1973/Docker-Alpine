#!/bin/sh

source /scripts/init-alpine.sh

# Se docker run passa un comando, esegui quello
if [ "$#" -gt 0 ]; then
    exec "$@"
fi

exec "${SHELL_TERMINAL:-/bin/sh}"
