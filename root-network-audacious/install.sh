#!/bin/sh
# Install root-network-audacious package

PKG_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
. "$(dirname "$PKG_DIR")/lib/install.sh"

echo "Installing root-network-audacious (apt proxy failover)"

install_config etc/apt/apt.conf.d/01proxy
install_script usr/local/bin/apt-proxy-detect.sh
install_config etc/systemd/network/10-wired.link
install_config etc/systemd/network/20-wired.network

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

install_success
