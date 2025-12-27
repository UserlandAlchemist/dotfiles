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
      # Astute is up - trigger background idle check (SSH session closes immediately)
      # The backgrounded check runs after a delay, allowing the SSH session to close
      ssh -o BatchMode=yes -o ConnectTimeout=2 astute \
        'nohup sh -c "sleep 3; sudo /usr/local/libexec/astute-idle-check.sh" >/tmp/idle-check.log 2>&1 &' 2>/dev/null
      notify-send -a "Astute" "" "Checking if Astute is idle..."

      # Check result after 5 seconds and notify
      (
        sleep 5
        if probe; then
          # Still up - read the result from log
          MSG=$(ssh -o BatchMode=yes -o ConnectTimeout=2 astute \
            'tail -n1 /tmp/idle-check.log 2>/dev/null' 2>/dev/null | grep -E '^Astute')
          [ -n "$MSG" ] && notify-send -a "Astute" "" "$MSG"
        else
          # Went to sleep
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
