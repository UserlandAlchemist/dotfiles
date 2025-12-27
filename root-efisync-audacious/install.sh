#!/bin/sh
set -eu

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="$(dirname "$PKG_DIR")"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root" >&2
  exit 1
fi

install_unit() {
  UNIT="$1"
  SOURCE="$PKG_DIR/etc/systemd/system/$UNIT"
  TARGET="/etc/systemd/system/$UNIT"

  install -m 0644 "$SOURCE" "$TARGET"
}

echo "Installing root-efisync-audacious (systemd units as real files)"

install_unit efi-sync.service
install_unit efi-sync.path

echo "→ Stowing package (excluding systemd units)"
cd "$DOTFILES_DIR"
stow -t / \
  --ignore='^install\.sh$' \
  --ignore='^\.stow-local-ignore$' \
  --ignore='^README\.md$' \
  --ignore='^etc/systemd/system' \
  root-efisync-audacious

echo "→ Reloading systemd"
systemctl daemon-reload

echo "✓ root-efisync-audacious installed successfully"
