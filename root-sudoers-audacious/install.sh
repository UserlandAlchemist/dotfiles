#!/bin/sh
# Install root-sudoers-audacious package

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$(dirname "$PKG_DIR")/lib/install.sh"

echo "Installing root-sudoers-audacious (NAS mount policy)"

echo "→ Installing sudoers rule (nas-mount)"
install -o root -g root -m 0440 \
  "$PKG_DIR/etc/sudoers.d/nas-mount.sudoers" \
  /etc/sudoers.d/nas-mount.sudoers

echo "→ Validating sudoers"
visudo -c

install_success
