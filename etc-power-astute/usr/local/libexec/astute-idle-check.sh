#!/bin/sh
set -eu

check_jellyfin_activity() {
    JELLYFIN_ACTIVE_WINDOW=1200
    JELLYFIN_API_KEY="$(cat /etc/jellyfin/api.key 2>/dev/null)" || return 0

    now=$(date +%s)

    curl -fsS \
      -H "X-Emby-Token: $JELLYFIN_API_KEY" \
      http://localhost:8096/Sessions \
    | jq -e --argjson now "$now" --argjson window "$JELLYFIN_ACTIVE_WINDOW" '
        .[]?
        | .LastActivityDate
        | sub("\\..*";"")
        | strptime("%Y-%m-%dT%H:%M:%S")
        | mktime
        | select($now - . <= $window)
    ' >/dev/null
}

TAG="astute-idle-check"
NAS_PATH="/srv/nas"
ACTIVITY_WINDOW=600   # 10 minutes
NOW=$(date +%s)


# Check for active login sessions
if [ -z "$ASTUTE_IGNORE_LOGIN_SESSIONS" ]; then
	if loginctl list-sessions --no-legend | grep -q .; then
    		logger -t "$TAG" "Active login session(s) detected; skipping suspend"
    		exit 0
	fi
fi

# Check for active inhibitors
if systemd-inhibit --list --no-legend | grep -q .; then
    logger -t "$TAG" "Active inhibitor(s) detected; skipping suspend"
    exit 0
fi

# --- NAS activity checks ---


# Find most recent filesystem activity (files or directories)
LAST_ACTIVITY=$(find "$NAS_PATH" -maxdepth 4 \
    -printf '%T@\n' 2>/dev/null | sort -nr | head -n1)

if [ -n "$LAST_ACTIVITY" ]; then
    LAST_ACTIVITY=${LAST_ACTIVITY%.*}
    if [ $((NOW - LAST_ACTIVITY)) -lt "$ACTIVITY_WINDOW" ]; then
        logger -t "$TAG" "Recent NAS filesystem activity detected; skipping suspend"
        exit 0
    fi
fi

if check_jellyfin_activity; then
    logger -t astute-idle-check "Jellyfin client active within last 20 minutes; skipping suspend"
    exit 0
fi

# No sessions, no inhibitors — suspend
logger -t "$TAG" "System idle; suspending now"
systemctl suspend
