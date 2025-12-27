#!/bin/sh
HOST="borg@astute"
MAC="60:45:cb:9b:ab:3b"
REPO="ssh://borg@astute/srv/backups/audacious-borg"

KEY="$HOME/.ssh/audacious-backup"
PASSCMD="cat $HOME/.config/borg/passphrase"

# Quick check if already reachable before sending WOL
if ssh -o BatchMode=yes -o ConnectTimeout=2 -i "$KEY" "$HOST" true >/dev/null 2>&1; then
    logger -t borg-backup "astute already reachable, skipping WOL"
    exit 0
fi

# Host is down, send WOL
logger -t borg-backup "Sending WOL to astute"
/usr/bin/wakeonlan "$MAC"

# Try for ~60 seconds (6 x 10s) with borg list check
export BORG_RSH="ssh -i $KEY -T -o BatchMode=yes -o ConnectTimeout=5"
export BORG_PASSCOMMAND="$PASSCMD"
export BORG_NONINTERACTIVE=1

i=0
while [ $i -lt 6 ]; do
    if borg list "$REPO" >/dev/null 2>&1; then
        logger -t borg-backup "astute responded after $((i * 10))s"
        exit 0
    fi
    i=$((i+1))
    sleep 10
done

echo "astute not ready after WOL (60s timeout)" >&2
logger -t borg-backup "WARNING: astute timeout after WOL"
exit 1
