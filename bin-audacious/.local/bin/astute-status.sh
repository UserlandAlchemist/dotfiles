#!/bin/sh

ASTUTE_IP="192.168.1.154"
ASTUTE_MAC="60:45:cb:9b:ab:3b"
ASTUTE_PORT=22
STATE_FILE="/tmp/astute-waking"

# TCP probe: succeeds only if Astute is fully awake
probe() {
  timeout 1 sh -c "</dev/tcp/$ASTUTE_IP/$ASTUTE_PORT" >/dev/null 2>&1
}

case "$1" in
  click)
    # Send a single Wake-on-LAN packet and mark as waking
    wakeonlan "$ASTUTE_MAC" >/dev/null 2>&1
    touch "$STATE_FILE"
    exit 0
    ;;
esac

if probe; then
  # Awake
  rm -f "$STATE_FILE"
  echo " astute"
elif [ -f "$STATE_FILE" ]; then
  # Waking
  echo " astute"
else
  # Asleep
  echo " astute"
fi

