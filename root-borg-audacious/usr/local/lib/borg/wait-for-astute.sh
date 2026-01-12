#!/bin/sh
ASTUTE_IP="192.168.1.154"
MAC="60:45:cb:9b:ab:3b"
WAKEONLAN_BIN="${WAKEONLAN_BIN:-/usr/bin/wakeonlan}"

# Quick ping check if already reachable before sending WOL
if ping -c1 -W1 -q "$ASTUTE_IP" >/dev/null 2>&1; then
    logger -t borg-backup "astute already reachable, skipping WOL"
    exit 0
fi

# Host is down, send WOL
logger -t borg-backup "Sending WOL to astute"
"$WAKEONLAN_BIN" "$MAC"

# Wait for astute to respond to ping (check every 2s for up to 60s)
i=0
while [ $i -lt 30 ]; do
    if ping -c1 -W1 -q "$ASTUTE_IP" >/dev/null 2>&1; then
        logger -t borg-backup "astute responded to ping after $((i * 2))s"
        exit 0
    fi
    i=$((i+1))
    sleep 2
done

echo "astute not ready after WOL (60s timeout)" >&2
logger -t borg-backup "WARNING: astute timeout after WOL"
exit 1
