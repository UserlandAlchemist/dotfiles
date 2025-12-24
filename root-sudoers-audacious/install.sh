#!/bin/sh
set -eu

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="$(dirname "$PKG_DIR")"

echo "Installing root-sudoers-audacious (NAS mount policy)"

echo "→ Installing sudoers rule (nas-mount)"
install -o root -g root -m 0440 \
  "$PKG_DIR/etc/sudoers.d/nas-mount.sudoers" \
  /etc/sudoers.d/nas-mount

echo "→ Validating sudoers"
visudo -c

echo "✓ root-sudoers-audacious installed successfully"
