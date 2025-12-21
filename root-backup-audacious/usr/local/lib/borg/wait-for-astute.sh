#!/bin/sh
MAC="60:45:cb:9b:ab:3b"
REPO="ssh://borg@astute/srv/backups/audacious-borg"

KEY="$HOME/alchemist/.ssh/audacious-backup"
PASSCMD="cat $HOME/alchemist/.config/borg/passphrase"

# 1) Wake
/usr/bin/wakeonlan "$MAC"

# 2) Try for ~60 seconds (6 x 10s)
i=0
while [ $i -lt 6 ]; do
    BORG_RSH="ssh -i $KEY -T" \
    BORG_PASSCOMMAND="$PASSCMD" \
    borg list "$REPO" >/dev/null 2>&1 && exit 0
    i=$((i+1))
    sleep 10
done

echo "astute not ready after WOL" >&2
exit 1
