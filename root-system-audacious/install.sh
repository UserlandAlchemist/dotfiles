#!/bin/sh
set -eu

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="$(dirname "$PKG_DIR")"
BACKUP_DIR="/var/backups/systemd/root-system-audacious"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root" >&2
  exit 1
fi

backup_conflict() {
  TARGET="$1"
  SOURCE="$2"

  if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
    if [ -L "$TARGET" ]; then
      RESOLVED="$(readlink -f "$TARGET" 2>/dev/null || true)"
      if [ "$RESOLVED" = "$SOURCE" ]; then
        return 0
      fi
    fi

    TS="$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    BASE="$(basename "$TARGET")"
    BACKUP="${BACKUP_DIR}/${BASE}.bak-${TS}"
    echo "→ Backing up $TARGET to $BACKUP"
    mv "$TARGET" "$BACKUP"
  fi
}

install_systemd_config() {
  RELPATH="$1"
  SOURCE="$PKG_DIR/$RELPATH"
  TARGET="/$RELPATH"
  TARGETDIR="$(dirname "$TARGET")"

  mkdir -p "$TARGETDIR"
  backup_conflict "$TARGET" "$SOURCE"
  install -m 0644 "$SOURCE" "$TARGET"
}

echo "Installing root-system-audacious (general system configuration)"

# Install systemd configs as real files (no symlinks to /home)
# This overrides Debian's /usr/lib/systemd/journald.conf.d/syslog.conf
install_systemd_config etc/systemd/journald.conf.d/syslog.conf

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
echo "Restart journald for changes to take effect:"
echo "  sudo systemctl restart systemd-journald"
