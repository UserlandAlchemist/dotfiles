#!/bin/sh
set -eu

HOME=/home/alchemist
export HOME

REPO="ssh://borg@astute/srv/backups/audacious-borg"

KEY="$HOME/.ssh/audacious-backup"
PASSCMD="cat $HOME/.config/borg/passphrase"

# Sanity check (helps immediately if something is wrong)
: "${KEY:?}"
: "${PASSCMD:?}"

# SSH options for non-interactive robustness
BORG_RSH="ssh -i $KEY -T -o BatchMode=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3"
export BORG_RSH
export BORG_PASSCOMMAND="$PASSCMD"

# Wake Astute
/usr/bin/wakeonlan "60:45:cb:9b:ab:3b"

# Wait for repo to be reachable (~60s)
i=0
while [ "$i" -lt 6 ]; do
  borg list "$REPO" >/dev/null 2>&1 && break
  i=$((i+1))
  sleep 10
done

[ "$i" -lt 6 ] || { echo "Astute not ready after WOL" >&2; exit 1; }

# Backup (progress visible in journal)
borg create \
  --progress \
  --verbose --stats --compression lz4 \
  --lock-wait 60 --one-file-system --checkpoint-interval 60 \
  --patterns-from "$HOME/.config/borg/patterns" \
  "$REPO"::"{hostname}-{now}"

borg prune --list \
  --keep-within 3d \
  --keep-daily 7 \
  --keep-weekly 52

borg compact
