#!/bin/sh

ASTUTE_IP="192.168.1.154"
ASTUTE_MAC="60:45:cb:9b:ab:3b"
ASTUTE_PORT=22
STATE_FILE="/tmp/astute-waking"

# TCP probe: succeeds only if Astute is fully awake
probe() {
  ping -c1 -W1 -q "$ASTUTE_IP" 2>/dev/null | grep -q "1 received"
}

underline() {
  printf "<span underline=\"single\" underline_color=\"%s\">%s</span>\n" "$1" "$2"
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
  underline "#FFDC40" "SRV UP"
elif [ -f "$STATE_FILE" ]; then
  # Waking
  underline "#FFFFFF" "SRV WAKING"
else
  # Asleep
  underline "#5078FF" "SRV ZZZ"
fi
