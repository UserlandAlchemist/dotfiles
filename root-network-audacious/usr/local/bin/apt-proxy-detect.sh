#!/usr/bin/env bash
set -euo pipefail

# Fast proxy detection for apt-cacher-ng on astute.
PROXY_HOST="192.168.1.154"
PROXY_PORT="3142"
PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"

if ping -c1 -W1 "$PROXY_HOST" >/dev/null 2>&1; then
  echo "$PROXY_URL"
else
  echo "DIRECT"
fi
