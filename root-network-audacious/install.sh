#!/bin/sh
set -eu

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="$(dirname "$PKG_DIR")"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root" >&2
  exit 1
fi

echo "Installing root-network-audacious (apt proxy failover)"

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
