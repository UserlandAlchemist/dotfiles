#!/bin/sh
set -eu

REPO="ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo"
PATTERNS="/etc/borg-offsite/astute-critical.patterns"
KEY="/root/.ssh/borgbase_offsite"
PASSFILE="/root/.config/borg-offsite/astute-critical.passphrase"

BORG_BASE_DIR="/var/lib/borg-offsite/astute-critical"
BORG_CONFIG_DIR="$BORG_BASE_DIR/config"
BORG_SECURITY_DIR="$BORG_BASE_DIR/security"
BORG_CACHE_DIR="/var/cache/borg-offsite/astute-critical"

export BORG_RSH="ssh -i $KEY -T -o BatchMode=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3"
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

if [ ! -f "$PATTERNS" ]; then
  echo "ERROR: missing patterns file: $PATTERNS" >&2
  exit 1
fi

mkdir -p "$BORG_CONFIG_DIR" "$BORG_SECURITY_DIR" "$BORG_CACHE_DIR"

borg create \
  --verbose --stats --progress --checkpoint-interval 60 --compression lz4 \
  --lock-wait 60 \
  --patterns-from "$PATTERNS" \
  "$REPO"::"astute-critical-{now}" \
  /
