#!/bin/sh
set -eu

REPO="ssh://j6i5cke1@j6i5cke1.repo.borgbase.com/./repo"
SRC="/srv/backups/audacious-borg"
KEY="/root/.ssh/borgbase_offsite"
PASSFILE="/root/.config/borg-offsite/audacious-home.passphrase"

BORG_BASE_DIR="/var/lib/borg-offsite/audacious-home"
BORG_CONFIG_DIR="$BORG_BASE_DIR/config"
BORG_SECURITY_DIR="$BORG_BASE_DIR/security"
BORG_CACHE_DIR="/var/cache/borg-offsite/audacious-home"

export BORG_RSH="ssh -i $KEY -T -o BatchMode=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3"
export BORG_PASSCOMMAND="cat $PASSFILE"
export BORG_BASE_DIR BORG_CONFIG_DIR BORG_SECURITY_DIR BORG_CACHE_DIR

if [ ! -d "$SRC" ]; then
  echo "ERROR: missing source directory: $SRC" >&2
  exit 1
fi

if [ ! -f "$KEY" ]; then
  echo "ERROR: missing BorgBase SSH key: $KEY" >&2
  exit 1
fi

if [ ! -f "$PASSFILE" ]; then
  echo "ERROR: missing passphrase file: $PASSFILE" >&2
  exit 1
fi

mkdir -p "$BORG_CONFIG_DIR" "$BORG_SECURITY_DIR" "$BORG_CACHE_DIR"

borg create \
  --verbose --stats --progress --checkpoint-interval 60 --compression lz4 \
  --lock-wait 60 \
  "$REPO"::"audacious-home-{now}" \
  "$SRC"

# Prune old archives (non-fatal - BorgBase may restrict or handle retention themselves)
echo "Attempting to prune old archives..."
borg prune --list --keep-daily 30 "$REPO" || {
  echo "WARNING: Prune operation failed or not supported by BorgBase" >&2
  echo "Archive created successfully, but client-side retention not enforced" >&2
  true  # Don't fail the backup
}

# Note: BorgBase handles compaction server-side; client compact not supported
# borg compact "$REPO"
