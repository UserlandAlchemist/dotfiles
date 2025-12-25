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
  BACKUP_DIR="${3:-}"

  if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
    if [ -L "$TARGET" ]; then
      RESOLVED="$(readlink -f "$TARGET" 2>/dev/null || true)"
      if [ "$RESOLVED" = "$SOURCE" ]; then
        return 0
      fi
    fi

    TS="$(date +%Y%m%d-%H%M%S)"
    if [ -n "$BACKUP_DIR" ]; then
      mkdir -p "$BACKUP_DIR"
      BASE="$(basename "$TARGET")"
      BACKUP="${BACKUP_DIR}/${BASE}.bak-${TS}"
    else
      BACKUP="${TARGET}.bak-${TS}"
    fi
    echo "→ Backing up $TARGET to $BACKUP"
    mv "$TARGET" "$BACKUP"
  fi
}

backup_conflict /etc/apt/apt.conf.d/01proxy \
  "$PKG_DIR/etc/apt/apt.conf.d/01proxy" \
  /var/backups/apt-proxy
install -m 0644 "$PKG_DIR/etc/apt/apt.conf.d/01proxy" \
  /etc/apt/apt.conf.d/01proxy

echo "→ Installing apt-proxy-detect (non-symlink)"
backup_conflict /usr/local/bin/apt-proxy-detect.sh \
  "$PKG_DIR/usr/local/bin/apt-proxy-detect.sh" \
  /var/backups/apt-proxy
install -m 0755 "$PKG_DIR/usr/local/bin/apt-proxy-detect.sh" \
  /usr/local/bin/apt-proxy-detect.sh

echo "→ Installing systemd-networkd files (non-symlink)"
mkdir -p /etc/systemd/network
backup_conflict /etc/systemd/network/10-wired.link \
  "$PKG_DIR/etc/systemd/network/10-wired.link"
backup_conflict /etc/systemd/network/20-wired.network \
  "$PKG_DIR/etc/systemd/network/20-wired.network"
install -m 0644 "$PKG_DIR/etc/systemd/network/10-wired.link" \
  /etc/systemd/network/10-wired.link
install -m 0644 "$PKG_DIR/etc/systemd/network/20-wired.network" \
  /etc/systemd/network/20-wired.network

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
