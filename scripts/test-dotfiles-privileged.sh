#!/usr/bin/env bash
# Privileged dotfiles regression checks (requires root).

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

info "Running privileged checks from $ROOT"

# Install script regression checks (host-specific)
if [ -x "$ROOT/scripts/test-install-scripts.sh" ]; then
	info "install script regression"
	if ! "$ROOT/scripts/test-install-scripts.sh"; then
		warn "install script regression reported failures"
	fi
else
	warn "missing scripts/test-install-scripts.sh; skipping install script checks"
fi

# systemd unit verification (installed units)
if command -v systemd-analyze >/dev/null 2>&1; then
	mapfile -t installed_units < <(find /etc/systemd/system -type f \( -name '*.service' -o -name '*.timer' -o -name '*.path' \))
	if [ "${#installed_units[@]}" -gt 0 ]; then
		info "systemd-analyze verify (/etc/systemd/system)"
		if ! SYSTEMD_PAGER=cat SYSTEMD_LOG_LEVEL=warning systemd-analyze verify "${installed_units[@]}"; then
			warn "systemd-analyze verify reported issues"
		fi
	fi
else
	warn "systemd-analyze not available; skipping installed unit verification"
fi

# Reload systemd to catch syntax errors early
if command -v systemctl >/dev/null 2>&1; then
	info "systemctl daemon-reload"
	if ! systemctl daemon-reload; then
		warn "systemctl daemon-reload failed"
	fi

	if systemctl --failed --no-legend --plain | grep -q .; then
		warn "systemctl reports failed units"
		systemctl --failed --no-legend --plain || true
	else
		info "systemctl reports no failed units"
	fi
else
	warn "systemctl not available; skipping daemon-reload check"
fi

# sudoers syntax (installed)
if command -v visudo >/dev/null 2>&1; then
	info "visudo -c"
	if ! visudo -c; then
		warn "visudo -c reported issues"
	fi
else
	warn "visudo not available; skipping sudoers syntax check"
fi

# nftables syntax (installed)
if command -v nft >/dev/null 2>&1; then
	if [ -f /etc/nftables.conf ]; then
		info "nft -c -f /etc/nftables.conf"
		if ! nft -c -f /etc/nftables.conf; then
			warn "nft -c failed for /etc/nftables.conf"
		fi
	else
		warn "/etc/nftables.conf missing; skipping nftables check"
	fi
else
	warn "nft not available; skipping nftables syntax check"
fi

if [ "$FAILURES" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
	info "All privileged checks passed"
	exit 0
fi

if [ "$WARNINGS" -gt 0 ]; then
	warn "Checks completed with $WARNINGS warning(s)"
fi
if [ "$FAILURES" -gt 0 ]; then
	error "Checks completed with $FAILURES failure(s)"
fi
exit $((FAILURES > 0))
