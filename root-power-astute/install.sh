#!/bin/sh
set -eu

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

echo "Installing root-power-astute (Astute power policy)"

echo "→ Stowing systemd units"
stow -t / root-power-astute

echo "→ Installing sudoers rule (nas-inhibit)"
install -o root -g root -m 0440 \
  "$PKG_DIR/etc/sudoers.d/nas-inhibit.sudoers" \
  /etc/sudoers.d/nas-inhibit

echo "→ Reloading systemd"
systemctl daemon-reload

echo "→ Validating sudoers"
visudo -c

echo "✓ root-power-astute installed successfully"

