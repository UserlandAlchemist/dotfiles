#!/bin/bash
set -eu

HOME=/home/alchemist
export HOME

REPO="ssh://borg@astute/srv/backups/audacious-borg"

KEY="$HOME/.ssh/audacious-backup"
PASSCMD="cat $HOME/.config/borg/passphrase"

# Sanity check (helps immediately if something is wrong)
: "${KEY:?}"
: "${PASSCMD:?}"

# Protected from idle shutdown by idle-shutdown.sh checking service status
# (systemd-inhibit doesn't work from user-context services)

# SSH options for non-interactive robustness
BORG_RSH="ssh -i $KEY -T -o BatchMode=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3"
export BORG_RSH
export BORG_PASSCOMMAND="$PASSCMD"

# Wake Astute
echo "Sending WOL to Astute..."
/usr/bin/wakeonlan "60:45:cb:9b:ab:3b"

# Wait for repo to be reachable (~60s)
echo "Waiting for repository to become available..."
i=0
while [ "$i" -lt 6 ]; do
  borg list "$REPO" >/dev/null 2>&1 && break
  i=$((i+1))
  sleep 10
done

if [ "$i" -lt 6 ]; then
  echo "Repository available, starting backup..."
else
  echo "ERROR: Astute not ready after WOL (60s timeout)" >&2
  exit 1
fi

# Backup (verbose output to journal)
echo "Creating backup archive..."
borg create \
  --verbose --stats --compression lz4 \
  --lock-wait 60 --one-file-system --checkpoint-interval 60 \
  --patterns-from "$HOME/.config/borg/patterns" \
  "$REPO"::'{hostname}-{now}'

echo "Pruning old archives..."
borg prune --list \
  --keep-daily 7 \
  "$REPO"

echo "Compacting repository..."
borg compact "$REPO"

echo "Backup completed successfully"
