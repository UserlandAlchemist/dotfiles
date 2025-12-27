#!/bin/sh
set -eu

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="$(dirname "$PKG_DIR")"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root" >&2
  exit 1
fi

install_systemd_config() {
  RELPATH="$1"
  SOURCE="$PKG_DIR/$RELPATH"
  TARGET="/$RELPATH"
  TARGETDIR="$(dirname "$TARGET")"

  mkdir -p "$TARGETDIR"
  install -m 0644 "$SOURCE" "$TARGET"
}

echo "Installing root-system-audacious (general system configuration)"

# Install systemd configs as real files (no symlinks to /home)
# This overrides Debian's /usr/lib/systemd/journald.conf.d/syslog.conf
install_systemd_config etc/systemd/journald.conf.d/syslog.conf

# Ensure journald waits for /var mount (separate ZFS dataset)
install_systemd_config etc/systemd/system/systemd-journald.service.d/wait-for-var.conf

echo "→ Stowing package (excluding systemd configs)"
cd "$DOTFILES_DIR"
stow -t / \
  --ignore='^install\.sh$' \
  --ignore='^\.stow-local-ignore$' \
  --ignore='^README\.md$' \
  --ignore='^etc/systemd' \
  root-system-audacious

echo "→ Reloading systemd"
systemctl daemon-reload

echo "✓ root-system-audacious installed successfully"
echo ""
echo "Changes applied:"
echo "  - journald ForwardToSyslog override"
echo "  - journald waits for /var mount (ZFS dataset)"
echo ""
echo "Reboot to verify journald persistent storage at boot:"
echo "  sudo reboot"
