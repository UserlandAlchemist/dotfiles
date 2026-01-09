#!/bin/sh
set -eu

REPO="ssh://j31cxd2v@j31cxd2v.repo.borgbase.com/./repo"
SRC="/home/alchemist"
PATTERNS="/home/alchemist/.config/borg/patterns"
KEY="/root/.ssh/borgbase-offsite-audacious"
PASSFILE="/root/.config/borg-offsite/audacious-home.passphrase"

BORG_BASE_DIR="/var/lib/borg-offsite/audacious-home"
BORG_CONFIG_DIR="$BORG_BASE_DIR/config"
BORG_SECURITY_DIR="$BORG_BASE_DIR/security"
BORG_CACHE_DIR="/var/cache/borg-offsite/audacious-home"

export BORG_RSH="ssh -i $KEY -T -o IdentitiesOnly=yes -o BatchMode=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3"
export BORG_PASSCOMMAND="cat $PASSFILE"
export BORG_BASE_DIR BORG_CONFIG_DIR BORG_SECURITY_DIR BORG_CACHE_DIR

if [ ! -d "$SRC" ]; then
  echo "ERROR: missing source directory: $SRC" >&2
  exit 1
fi

if [ ! -f "$PATTERNS" ]; then
  echo "ERROR: missing Borg patterns file: $PATTERNS" >&2
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
  --lock-wait 60 --one-file-system \
  --patterns-from "$PATTERNS" \
  "${REPO}::audacious-home-{now}"

# Note: This repo should use append-only access in BorgBase for ransomware protection.
# Prune operations are disabled - manage retention manually via BorgBase web UI.
# Compaction is handled server-side by BorgBase.

echo "Backup completed successfully"
