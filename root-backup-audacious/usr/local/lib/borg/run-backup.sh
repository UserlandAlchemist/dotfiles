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

# Acquire inhibit lock to prevent shutdown during backup
# systemd-inhibit with 'cat' keeps the lock held until we kill it
systemd-inhibit --what=shutdown:sleep --who="borg-backup" --why="Backup in progress (Audacious → Astute)" cat > /dev/null &
INHIBIT_PID=$!

# Ensure we release the lock on exit (success or failure)
cleanup() {
    if [ -n "${INHIBIT_PID:-}" ] && kill -0 "$INHIBIT_PID" 2>/dev/null; then
        kill "$INHIBIT_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

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
  "$REPO"::"{hostname}-{now}"

echo "Pruning old archives..."
borg prune --list \
  --keep-last 2 \
  "$REPO"

echo "Compacting repository..."
borg compact
borg compact "$REPO"

echo "Backup completed successfully"
