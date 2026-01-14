#!/usr/bin/env bash
# Lightweight dotfiles regression checks (no sudo, no writes).

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

cd "$ROOT"

info "Running dotfiles checks from $ROOT"

# Shell linting
sh_files=()
while IFS= read -r f; do sh_files+=("$f"); done < <(rg --files --hidden --no-ignore-vcs -g '*.sh' -g '!.git/*')

if command -v shellcheck >/dev/null 2>&1; then
	if [ "${#sh_files[@]}" -gt 0 ]; then
		info "shellcheck (${#sh_files[@]} files)"
		if ! shellcheck "${sh_files[@]}"; then
			warn "shellcheck reported issues"
		fi
	else
		info "shellcheck: no shell scripts found"
	fi
else
	warn "shellcheck not installed; skipping shell lint"
	if [ "${#sh_files[@]}" -gt 0 ]; then
		info "bash -n sanity check (${#sh_files[@]} files)"
		for f in "${sh_files[@]}"; do
			if ! bash -n "$f"; then
				error "bash -n failed: $f"
			fi
		done
	fi
fi

# systemd unit verification (best-effort)
host="$(hostname -s 2>/dev/null || hostname)"
unit_dirs=()
case "$host" in
audacious | astute)
	unit_dirs=(root-*-"$host")
	;;
*)
	warn "unknown host '$host'; verifying all repo units"
	unit_dirs=(root-*)
	;;
esac
if [ "${#unit_dirs[@]}" -eq 0 ]; then
	warn "no unit directories found for host '$host'; verifying all repo units"
	unit_dirs=(root-*)
fi
unit_files=()
while IFS= read -r f; do unit_files+=("$f"); done < <(rg --files --hidden --no-ignore-vcs -g '*.service' -g '*.timer' -g '*.path' -g '!.git/*' "${unit_dirs[@]}")
if [ "${#unit_files[@]}" -gt 0 ]; then
	if command -v systemd-analyze >/dev/null 2>&1; then
		info "systemd-analyze verify (${#unit_files[@]} units)"
		verify_args=()
		if [ "$(id -u)" -ne 0 ]; then
			verify_args=(--generators=no)
		fi
		verify_output=""
		if ! verify_output=$(SYSTEMD_PAGER=cat SYSTEMD_LOG_LEVEL=warning systemd-analyze \
			"${verify_args[@]}" verify "${unit_files[@]}" 2>&1); then
			filtered_output="$(printf '%s\n' "$verify_output" | rg -v 'SO_PASSCRED failed' || true)"
			if [ -n "$filtered_output" ]; then
				printf '%s\n' "$filtered_output" >&2
				warn "systemd-analyze verify reported issues (see output above)"
			else
				info "systemd-analyze verify skipped (SO_PASSCRED not permitted)"
			fi
		elif [ -n "$verify_output" ]; then
			printf '%s\n' "$verify_output"
		fi
	else
		warn "systemd-analyze not available; skipping unit verification"
	fi
fi

# nftables syntax check (best-effort)
nft_files=()
while IFS= read -r f; do nft_files+=("$f"); done < <(rg --files --hidden --no-ignore-vcs -g 'nftables.conf' -g '!.git/*' root-*)
if [ "${#nft_files[@]}" -gt 0 ]; then
	if [ "$(id -u)" -ne 0 ]; then
		info "nftables syntax check requires root; run privileged checks"
	else
		nft_bin="$(command -v nft 2>/dev/null || true)"
		if [ -z "$nft_bin" ]; then
			for bin in /usr/local/sbin/nft /usr/sbin/nft /sbin/nft; do
				if [ -x "$bin" ]; then
					nft_bin="$bin"
					break
				fi
			done
		fi
		if [ -n "$nft_bin" ]; then
			info "nft -c check (${#nft_files[@]} files)"
			for f in "${nft_files[@]}"; do
				if ! "$nft_bin" -c -f "$f"; then
					warn "nft -c failed: $f"
				fi
			done
		else
			warn "nft not installed; skipping nftables syntax check"
		fi
	fi
fi

