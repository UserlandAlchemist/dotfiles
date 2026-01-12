#!/usr/bin/env bash

# Fast proxy detection for apt-cacher-ng on astute.
PROXY_HOST="192.168.1.154"
PROXY_PORT="3142"
PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"

if command -v ping >/dev/null 2>&1; then
	if ping -c1 -W1 "$PROXY_HOST" >/dev/null 2>&1; then
		printf '%s\n' "$PROXY_URL"
		exit 0
	fi
fi

if command -v timeout >/dev/null 2>&1 && command -v bash >/dev/null 2>&1; then
	if timeout 1 bash -c "exec 3<>/dev/tcp/${PROXY_HOST}/${PROXY_PORT}" >/dev/null 2>&1; then
		printf '%s\n' "$PROXY_URL"
		exit 0
	fi
fi

printf 'DIRECT\n'
exit 0
