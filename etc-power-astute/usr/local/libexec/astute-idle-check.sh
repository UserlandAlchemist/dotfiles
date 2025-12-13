#!/bin/sh
set -eu

TAG="astute-idle-check"

# Check for active login sessions
if loginctl list-sessions --no-legend | grep -q .; then
    logger -t "$TAG" "Active login session(s) detected; skipping suspend"
    exit 0
fi

# Check for active inhibitors
if systemd-inhibit --list --no-legend | grep -q .; then
    logger -t "$TAG" "Active inhibitor(s) detected; skipping suspend"
    exit 0
fi

# No sessions, no inhibitors — suspend
logger -t "$TAG" "System idle; suspending now"
systemctl suspend

