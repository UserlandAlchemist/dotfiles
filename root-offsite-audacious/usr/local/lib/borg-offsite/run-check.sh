#!/bin/sh
set -eu

REPO="ssh://j31cxd2v@j31cxd2v.repo.borgbase.com/./repo"
BASE="/var/lib/borg-offsite/audacious-home"
PASSFILE="/root/.config/borg-offsite/audacious-home.passphrase"
KEY="/root/.ssh/borgbase-offsite-audacious"

BORG_BASE_DIR="$BASE"
BORG_CONFIG_DIR="$BASE/config"
BORG_SECURITY_DIR="$BASE/security"
BORG_CACHE_DIR="/var/cache/borg-offsite/audacious-home"

export BORG_RSH="ssh -i $KEY -T -o IdentitiesOnly=yes -o BatchMode=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3"
export BORG_PASSCOMMAND="cat $PASSFILE"
export BORG_BASE_DIR BORG_CONFIG_DIR BORG_SECURITY_DIR BORG_CACHE_DIR

if [ ! -f "$PASSFILE" ]; then
  echo "ERROR: missing passphrase file: $PASSFILE" >&2
  exit 1
fi

mkdir -p "$BORG_CONFIG_DIR" "$BORG_SECURITY_DIR" "$BORG_CACHE_DIR"

echo "Checking audacious-home repository..."
borg check --lock-wait 60 "$REPO"
echo "✓ audacious-home: repository healthy"
