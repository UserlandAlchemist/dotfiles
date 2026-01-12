#!/bin/bash
set -eu

# Log all output directly to the journal.
{
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting backup service"
	/usr/local/lib/borg/run-backup.sh
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup service completed"
} 2>&1 | systemd-cat -t borg-backup
