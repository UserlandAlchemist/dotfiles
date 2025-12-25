#!/bin/sh
set -eu

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

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
    BACKUP="${TARGET}.bak-${TS}"
    echo "→ Backing up $TARGET to $BACKUP"
    mv "$TARGET" "$BACKUP"
  fi
}

echo "Installing root-proaudio-audacious (real-time audio limits)"

backup_conflict /etc/security/limits.d/20-audio.conf \
  "$PKG_DIR/etc/security/limits.d/20-audio.conf"
install -o root -g root -m 0644 \
  "$PKG_DIR/etc/security/limits.d/20-audio.conf" \
  /etc/security/limits.d/20-audio.conf

echo "✓ root-proaudio-audacious installed successfully"
