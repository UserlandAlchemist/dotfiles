#!/usr/bin/env bash
# Lightweight dotfiles regression checks (no sudo, no writes).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
WARNINGS=0
FAILURES=0

info()  { printf '[INFO] %s\n' "$*"; }
warn()  { printf '[WARN] %s\n' "$*" >&2; WARNINGS=$((WARNINGS + 1)); }
error() { printf '[FAIL] %s\n' "$*" >&2; FAILURES=$((FAILURES + 1)); }

cd "$ROOT"

info "Running dotfiles checks from $ROOT"

# Shell linting
sh_files=()
while IFS= read -r f; do sh_files+=("$f"); done < <(rg --files -g '*.sh')

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
unit_files=()
while IFS= read -r f; do unit_files+=("$f"); done < <(rg --files -g '*.service' -g '*.timer' -g '*.path' root-*)
if [ "${#unit_files[@]}" -gt 0 ]; then
  if command -v systemd-analyze >/dev/null 2>&1; then
    info "systemd-analyze verify (${#unit_files[@]} units)"
    if ! SYSTEMD_PAGER=cat SYSTEMD_LOG_LEVEL=warning systemd-analyze verify "${unit_files[@]}"; then
      warn "systemd-analyze verify reported issues (see output above)"
    fi
  else
    warn "systemd-analyze not available; skipping unit verification"
  fi
fi

# Documentation reference hygiene
if rg --quiet 'data-restore\\.md' docs; then
  error "Found stale reference to data-restore.md in docs/"
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
exit $(( FAILURES > 0 ))
