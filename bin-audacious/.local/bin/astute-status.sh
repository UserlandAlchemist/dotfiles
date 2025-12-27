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
      # Astute is up - trigger idle check via systemd (won't create user session)
      notify-send -u low -a "Astute Sleep Control" "Idle Check" "Checking if Astute can sleep..."

      # Trigger the check via systemd service to avoid creating a user session
      ssh -o BatchMode=yes -o ConnectTimeout=2 astute \
        'sudo systemctl start astute-idle-suspend.service' 2>/dev/null

      # Brief wait for the check to complete
      sleep 2

      # Check if Astute is still up or went to sleep
      if probe; then
        # Still up - check journalctl for the reason
        MSG=$(ssh -o BatchMode=yes -o ConnectTimeout=2 astute \
          'sudo journalctl -u astute-idle-suspend.service -n 1 --output=cat' 2>/dev/null)
        if [ -n "$MSG" ]; then
          notify-send -a "Astute Sleep Control" "Staying Awake" "$MSG"
        fi
      else
        # Went to sleep
        notify-send -a "Astute Sleep Control" "Going to Sleep" "Astute is idle and suspending now"
      fi
    else
      # Astute is down - send WOL
      wakeonlan "$ASTUTE_MAC" >/dev/null 2>&1
      touch "$STATE_FILE"
      notify-send -u low -a "Astute Sleep Control" "Wake on LAN" "Sending magic packet to wake Astute..."
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
