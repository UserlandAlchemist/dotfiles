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

# --- NAS activity checks ---

# Check for active NFS server connections (port 2049)
if ss -tn state established '( sport = :2049 )' | grep -q .; then
    logger -t "$TAG" "Active NFS client connection(s) detected; skipping suspend"
    exit 0
fi

# Check for recent disk I/O on /srv/nas
NAS_PATH="/srv/nas"
IO_MARKER="/run/astute-nas-io"

# Initialise marker if missing
if [ ! -e "$IO_MARKER" ]; then
    touch "$IO_MARKER"
    exit 0
fi

# If anything under /srv/nas has been accessed since last check
if find "$NAS_PATH" -type f -newer "$IO_MARKER" -print -quit 2>/dev/null | grep -q .; then
    logger -t "$TAG" "Recent NAS disk activity detected; skipping suspend"
    touch "$IO_MARKER"
    exit 0
fi

# Update marker for next run
touch "$IO_MARKER"

# No sessions, no inhibitors — suspend
logger -t "$TAG" "System idle; suspending now"
systemctl suspend