# sudoers syntax check (best-effort)
sudoers_files=()
while IFS= read -r f; do sudoers_files+=("$f"); done < <(rg --files --hidden --no-ignore-vcs -g '*.sudoers' -g '!.git/*' root-*)
if [ "${#sudoers_files[@]}" -gt 0 ]; then
	if [ "$(id -u)" -ne 0 ]; then
		info "sudoers syntax check requires root; run privileged checks"
	else
		visudo_bin="$(command -v visudo 2>/dev/null || true)"
		if [ -z "$visudo_bin" ]; then
			for bin in /usr/local/sbin/visudo /usr/sbin/visudo /sbin/visudo; do
				if [ -x "$bin" ]; then
					visudo_bin="$bin"
					break
				fi
			done
		fi
		if [ -n "$visudo_bin" ]; then
			info "visudo check (${#sudoers_files[@]} files)"
			for f in "${sudoers_files[@]}"; do
				if ! "$visudo_bin" -cf "$f"; then
					warn "visudo -cf failed: $f"
				fi
			done
		else
			warn "visudo not installed; skipping sudoers syntax check"
		fi
	fi
fi

# Documentation reference hygiene
if rg --quiet --hidden --no-ignore-vcs 'data-restore\\.md' docs; then
	error "Found stale reference to data-restore.md in docs/"
fi

# JSONC validation (best-effort)
jsonc_files=()
while IFS= read -r f; do jsonc_files+=("$f"); done < <(rg --files --hidden --no-ignore-vcs -g '*.jsonc' -g '!.git/*')
if [ "${#jsonc_files[@]}" -gt 0 ]; then
	if command -v python3 >/dev/null 2>&1; then
		info "jsonc parse (${#jsonc_files[@]} files)"
		for f in "${jsonc_files[@]}"; do
			if ! python3 - "$f" <<'PY'; then
import json
import sys

path = sys.argv[1]
data = open(path, "r", encoding="utf-8").read()
out = []
in_str = False
escape = False
in_line = False
in_block = False
i = 0
while i < len(data):
    c = data[i]
    if in_line:
        if c == "\n":
            in_line = False
            out.append(c)
        i += 1
        continue
    if in_block:
        if c == "*" and i + 1 < len(data) and data[i + 1] == "/":
            in_block = False
            i += 2
        else:
            i += 1
        continue
    if in_str:
        out.append(c)
        if escape:
            escape = False
        elif c == "\\":
            escape = True
        elif c == '"':
            in_str = False
        i += 1
        continue
    if c == '"':
        in_str = True
        out.append(c)
        i += 1
        continue
    if c == "/" and i + 1 < len(data):
        nxt = data[i + 1]
        if nxt == "/":
            in_line = True
            i += 2
            continue
        if nxt == "*":
            in_block = True
            i += 2
            continue
    out.append(c)
    i += 1

json.loads("".join(out))
PY
				warn "jsonc parse failed: $f"
			fi
		done
	else
		warn "python3 not installed; skipping jsonc parse"
	fi
fi

# Shell formatting (optional)
if command -v shfmt >/dev/null 2>&1; then
	info "shfmt check (${#sh_files[@]} files)"
	if ! shfmt -d "${sh_files[@]}"; then
		warn "shfmt reported formatting differences"
	fi
else
	warn "shfmt not installed; skipping shell formatting check"
fi

# Shellspec (optional)
if [ -d "$ROOT/spec" ]; then
	if command -v shellspec >/dev/null 2>&1; then
		info "shellspec"
		if ! shellspec; then
			warn "shellspec reported failures"
		fi
	else
		warn "shellspec not installed; skipping BDD specs"
	fi
fi

# Markdown lint (optional)
md_files=()
while IFS= read -r f; do md_files+=("$f"); done < <(rg --files --hidden --no-ignore-vcs -g '*.md' -g '!.git/*')
mdlint_bin=""
mdlint_args=()
if command -v markdownlint >/dev/null 2>&1; then
	mdlint_bin="markdownlint"
elif command -v mdl >/dev/null 2>&1; then
	mdlint_bin="mdl"
	# Exclude MD013 (line length) for technical documentation
	mdlint_args=("-r" "~MD013")
fi
if [ -n "$mdlint_bin" ] && [ "${#md_files[@]}" -gt 0 ]; then
	info "markdownlint (${#md_files[@]} files) via $mdlint_bin"
	if ! "$mdlint_bin" "${mdlint_args[@]}" "${md_files[@]}"; then
		warn "markdownlint reported issues"
	fi
else
	warn "markdownlint not installed; skipping markdown lint"
fi

if [ "$FAILURES" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
	info "All checks passed"
	exit 0
fi

if [ "$WARNINGS" -gt 0 ]; then
	warn "Checks completed with $WARNINGS warning(s)"
fi
if [ "$FAILURES" -gt 0 ]; then
	error "Checks completed with $FAILURES failure(s)"
fi
exit $((FAILURES > 0))
