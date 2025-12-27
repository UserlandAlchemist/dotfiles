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
      # Astute is up - show immediate feedback, then run check
      notify-send -a "Astute" "" "Checking Astute status..."

      # Non-interactive SSH doesn't create TTY session, won't interfere with check
      MSG=$(ssh -o BatchMode=yes -o ConnectTimeout=2 astute \
        'sudo /usr/local/libexec/astute-idle-check.sh' 2>/dev/null)

      if [ -n "$MSG" ]; then
        # Astute stayed awake - show the reason
        notify-send -a "Astute" "" "$MSG"
      else
        # No output means it suspended
        notify-send -a "Astute" "" "Astute going to sleep - idle"
      fi
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
