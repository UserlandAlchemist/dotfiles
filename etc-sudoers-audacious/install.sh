#!/bin/sh
set -eu

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

echo "Installing etc-sudoers-audacious (NAS mount policy)"

echo "→ Installing sudoers rule (nas-mount)"
install -o root -g root -m 0440 \
  "$PKG_DIR/etc/sudoers.d/nas-mount.sudoers" \
  /etc/sudoers.d/nas-mount

echo "→ Validating sudoers"
visudo -c

echo "✓ etc-sudoers-audacious installed successfully"
