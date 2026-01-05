#!/usr/bin/env bash
set -euo pipefail

title="Cold Storage Backup"
body="Mount /mnt/cold-storage and run cold-storage-backup.sh (monthly)."

if command -v notify-send >/dev/null 2>&1; then
  notify-send -u normal "${title}" "${body}"
else
  echo "${title}: ${body}"
fi
