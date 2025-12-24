#!/bin/sh
set -eu

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="$(dirname "$PKG_DIR")"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root" >&2
  exit 1
fi

echo "Installing root-network-audacious (apt proxy failover)"

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
    BACKUP="${TARGET}.bak-${TS}"
    echo "→ Backing up $TARGET to $BACKUP"
    mv "$TARGET" "$BACKUP"
  fi
}

backup_conflict /etc/apt/apt.conf.d/01proxy \
  "$PKG_DIR/etc/apt/apt.conf.d/01proxy"
backup_conflict /etc/systemd/network/10-wired.link \
  "$PKG_DIR/etc/systemd/network/10-wired.link"
backup_conflict /etc/systemd/network/20-wired.network \
  "$PKG_DIR/etc/systemd/network/20-wired.network"

echo "→ Stowing package"
cd "$DOTFILES_DIR"
stow -t / root-network-audacious

echo "→ Setting executable permission"
chmod 755 /usr/local/bin/apt-proxy-detect.sh

echo "→ Testing apt-proxy-detect"
OUTPUT="$(/usr/local/bin/apt-proxy-detect.sh 2>/dev/null || true)"
case "$OUTPUT" in
  "DIRECT"|"http://192.168.1.154:3142")
    echo "✓ apt-proxy-detect returned: $OUTPUT"
    ;;
  *)
    echo "ERROR: apt-proxy-detect returned unexpected output: $OUTPUT" >&2
    exit 1
    ;;
esac

echo "✓ root-network-audacious installed successfully"
