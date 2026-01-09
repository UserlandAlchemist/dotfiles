#!/bin/sh
set -eu

REPO="ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo"
SRC1="/srv/nas/lucii"
SRC2="/srv/nas/bitwarden-exports"
KEY="/root/.ssh/borgbase-offsite-astute"
PASSFILE="/root/.config/borg-offsite/astute-critical.passphrase"

BORG_BASE_DIR="/var/lib/borg-offsite/astute-critical"
BORG_CONFIG_DIR="$BORG_BASE_DIR/config"
BORG_SECURITY_DIR="$BORG_BASE_DIR/security"
BORG_CACHE_DIR="/var/cache/borg-offsite/astute-critical"

export BORG_RSH="ssh -i $KEY -T -o IdentitiesOnly=yes -o BatchMode=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3"
export BORG_PASSCOMMAND="cat $PASSFILE"
export BORG_BASE_DIR BORG_CONFIG_DIR BORG_SECURITY_DIR BORG_CACHE_DIR

if [ ! -f "$KEY" ]; then
  echo "ERROR: missing BorgBase SSH key: $KEY" >&2
  exit 1
fi

if [ ! -f "$PASSFILE" ]; then
  echo "ERROR: missing passphrase file: $PASSFILE" >&2
  exit 1
fi

if [ ! -d "$SRC1" ]; then
  echo "ERROR: missing source directory: $SRC1" >&2
  exit 1
fi

# SRC2 may not exist yet (bitwarden-exports), allow backup to proceed
if [ ! -d "$SRC2" ]; then
  echo "WARNING: $SRC2 does not exist, skipping" >&2
fi

mkdir -p "$BORG_CONFIG_DIR" "$BORG_SECURITY_DIR" "$BORG_CACHE_DIR"

# Backup sources (SRC2 optional if not exists)
if [ -d "$SRC2" ]; then
 borg create \
  --verbose --stats --progress --checkpoint-interval 60 --compression lz4 \
  --lock-wait 60 \
  "$REPO"::'astute-critical-{now}' \
  "$SRC1" "$SRC2"
else
 borg create \
  --verbose --stats --progress --checkpoint-interval 60 --compression lz4 \
  --lock-wait 60 \
  "$REPO"::'astute-critical-{now}' \
  "$SRC1"
fi

# Note: No prune/compact for append-only access (BorgBase manages compaction)
