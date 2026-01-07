#!/bin/sh
set -eu

check_repo() {
  REPO="$1"
  BASE="$2"
  PASSFILE="$3"
  KEY="/root/.ssh/borgbase_offsite"

  BORG_BASE_DIR="$BASE"
  BORG_CONFIG_DIR="$BASE/config"
  BORG_SECURITY_DIR="$BASE/security"
  BORG_CACHE_DIR="/var/cache/borg-offsite/$(basename "$BASE")"

  export BORG_RSH="ssh -i $KEY -T -o BatchMode=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3"
  export BORG_PASSCOMMAND="cat $PASSFILE"
  export BORG_BASE_DIR BORG_CONFIG_DIR BORG_SECURITY_DIR BORG_CACHE_DIR

  if [ ! -f "$PASSFILE" ]; then
    echo "ERROR: missing passphrase file: $PASSFILE" >&2
    exit 1
  fi

  mkdir -p "$BORG_CONFIG_DIR" "$BORG_SECURITY_DIR" "$BORG_CACHE_DIR"

  borg check --lock-wait 60 "$REPO"
}

check_repo \
  "ssh://j6i5cke1@j6i5cke1.repo.borgbase.com/./repo" \
  "/var/lib/borg-offsite/audacious-home" \
  "/root/.config/borg-offsite/audacious-home.passphrase"

check_repo \
  "ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo" \
  "/var/lib/borg-offsite/astute-critical" \
  "/root/.config/borg-offsite/astute-critical.passphrase"
