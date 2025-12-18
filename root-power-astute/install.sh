#!/bin/sh
set -eu

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

echo "Installing etc-power-astute (Astute power policy)"

echo "→ Stowing systemd units"
stow -t / etc-power-astute

echo "→ Installing sudoers rule (nas-inhibit)"
install -o root -g root -m 0440 \
  "$PKG_DIR/etc/sudoers.d/nas-inhibit.sudoers" \
  /etc/sudoers.d/nas-inhibit

echo "→ Reloading systemd"
systemctl daemon-reload

echo "→ Validating sudoers"
visudo -c

echo "✓ etc-power-astute installed successfully"

