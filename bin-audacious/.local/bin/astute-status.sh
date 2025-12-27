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
    if probe; then
      # Astute is up - schedule idle check to run in 3 seconds via systemd-run
      # This runs outside any SSH session context, avoiding false session detection
      ssh -o BatchMode=yes -o ConnectTimeout=2 astute \
        'systemd-run --user --on-active=3s --unit=idle-check-manual sudo /usr/local/libexec/astute-idle-check.sh' >/dev/null 2>&1

      # Check result after 5 seconds
      (
        sleep 5
        if probe; then
          notify-send -a "Astute" "" "Astute stayed awake"
        else
          notify-send -a "Astute" "" "Astute went to sleep"
        fi
      ) &
    else
      # Astute is down - send WOL
      wakeonlan "$ASTUTE_MAC" >/dev/null 2>&1
      touch "$STATE_FILE"
      notify-send -a "Astute" "" "Waking Astute..."
    fi
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
