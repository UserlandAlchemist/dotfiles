#!/bin/sh
# Wrapper to load Borg environment (systemd-style env file) for manual use

set -e

# Read each non-empty, non-comment line and export it
while IFS='=' read -r key value; do
    case "$key" in
        ''|\#*) continue ;;    # skip blanks/comments
    esac
    export "$key=$value"
done < /home/alchemist/.config/borg/env

# Now run whatever was passed (e.g. borg list)
exec "$@"
