#!/bin/sh
set -eu

HOME=/home/alchemist
export HOME

REPO="ssh://borg@astute/srv/backups/audacious-borg"
KEY="$HOME/.ssh/audacious-backup"
PASSCMD="cat $HOME/.config/borg/passphrase"

BORG_RSH="ssh -i $KEY -T -o BatchMode=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3"
export BORG_RSH
export BORG_PASSCOMMAND="$PASSCMD"

echo "Starting Borg deep check at $(date)"

borg check \
  --verify-data \
  --progress \
  "$REPO"

echo "Completed Borg deep check at $(date)"
