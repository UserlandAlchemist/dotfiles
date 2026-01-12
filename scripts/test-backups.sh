#!/usr/bin/env bash
# Backup verification checks (requires root).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
WARNINGS=0
FAILURES=0

info() { printf '[INFO] %s\n' "$*"; }
warn() {
	printf '[WARN] %s\n' "$*" >&2
	WARNINGS=$((WARNINGS + 1))
}
error() {
	printf '[FAIL] %s\n' "$*" >&2
	FAILURES=$((FAILURES + 1))
}

if [ "$(id -u)" -ne 0 ]; then
	error "Run as root: sudo $0"
	exit 1
fi

cd "$ROOT"

BACKUP_USER="${BACKUP_USER:-alchemist}"
BACKUP_USER_HOME="${BACKUP_USER_HOME:-/home/${BACKUP_USER}}"

LOCAL_REPO="${LOCAL_REPO:-ssh://borg@astute/srv/backups/audacious-borg}"
LOCAL_KEY="${LOCAL_KEY:-${BACKUP_USER_HOME}/.ssh/audacious-backup}"
LOCAL_PASS="${LOCAL_PASS:-${BACKUP_USER_HOME}/.config/borg/passphrase}"
LOCAL_PATTERNS="${LOCAL_PATTERNS:-${BACKUP_USER_HOME}/.config/borg/patterns}"

OFFSITE_AUDACIOUS_REPO="${OFFSITE_AUDACIOUS_REPO:-ssh://j31cxd2v@j31cxd2v.repo.borgbase.com/./repo}"
OFFSITE_AUDACIOUS_KEY="${OFFSITE_AUDACIOUS_KEY:-/root/.ssh/borgbase-offsite-audacious}"
OFFSITE_AUDACIOUS_PASS="${OFFSITE_AUDACIOUS_PASS:-/root/.config/borg-offsite/audacious-home.passphrase}"

OFFSITE_ASTUTE_REPO="${OFFSITE_ASTUTE_REPO:-ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo}"
OFFSITE_ASTUTE_KEY="${OFFSITE_ASTUTE_KEY:-/root/.ssh/borgbase-offsite-astute}"
OFFSITE_ASTUTE_PASS="${OFFSITE_ASTUTE_PASS:-/root/.config/borg-offsite/astute-critical.passphrase}"

CHECK_LOCAL="${CHECK_LOCAL:-1}"
CHECK_OFFSITE="${CHECK_OFFSITE:-1}"
BACKUP_VERIFY_PATTERNS="${BACKUP_VERIFY_PATTERNS:-0}"

require_file() {
	local path=$1 label=$2
	if [ ! -f "$path" ]; then
		error "missing ${label}: ${path}"
		return 1
	fi
	return 0
}

run_as_user() {
	if command -v runuser >/dev/null 2>&1; then
		runuser -u "$BACKUP_USER" -- "$@"
		return $?
	fi
	error "runuser not available; cannot run user backup checks"
	return 1
}

if ! command -v borg >/dev/null 2>&1; then
	error "borg not installed; cannot run backup checks"
	exit 1
fi

info "Running backup checks from $ROOT"

if [ "$CHECK_LOCAL" != "0" ]; then
	local_ready=1
	require_file "$LOCAL_KEY" "local backup SSH key" || local_ready=0
	require_file "$LOCAL_PASS" "local backup passphrase" || local_ready=0
	require_file "$LOCAL_PATTERNS" "local backup patterns" || local_ready=0

	if [ "$local_ready" -eq 1 ]; then
		local_rsh="ssh -i $LOCAL_KEY -T -o BatchMode=yes -o IdentitiesOnly=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3"
		info "borg list (local repo)"
		if ! run_as_user env HOME="$BACKUP_USER_HOME" \
			BORG_RSH="$local_rsh" \
			BORG_PASSCOMMAND="cat $LOCAL_PASS" \
			borg list "$LOCAL_REPO" >/dev/null; then
			error "borg list failed for local repo"
		fi

		if [ "$BACKUP_VERIFY_PATTERNS" = "1" ]; then
			info "borg create --dry-run (local patterns)"
			if ! run_as_user env HOME="$BACKUP_USER_HOME" \
				BORG_RSH="$local_rsh" \
				BORG_PASSCOMMAND="cat $LOCAL_PASS" \
				borg create --dry-run --stats \
				--patterns-from "$LOCAL_PATTERNS" \
				"${LOCAL_REPO}::pattern-check-{now}" \
				"$BACKUP_USER_HOME" >/dev/null; then
				error "borg dry-run failed for local patterns"
			fi
		fi
	fi
else
	info "Skipping local backup checks (CHECK_LOCAL=0)"
fi

if [ "$CHECK_OFFSITE" != "0" ]; then
	offsite_ready=1
	require_file "$OFFSITE_AUDACIOUS_KEY" "offsite audacious-home SSH key" || offsite_ready=0
	require_file "$OFFSITE_AUDACIOUS_PASS" "offsite audacious-home passphrase" || offsite_ready=0
	require_file "$OFFSITE_ASTUTE_KEY" "offsite astute-critical SSH key" || offsite_ready=0
	require_file "$OFFSITE_ASTUTE_PASS" "offsite astute-critical passphrase" || offsite_ready=0

	if [ "$offsite_ready" -eq 1 ]; then
		offsite_rsh_audacious="ssh -i $OFFSITE_AUDACIOUS_KEY -T -o BatchMode=yes -o IdentitiesOnly=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3"
		offsite_rsh_astute="ssh -i $OFFSITE_ASTUTE_KEY -T -o BatchMode=yes -o IdentitiesOnly=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3"

		info "borg list (offsite audacious-home)"
		if ! BORG_RSH="$offsite_rsh_audacious" \
			BORG_PASSCOMMAND="cat $OFFSITE_AUDACIOUS_PASS" \
			borg list "$OFFSITE_AUDACIOUS_REPO" >/dev/null; then
			error "borg list failed for offsite audacious-home"
		fi

		info "borg list (offsite astute-critical)"
		if ! BORG_RSH="$offsite_rsh_astute" \
			BORG_PASSCOMMAND="cat $OFFSITE_ASTUTE_PASS" \
			borg list "$OFFSITE_ASTUTE_REPO" >/dev/null; then
			error "borg list failed for offsite astute-critical"
		fi
	fi
else
	info "Skipping offsite backup checks (CHECK_OFFSITE=0)"
fi

if [ "$FAILURES" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
	info "All backup checks passed"
	exit 0
fi

if [ "$WARNINGS" -gt 0 ]; then
	warn "Checks completed with $WARNINGS warning(s)"
fi
if [ "$FAILURES" -gt 0 ]; then
	error "Checks completed with $FAILURES failure(s)"
fi
exit $((FAILURES > 0))
